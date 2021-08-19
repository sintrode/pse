::------------------------------------------------------------------------------
:: NAME
::     pse.bat - Parallel Script Execution
::
:: DESCRIPTION
::     Runs a script against every file in a specified folder.
::
:: MANDATORY ARGUMENTS
::     %1 - The folder containing the files to process
::     %2 - The script that will process the files in the specified folder
::
:: AUTHOR
::     Sintrode
::
:: VERSION HISTORY
::     1.2 (2021-08-16) - Removed need for delayed expansion to handle filenames
::                        that contain exclamation points
::     1.1 (2021-08-02) - Added subfolder processing
::     1.0 (2021-07-23) - Initial Version
::------------------------------------------------------------------------------
@echo off

if "%~2"=="" goto :usage
if not exist "%~1\" goto :usage
if not exist "%~2" goto :usage
set "input_folder=%~1"
set "target_script=%~f2"

:: Only use a quarter of all available processors so that your computer is still
:: useable; feel free to hardcode MAX_THREADS if you know what you're doing
:: (we're dividing by 8 instead of 4 because of virtual threads)
set /a MAX_THREADS=%NUMBER_OF_PROCESSORS%/8
:: There's a tiny chance somebody's still using a 2-core processor in 2021
if %MAX_THREADS% EQU 0 set "MAX_THREADS=1"

:: Enter input_folder so that any output files end up in the same folder
:: If a separate output folder is desired, that should be handled by target_script
pushd "%input_folder%"
set "counter=-1"
for /f "delims=" %%A in ('dir /b /s /a:-d') do (
	set /a counter+=1
	call set "filename[%%counter%%]=%%A"
)
set /a total_count=counter, processed_count=-1

:spawn_process
for /f %%A in ('tasklist /FI "WINDOWTITLE eq pse_spawn*" ^| find "cmd" /c') do set "running_processes=%%A"
if %running_processes% GEQ %MAX_THREADS% (
	timeout /t 1 >nul
	goto :spawn_process
)
set /a processed_count+=1
title Processing file %processed_count%/%total_count%

call set "actual_filename=%%filename[%processed_count%]%%"
for /f "delims=" %%A in ("%processed_count%") do (
	start "pse_spawn" cmd /c "%target_script% ^"%actual_filename%^""
	REM Wait for a second so that two processes don't spawn at the same time
	timeout /t 1 >nul
)
if %processed_count% LSS %total_count% goto :spawn_process
popd
exit /b

::------------------------------------------------------------------------------
:: Displays the usage text for the script
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:Usage
echo USAGE: %~nx0 ^<input_folder^> ^<target_script^>
echo        input_folder     The folder containing the files to process
echo        target_script    The script that will process the files in input_folder
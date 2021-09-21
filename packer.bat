::------------------------------------------------------------------------------
:: NAME
::     packer.bat
::
:: AUTHOR
::     sintrode
::
:: DESCRIPTION
::     Generates a cabinet file from a provided folder that contains all other
::     files and subfolders that were inside of the main directory. From there,
::     gets converted to base64 and put in a self-extracting batch script.
::
:: REQUIREMENTS
::     certutil
::
:: THANKS
::     Inspired by http://www.dostips.com/forum/viewtopic.php?t=1977#p8751
::     File size limit fix from https://ss64.com/nt/makecab-directives.html
::------------------------------------------------------------------------------
@echo off
setlocal enabledelayedexpansion
chcp 1252 >nul

:: If no folder was provided, exit immediately
if "%~1"=="" exit /b
if not exist "%~1\" exit /b

:: Check that the input directory is 74472684 bytes or smaller
set "max_cab_size=74472448"

set "config_file=%~dp0\directives.ddf"
set "target_file=%~dp0\%~n1.cab"

pushd "%~1"
:: Add the header to the cabinet config file
>"%config_file%" (
	echo ; Generated %date% %time%
	echo .Option Explicit
	echo .Set SourceDir="%~1"
	echo .Set DiskDirectoryTemplate="%~dp0"
	echo .Set CabinetNameTemplate="%~n1*.cab"
	echo .Set Cabinet=ON
	echo .Set Compress=ON
	echo .Set CompressionType=MSZIP
	echo .Set DestinationDir="%~n1"
	echo .Set MaxDiskSize=%max_cab_size%
)

:: Add the list of files to the cabinet config file
echo(Processing all files in %cd%
for /f "delims=" %%A in ('dir /a:-d /b') do (
	>>"%config_file%" echo "%%A"
)

:: Add the subdirectories and all related files to the cabinet config file
for /f "delims=" %%A in ('dir /a:d /b /s') do (
	set "inner_target=%%A"
	set "inner_target=%~n1\!inner_target:*%~1\=!"
	echo(Processing all files in !inner_target!
	>>"%config_file%" (
		echo .Set SourceDir="%%A"
		echo .Set DestinationDir="!inner_target!"
		for /f "delims=" %%B in ('dir /a:-d /b "%%A"') do (
			echo "%%B"
		)
	)
)
popd

:: Generate the cabinet file
makecab /f "%config_file%"
del "%~dp0\directives.ddf"
del "%~dp1\setup.rpt"
del "%~dp1\setup.inf"

:: Generate the extraction script
set "output_file="
>>"%~n1_setup.bat" (
	echo @echo off
	echo setlocal enabledelayedexpansion
	echo set "output_dir=%%~n0"
	echo mkdir "%%output_dir%%"
	echo set "output_file="
	echo set "input_file=%%~nx0"
	echo for /f "usebackq skip=35 tokens=1,2 delims=:" %%%%A in ("%%input_file%%"^) do (
	echo 	if not "%%%%~B"=="" (
	echo 		if defined output_file call :Base64Process "^!output_file^!"
	echo 		endlocal
	echo 		call :sanitizeFilename "%%%%~A"
	echo 		setlocal enabledelayedexpansion
	echo 		pushd "%%output_dir%%"
	echo 		echo Processing ^^!output_file^^!
	echo 		^>^>"^!output_file^!" echo %%%%~B
	echo 	^) else (
	echo 		^>^>"^!output_file^!" echo %%%%~A
	echo 	^)
	echo ^)
	echo call :Base64Process "^!output_file^!"
	echo extrac32 /a /e "%~n11.cab"
	echo del "%~n1*.cab"
	echo popd
	echo exit /b
	echo :sanitizeFilename
	echo set "filename=%%~1"
	echo set "filename=%%filename:^!=%%"
	echo set "output_file=%%filename%%"
	echo exit /b
	echo :Base64Process
	echo set "b64_filename=%%~1"
	echo set "reg_filename=%%b64_filename:~7%%"
	echo ^>nul certutil -decode "%%b64_filename%%" "%%reg_filename%%"
	echo del "%%b64_filename%%"
	echo exit /b
)

:: Convert all cabinet files to base64 and generate the m64 file
>>"%~n1_setup.bat" (
	for /f "delims=" %%A in ('dir /b "%~n1*.cab"') do (
		>nul certutil -encode "%%~A" "base64_%%~nxA"
		<nul set /p "=base64_%%~nxA:"
		type "base64_%%~nxA"
		del "base64_%%~nxA"
	)
)
del /q "%~n1*.cab"
exit /b

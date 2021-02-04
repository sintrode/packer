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
::
:: VERSION HISTORY
::     1.1 (2021-02-04) - Removed file size limitations (up to makecab's
::                        makecab's default 2GB filesize)
::                      - Fixed support for subfolders
::     1.0 (2018-03-18) - Initial Version
::------------------------------------------------------------------------------
@echo off
setlocal enabledelayedexpansion

:: If no folder was provided, exit immediately
if "%~1"=="" exit /b
if not exist "%~1\" exit /b

set "config_file=%~dp0\directives.ddf"
set "target_file=%~dp0\%~n1.cab"

pushd "%~1"
:: Add the header to the cabinet config file
>"%config_file%" (
	echo ; Generated %date% %time%
	echo .Option Explicit
	echo .Set SourceDir="%~1"
	echo .Set DiskDirectoryTemplate="%~dp0"
	echo .Set CabinetNameTemplate="%~n1.cab"
	echo .Set Cabinet=ON
	echo .Set Compress=ON
	echo .Set CompressionType=MSZIP
	echo .Set DestinationDir="%~n1"
	echo .Set FolderSizeThreshold=0
	echo .Set MaxCabinetSize=0
	echo .Set MaxDiskFileCount=0
	echo .Set MaxDiskSize=0
)

:: Add the list of files to the cabinet config file
echo(Processing all files in %cd%
for /f "delims=" %%A in ('dir /a:-d /b') do (
	>>%config_file% echo "%%A"
)

:: Add the subdirectories and all related files to the cabinet config file
for /f "delims=" %%A in ('dir /a:d /b /s') do (
	set "inner_target=%%A"
	set "inner_target=%~n1\!inner_target:*%~1\=!"
	echo(Processing all files in !inner_target!
	>>%config_file% echo .Set SourceDir="%%A"
	>>%config_file% echo .Set DestinationDir="!inner_target!"
	for /f "delims=" %%B in ('dir /a:-d /b "%%A"') do (
		>>%config_file% echo "%%B"
	)
)
popd

:: Generate the cabinet file
makecab /f %config_file%
del "%~dp0\directives.ddf"
del "%~dp1\setup.rpt"
del "%~dp1\setup.inf"

:: Generate the extraction script
>>"%~n1_setup.bat" (
	echo @echo off
	echo certutil -decode "%%~0" "%%~n0.cab"
	echo mkdir "%%~n0" 2^>nul
	echo expand "%%~n0.cab" -f:* "%%~n0"
	echo del "%%~n0.cab"
)
certutil -encode "%target_file%" "%target_file%.b64"
del "%target_file%"
>>"%~n1_setup.bat" (
	echo exit /b
	type "%target_file%.b64"
)
del "%target_file%.b64"

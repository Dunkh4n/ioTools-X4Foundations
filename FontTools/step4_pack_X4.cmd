@echo off
setlocal

echo.
echo "|   __   ______ _ ___ _____   ____   __   _  __  __ __  __ _____ ___   __ |"
echo "| /' _/ / _/ _ \ | _,\_   _| |  \ `v' /  | |/__\|  V  |/  \_   _| \ \_/ / |"
echo "| `._`.| \_| v / | v_/ | |   | -<`. .'   | | \/ | \_/ | /\ || | | |> , <  |"
echo "| |___/ \__/_|_\_|_|   |_|   |__/ !_!    |_|\__/|_| |_|_||_||_| |_/_/ \_\ |"
echo "|  _________________________________________________________________________ |"
echo "| )___)___)___)___)___)___)___)___)___)___)___)___)___)___)___)____)___/___/ |"
echo "| /___(___(___(___(___(___(___(___(___(___(___(___(___(___(___(___(___(___(  |"
echo.

:: Set tools path
call include.cmd
if errorlevel 1 (
    echo [ERROR] Failed to include tools path from include.cmd
    goto eof
)

:: Check if the target directory exists
if not exist %FOLDER%\mods\%TARGET% (
    echo [ERROR] Target directory %TARGET% does not exist.
    goto eof
)

:: Create output directory if it doesn't exist
echo.
echo [LOG] Setting up the output path... 
set FOLDER_NO_QUOTES=%FOLDER:"=%
set OUTDIR_NO_QUOTES=%OUTDIR:"=%
set TARGET_NO_QUOTES=%TARGET:"=%
set PATH=%FOLDER_NO_QUOTES%\%OUTDIR_NO_QUOTES%

:: Checking directories...
echo [LOG] Checking directories...
:: DIY -> OR gate
set res="F"
if %OUTDIR%==. set res="T"
if %OUTDIR%=="." set res="T"
if %OUTDIR%==% set res="T"
if %res%=="T" (
    :: Remove trailing backslash from OUTDIR
    set PATH=%FOLDER_NO_QUOTES%
)

echo [LOG] Out path resolved as "%D%%PATH%"

:: Prepare main output path
if not exist "%D%%PATH%" mkdir "%D%%PATH%"
if errorlevel 1 (
    echo [ERROR] Failed to create %PATH% directory.
    echo [WARNING] The %PATH% directory is mandatory to pack the assets.
    echo Exiting...
    goto eof
)


:: Packing assets to an external catalog with X Tools
echo.
echo [LOG] Packing %TARGET_NO_QUOTES% to the %PATH%\%CATDAT%.cat 
%XRCATTOOL% -in %FOLDER_NO_QUOTES%\mods -out %PATH%\%CATDAT%.cat
if errorlevel 1 (
    echo [ERROR] Failed to pack assets to %PATH%\%CATDAT%.cat
    echo Exiting...
    goto eof
)

echo.
:: Prepare target path for replacemnt  to pack replacement of the assets.
if not exist "%D%%PATH%\mods\%TARGET_NO_QUOTES%\" mkdir "%D%%PATH%\mods\%TARGET_NO_QUOTES%"
if errorlevel 1 (
    echo [ERROR] Failed to create "mods\%TARGET_NO_QUOTES%" within the output directory.
    echo [WARNING] The "%TARGET_NO_QUOTES%" directory is mandatory to pack replacement of the assets.
    echo Exiting...
    goto eof
)

:: Copying specific font files (e.g., Arial_* and Arial Bold_*)
for %%F in ("%FOLDER_NO_QUOTES%\mods\%TARGET_NO_QUOTES%\*.abc" "%FOLDER_NO_QUOTES%\mods\%TARGET_NO_QUOTES%\*.dds") do (
    setlocal enabledelayedexpansion
    set "FILE=%%~nF"
    set "BASENAME=!FILE:%REPLACEFONT%=!"
    echo.
    echo [LOG] Found file: %%F
    echo [LOG] Basename of the file is !BASENAME!
    
    :: Determine if it's the regular or bold variant
    for /f "tokens=2,* delims= " %%a in ("!BASENAME!") do (
        set "SUF=%%a"
        set "VARIANT=_32"
        set REPLACEFONT_NO_QUOTES=%REPLACEFONT:"=%
        set "NEWNAME=!REPLACEFONT_NO_QUOTES!!VARIANT!%%~xF"

        :: Isolated to avoid break of this script
        setlocal enabledelayedexpansion
        for /f "tokens=1,* delims=_" %%A in ("!SUF!") do (        
            if /i "%%A"=="Bold" (
                set "VARIANT= Bold_32"
                set REPLACEFONT_NO_QUOTES=%REPLACEFONT:"=%
                set "NEWNAME=!REPLACEFONT_NO_QUOTES!!VARIANT!%%~xF"
                :: Call the external batch file to handle file copying ( Bold_32)
                call copy_files.bat "%%F" "%PATH%\mods\%TARGET_NO_QUOTES%\!NEWNAME!"
            )    
        )
        endlocal

        :: Call the external batch file to handle file copying (_32)
        call copy_files.bat "%%F" "%PATH%\mods\%TARGET_NO_QUOTES%\!NEWNAME!"
    )
)

:: Packing replacements (subst) with X Tools
echo.
echo [LOG] Packing replacements to %PATH%\%CATDATSUBST%.cat...
%XRCATTOOL% -in %PATH%\mods -out %PATH%\%CATDATSUBST%.cat
if errorlevel 1 (
    echo [ERROR] Failed to pack assets. Exiting.
    goto eof
)

echo.
echo.
echo [SUCCESS] Step 4 has been completed successfully!
echo.

:eof
endlocal

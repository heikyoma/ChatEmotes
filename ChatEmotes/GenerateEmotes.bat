@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo Generating Emotes.lua...
echo.

> "Emotes.lua" echo ChatEmotes_Emotes = {

set /a COUNT=0

for %%F in ("art\*.dds") do (
    if exist "%%~fF" (
        >> "Emotes.lua" echo     [":%%~nF:"] = { texture = "ChatEmotes/art/%%~nxF" },
        set /a COUNT+=1
    )
)

>> "Emotes.lua" echo }

echo.
echo Generated %COUNT% emote(s).
echo File: %CD%\Emotes.lua
echo.
echo Now use /reloadui in ESO.
echo.
pause

@echo off
title Shadow Cheat - Solo Guild Ascendance
set "GODOT=C:\Users\Rodrigo Brasil\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe"
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

echo Iniciando o jogo na sua tela...
start "" "%GODOT%" --path "%PROJECT_DIR%"
exit

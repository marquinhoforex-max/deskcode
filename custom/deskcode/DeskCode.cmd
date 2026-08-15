@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deskcode.ps1" %*
exit /b %ERRORLEVEL%

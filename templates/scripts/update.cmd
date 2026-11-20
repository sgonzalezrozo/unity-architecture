@echo off
rem Windows launcher for update.sh: updates .ai and the copied files.
rem Run it from the project root, the folder that holds Assets and .ai:  .ai\templates\scripts\update.cmd
rem It takes the same options as update.sh, and runs it with Git Bash instead of WSL's bash.
setlocal
call "%~dp0find-git-bash.cmd" || exit /b 2
set "SCRIPT=%~dp0update.sh"
set "SCRIPT=%SCRIPT:\=/%"
"%GIT_BASH%" "%SCRIPT%" %*
exit /b %ERRORLEVEL%

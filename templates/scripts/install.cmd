@echo off
rem Windows launcher for install.sh: puts the rules' files in the project.
rem Run it from the project root, the folder that holds Assets and .ai:  .ai\templates\scripts\install.cmd
rem It takes the same options as install.sh, and runs it with Git Bash instead of WSL's bash.
setlocal
call "%~dp0find-git-bash.cmd" || exit /b 2
set "SCRIPT=%~dp0install.sh"
set "SCRIPT=%SCRIPT:\=/%"
"%GIT_BASH%" "%SCRIPT%" %*
exit /b %ERRORLEVEL%

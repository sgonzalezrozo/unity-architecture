@echo off
rem Sets GIT_BASH to Git for Windows' bash.exe. Plain "bash" in PowerShell or cmd is usually WSL's launcher
rem (C:\Windows\System32\bash.exe), which fails when no Linux distribution is installed.
set "GIT_BASH="
for %%P in ("%ProgramFiles%\Git\bin\bash.exe" "%ProgramFiles(x86)%\Git\bin\bash.exe" "%LocalAppData%\Programs\Git\bin\bash.exe") do (
    if not defined GIT_BASH if exist "%%~P" set "GIT_BASH=%%~P"
)
if not defined GIT_BASH (
    for /f "delims=" %%G in ('where git 2^>nul') do (
        if not defined GIT_BASH if exist "%%~dpG..\bin\bash.exe" set "GIT_BASH=%%~dpG..\bin\bash.exe"
    )
)
if not defined GIT_BASH (
    echo Git Bash not found. Install Git for Windows from https://git-scm.com/download/win and run this again.
    exit /b 2
)
exit /b 0

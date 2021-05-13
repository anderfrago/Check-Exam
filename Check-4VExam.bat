@echo off

:: BatchGotAdmin
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"





:launchApp
    set location=%CD%
    echo Enable execution of PowerShell Scripts
    powershell.exe Set-ExecutionPolicy Unrestricted
    echo Check requirement: Nmap
    IF NOT EXIST "C:\Program Files (x86)\Nmap"   (
	rem mklink "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Check-Exam\Check-4VExam" C:\Check-Exam\Check-4VExam.bat
	rem mklink %userprofile%"\Desktop\Check-4VExam" C:\Check-Exam\Check-4VExam.bat
        echo Installing NMap
        cd lib
        nmap-7.91-setup.exe
        echo Installation finished   
        rem start cmd.exe /k "%location%\Check-4VExam.bat"
	echo Please, restart the script
    ) else (
        echo Starting the script
        cd bin
        powershell.exe .\Get-Information.ps1
    )

:end
pause > nul
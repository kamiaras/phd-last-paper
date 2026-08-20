@echo off
setlocal
set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
python "%~dp0compile-latex.py"

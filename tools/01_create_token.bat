@echo off
setlocal

if not defined PYTHON_BIN (
    set PYTHON_BIN=python
)

%PYTHON_BIN% -m python.cli.main create-token %*
exit /b %ERRORLEVEL%

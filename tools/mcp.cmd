@echo off
REM ============================================================================
REM MCP Snowflake CLI - Unified Command Interface (Windows)
REM
REM A single entry point for all MCP server operations.
REM
REM Usage:
REM   tools\mcp <command> [options]
REM   tools\mcp help
REM
REM Commands:
REM   token     Create PAT token for MCP authentication
REM   setup     Provision MCP server and apply grants
REM   test      Validate SSL and test MCP connection
REM   all       Run complete setup (token + setup + test)
REM   proxy     Manage local SSE proxy server
REM   help      Show this help message
REM
REM Author: SE Community
REM ============================================================================

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "LIB_DIR=%SCRIPT_DIR%windows"
set "PROXY_DIR=%PROJECT_ROOT%\proxy"
set "PIDS_DIR=%PROJECT_ROOT%\.pids"

REM Get command
set "CMD=%~1"
if "%CMD%"=="" set "CMD=help"

REM Shift to get remaining args
shift

REM Route to command
if /i "%CMD%"=="token" goto :cmd_token
if /i "%CMD%"=="create-token" goto :cmd_token
if /i "%CMD%"=="setup" goto :cmd_setup
if /i "%CMD%"=="setup-mcp" goto :cmd_setup
if /i "%CMD%"=="test" goto :cmd_test
if /i "%CMD%"=="test-connection" goto :cmd_test
if /i "%CMD%"=="all" goto :cmd_all
if /i "%CMD%"=="master" goto :cmd_all
if /i "%CMD%"=="proxy" goto :cmd_proxy
if /i "%CMD%"=="help" goto :cmd_help
if /i "%CMD%"=="--help" goto :cmd_help
if /i "%CMD%"=="-h" goto :cmd_help

echo.
echo ERROR: Unknown command: %CMD%
echo.
goto :cmd_help

REM ============================================================================
REM Command: token
REM ============================================================================
:cmd_token
call :banner "Create PAT Token"
echo [i] Generating programmatic access token for MCP authentication
echo.
call :run_python create-token %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

REM ============================================================================
REM Command: setup
REM ============================================================================
:cmd_setup
call :banner "Setup MCP Server"
echo [i] Provisioning MCP server and applying least-privilege grants
echo.
call :run_python setup-mcp %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

REM ============================================================================
REM Command: test
REM ============================================================================
:cmd_test
call :banner "Test MCP Connection"
echo [i] Validating SSL certificate and testing MCP endpoint
echo.
call :run_python test-connection %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

REM ============================================================================
REM Command: all
REM ============================================================================
:cmd_all
call :banner "Complete MCP Setup"
echo [i] Running full setup workflow: token - setup - test
echo.
call :run_python master %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

REM ============================================================================
REM Command: proxy
REM ============================================================================
:cmd_proxy
set "SUBCMD=%~1"
if "%SUBCMD%"=="" set "SUBCMD=help"
shift

if /i "%SUBCMD%"=="start" goto :proxy_start
if /i "%SUBCMD%"=="stop" goto :proxy_stop
if /i "%SUBCMD%"=="status" goto :proxy_status
if /i "%SUBCMD%"=="logs" goto :proxy_logs
goto :proxy_help

:proxy_help
echo.
echo Proxy Commands
echo.
echo   mcp proxy start   Start the local SSE proxy server
echo   mcp proxy stop    Stop the proxy server
echo   mcp proxy status  Check if proxy is running
echo   mcp proxy logs    View proxy server logs
echo.
echo The proxy fixes SSE streaming errors with Snowflake MCP server.
echo See docs/05-PROXY-SETUP.md for configuration details.
echo.
goto :eof

:proxy_start
call :banner "Start MCP Proxy"

REM Check Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo [x] Node.js not found. Install from https://nodejs.org/
    exit /b 1
)

REM Check config
if not exist "%PROXY_DIR%\config.js" (
    echo [!] proxy\config.js not found
    echo.
    echo [i] Create it by copying the example:
    echo     copy proxy\config.example.js proxy\config.js
    echo     REM Edit with your MCP URL and PAT token
    exit /b 1
)

REM Install deps if needed
if not exist "%PROXY_DIR%\node_modules" (
    echo [-] Installing npm dependencies...
    pushd "%PROXY_DIR%"
    call npm install --silent
    popd
    echo [+] Dependencies installed
)

REM Create pids dir
if not exist "%PIDS_DIR%" mkdir "%PIDS_DIR%"

REM Check for background flag
set "BACKGROUND=false"
:parse_proxy_args
if "%~1"=="" goto :done_parse_proxy
if /i "%~1"=="--bg" set "BACKGROUND=true"
if /i "%~1"=="--background" set "BACKGROUND=true"
shift
goto :parse_proxy_args
:done_parse_proxy

if "%BACKGROUND%"=="true" (
    echo [-] Starting proxy in background...
    pushd "%PROXY_DIR%"
    start /B node server.js > proxy.log 2>&1
    popd
    
    timeout /t 2 /nobreak >nul
    
    REM Find node process and save PID
    for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST 2^>nul ^| find "PID:"') do (
        echo %%a > "%PIDS_DIR%\proxy.pid"
        echo [+] Proxy started ^(PID: %%a^)
        goto :proxy_started
    )
    echo [x] Proxy may not have started. Check: type proxy\proxy.log
    exit /b 1
    
    :proxy_started
    echo.
    echo [i] Configure your IDE to use: http://127.0.0.1:3456/mcp
    echo [i] Stop with: tools\mcp proxy stop
) else (
    echo [i] Starting proxy in foreground ^(Ctrl+C to stop^)...
    echo.
    pushd "%PROXY_DIR%"
    node server.js
    popd
)
goto :eof

:proxy_stop
call :banner "Stop MCP Proxy"

set "STOPPED=false"

REM Try PID file
if exist "%PIDS_DIR%\proxy.pid" (
    set /p PID=<"%PIDS_DIR%\proxy.pid"
    tasklist /FI "PID eq !PID!" 2>nul | find "!PID!" >nul
    if not errorlevel 1 (
        echo [-] Stopping proxy ^(PID: !PID!^)...
        taskkill /PID !PID! /F >nul 2>&1
        echo [+] Proxy stopped
        set "STOPPED=true"
    )
    del "%PIDS_DIR%\proxy.pid" 2>nul
)

REM Also check port 3456
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3456 " ^| findstr "LISTENING" 2^>nul') do (
    echo [-] Stopping process on port 3456 ^(PID: %%a^)...
    taskkill /PID %%a /F >nul 2>&1
    echo [+] Process stopped
    set "STOPPED=true"
    goto :proxy_stop_done
)
:proxy_stop_done

if "%STOPPED%"=="false" (
    echo [i] No proxy server found running
)
goto :eof

:proxy_status
call :banner "Proxy Status"

set "RUNNING=false"
set "PID="

if exist "%PIDS_DIR%\proxy.pid" (
    set /p PID=<"%PIDS_DIR%\proxy.pid"
    tasklist /FI "PID eq !PID!" 2>nul | find "!PID!" >nul
    if not errorlevel 1 set "RUNNING=true"
)

REM Check port
netstat -ano | findstr ":3456 " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 set "RUNNING=true"

if "%RUNNING%"=="true" (
    echo   Status:   Running
    if defined PID echo   PID:      !PID!
    echo   Port:     3456
    echo.
    echo   Endpoints:
    echo     http://127.0.0.1:3456/mcp     MCP proxy
    echo     http://127.0.0.1:3456/health  Health check
) else (
    echo   Status:   Stopped
    echo.
    echo [i] Start with: tools\mcp proxy start
)
goto :eof

:proxy_logs
set "LOG_FILE=%PROXY_DIR%\proxy.log"
if exist "%LOG_FILE%" (
    type "%LOG_FILE%"
) else (
    echo [i] No log file found at %LOG_FILE%
)
goto :eof

REM ============================================================================
REM Command: help
REM ============================================================================
:cmd_help
echo.
echo MCP Snowflake CLI
echo Unified command interface for MCP server operations
echo.
echo USAGE
echo     tools\mcp ^<command^> [options]
echo.
echo COMMANDS
echo.
echo   token              Create PAT token for MCP authentication
echo                      Options: --profile ^<name^> --dry-run --verbose
echo.
echo   setup              Provision MCP server and apply grants
echo                      Options: --profile ^<name^> --dry-run --verbose
echo.
echo   test               Validate SSL and test MCP connection
echo                      Options: --url ^<url^> --hostname ^<host^> --token ^<token^>
echo.
echo   all                Run complete setup (token + setup + test)
echo                      Options: --profile ^<name^> --url ^<url^> --skip-test
echo.
echo   proxy              Manage local SSE proxy server
echo                      Subcommands: start, stop, status, logs
echo.
echo   help               Show this help message
echo.
echo EXAMPLES
echo.
echo     REM Create token using default profile
echo     tools\mcp token
echo.
echo     REM Setup with specific profile
echo     tools\mcp setup --profile myprofile
echo.
echo     REM Start proxy in background
echo     tools\mcp proxy start --bg
echo.
echo DOCUMENTATION
echo.
echo     docs\01-SETUP.md         Prerequisites and environment setup
echo     docs\05-PROXY-SETUP.md   SSE proxy configuration
echo.
goto :eof

REM ============================================================================
REM Helper Functions
REM ============================================================================

:banner
echo.
echo ================================================================
echo   %~1
echo ================================================================
echo.
goto :eof

:run_python
REM Find Python
set "PYTHON_BIN="
where python3 >nul 2>&1 && set "PYTHON_BIN=python3"
if "%PYTHON_BIN%"=="" where python >nul 2>&1 && set "PYTHON_BIN=python"
if "%PYTHON_BIN%"=="" (
    echo [x] Python not found. Please install Python 3.10+
    exit /b 1
)

pushd "%PROJECT_ROOT%"
%PYTHON_BIN% -m python.cli.main %*
popd
goto :eof


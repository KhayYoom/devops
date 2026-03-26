@echo off
REM =============================================================================
REM  CUSTOM ACTIONS LAB - LOCAL PIPELINE SIMULATOR (Windows)
REM =============================================================================
REM
REM  This script validates the custom actions lab locally by:
REM
REM   [1.FILES] --> [2.DEPS] --> [3.TESTS] --> [4.YAML] --> [5.DOCKER]
REM
REM  KEY CONCEPT: If ANY stage fails, the pipeline STOPS immediately.
REM
REM  Usage: scripts\run-pipeline.bat  (from the lab-custom-actions folder)
REM
REM =============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0\.."

echo.
echo ============================================================
echo       CUSTOM ACTIONS LAB - Pipeline Starting...
echo ============================================================
echo.
echo   Project:   %CD%
echo   Timestamp: %DATE% %TIME%
python --version 2>nul
node --version 2>nul
echo.

REM ===========================================================================
REM STAGE 1: VERIFY ACTION FILES
REM ===========================================================================

echo.
echo ----------------------------------------------------------
echo   STAGE 1/5 - VERIFY ACTION FILES
echo ----------------------------------------------------------
echo.
echo   Checking that all action files exist...

set "ALL_FOUND=1"

REM JavaScript Action (PR Comment Bot)
if exist "actions\pr-comment\action.yml" (echo     [OK] actions\pr-comment\action.yml) else (echo     [MISSING] actions\pr-comment\action.yml & set "ALL_FOUND=0")
if exist "actions\pr-comment\index.js" (echo     [OK] actions\pr-comment\index.js) else (echo     [MISSING] actions\pr-comment\index.js & set "ALL_FOUND=0")
if exist "actions\pr-comment\package.json" (echo     [OK] actions\pr-comment\package.json) else (echo     [MISSING] actions\pr-comment\package.json & set "ALL_FOUND=0")

REM Docker Action (Code Statistics)
if exist "actions\code-stats\action.yml" (echo     [OK] actions\code-stats\action.yml) else (echo     [MISSING] actions\code-stats\action.yml & set "ALL_FOUND=0")
if exist "actions\code-stats\Dockerfile" (echo     [OK] actions\code-stats\Dockerfile) else (echo     [MISSING] actions\code-stats\Dockerfile & set "ALL_FOUND=0")
if exist "actions\code-stats\entrypoint.sh" (echo     [OK] actions\code-stats\entrypoint.sh) else (echo     [MISSING] actions\code-stats\entrypoint.sh & set "ALL_FOUND=0")

REM Composite Action (Setup & Test)
if exist "actions\setup-and-test\action.yml" (echo     [OK] actions\setup-and-test\action.yml) else (echo     [MISSING] actions\setup-and-test\action.yml & set "ALL_FOUND=0")

REM Sample App & Tests
if exist "app\__init__.py" (echo     [OK] app\__init__.py) else (echo     [MISSING] app\__init__.py & set "ALL_FOUND=0")
if exist "app\utils.py" (echo     [OK] app\utils.py) else (echo     [MISSING] app\utils.py & set "ALL_FOUND=0")
if exist "tests\unit\test_utils.py" (echo     [OK] tests\unit\test_utils.py) else (echo     [MISSING] tests\unit\test_utils.py & set "ALL_FOUND=0")
if exist "requirements.txt" (echo     [OK] requirements.txt) else (echo     [MISSING] requirements.txt & set "ALL_FOUND=0")

if "%ALL_FOUND%"=="0" (
    echo.
    echo   [FAILED] Missing required files!
    echo   PIPELINE STOPPED at stage: VERIFY FILES
    exit /b 1
)

echo.
echo   [PASSED] All action files present
echo.

REM ===========================================================================
REM STAGE 2: INSTALL PYTHON DEPENDENCIES
REM ===========================================================================

echo.
echo ----------------------------------------------------------
echo   STAGE 2/5 - INSTALL PYTHON DEPENDENCIES
echo ----------------------------------------------------------
echo.
echo   Installing Python dependencies from requirements.txt...
echo.

python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo.
    echo   [FAILED] Could not install dependencies!
    echo   PIPELINE STOPPED at stage: INSTALL DEPS
    exit /b 1
)

echo.
echo   [PASSED] Python dependencies installed successfully
echo.

REM ===========================================================================
REM STAGE 3: RUN UNIT TESTS
REM ===========================================================================

echo.
echo ----------------------------------------------------------
echo   STAGE 3/5 - RUN UNIT TESTS
echo ----------------------------------------------------------
echo.
echo   Running pytest against app/utils.py...
echo.

python -m pytest tests/unit/ -v --tb=short
if errorlevel 1 (
    echo.
    echo   [FAILED] Unit tests failed!
    echo   Hint: Look at the FAILED line above.
    echo         Check app/utils.py -- did you change a function?
    echo   PIPELINE STOPPED at stage: UNIT TESTS
    exit /b 1
)

echo.
echo   [PASSED] Unit tests passed
echo.

REM ===========================================================================
REM STAGE 4: VALIDATE ACTION METADATA
REM ===========================================================================

echo.
echo ----------------------------------------------------------
echo   STAGE 4/5 - VALIDATE ACTION METADATA
echo ----------------------------------------------------------
echo.
echo   Checking action.yml files for required fields...
echo.

set "VALID=1"

for %%A in (actions\pr-comment\action.yml actions\code-stats\action.yml actions\setup-and-test\action.yml) do (
    echo   Validating %%A...
    findstr /C:"name:" "%%A" >nul 2>&1
    if errorlevel 1 (
        echo     [MISSING] 'name:' field
        set "VALID=0"
    ) else (
        echo     [OK] Has 'name:'
    )
    findstr /C:"description:" "%%A" >nul 2>&1
    if errorlevel 1 (
        echo     [MISSING] 'description:' field
        set "VALID=0"
    ) else (
        echo     [OK] Has 'description:'
    )
    findstr /C:"runs:" "%%A" >nul 2>&1
    if errorlevel 1 (
        echo     [MISSING] 'runs:' field
        set "VALID=0"
    ) else (
        echo     [OK] Has 'runs:'
    )
    echo.
)

if "%VALID%"=="0" (
    echo   [FAILED] Action metadata validation failed!
    echo   PIPELINE STOPPED at stage: VALIDATE YAML
    exit /b 1
)

echo   [PASSED] All action.yml files have required fields
echo.

REM ===========================================================================
REM STAGE 5: CHECK DOCKER (Optional)
REM ===========================================================================

echo.
echo ----------------------------------------------------------
echo   STAGE 5/5 - CHECK DOCKER (Optional)
echo ----------------------------------------------------------
echo.

docker --version >nul 2>&1
if errorlevel 1 (
    echo   [INFO] Docker not found -- skipping Docker validation
    echo   The code-stats action requires Docker and will only
    echo   run on Linux GitHub Actions runners.
    echo.
    echo   [SKIPPED] Docker check skipped
) else (
    echo   Docker found.
    echo   [PASSED] Docker is available
)
echo.

REM ===========================================================================
REM PIPELINE COMPLETE
REM ===========================================================================

echo.
echo ============================================================
echo.
echo    CUSTOM ACTIONS LAB - ALL CHECKS PASSED!
echo.
echo ============================================================
echo.
echo   Pipeline Summary:
echo     [PASSED] Action Files  - All 3 actions have required files
echo     [PASSED] Dependencies  - Python packages installed
echo     [PASSED] Unit Tests    - All utility functions working
echo     [PASSED] Action YAML   - All action.yml files valid
echo     [PASSED] Docker        - Checked (or skipped)
echo.
echo   Next Steps:
echo     Push to GitHub and create a PR to test the actions live!
echo.

endlocal

@echo off
cd /d %~dp0

:: Define the GitHub repository URL (modify as needed)
set "REMOTE_URL=https://github.com/zxyandreay/nameless-rpg-demo.git"

:: Check if Git is installed
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH. Install Git and restart the terminal.
    pause
    exit /b
)

:: Ensure Git LFS is installed
git lfs version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git LFS is not installed. Please install it from https://git-lfs.github.com/
    pause
    exit /b
)

:: Initialize Git LFS
git lfs install

:: Check if current folder is a Git repository, if not then init
if not exist ".git" (
    echo [INFO] No Git repository detected. Initializing one now...
    git init
)

:: Mark repository as safe
echo [INFO] Marking repository as safe...
git config --global --add safe.directory "%CD%"

:: Ensure remote origin exists
git remote -v | find "origin" >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Adding remote origin: %REMOTE_URL%
    git remote add origin %REMOTE_URL%
) else (
    echo [INFO] Remote origin already exists.
)

:: Detect and track large files (above 50MB)
echo [INFO] Checking for large files...
(for /f "delims=" %%A in ('git ls-files') do (
    for /f "tokens=1" %%B in ('git cat-file -s "%%A" 2^>nul') do (
        if %%B gtr 50000000 (
            git lfs track "%%A"
            echo [INFO] Tracked large file with Git LFS: %%A
        )
    )
))

:: Ensure .gitattributes is added
git add .gitattributes

:: Check for files exceeding 100MB
echo [INFO] Checking for files exceeding 100MB...
(for /f "delims=" %%A in ('git ls-files') do (
    for /f "tokens=1" %%B in ('git cat-file -s "%%A" 2^>nul') do (
        if %%B gtr 100000000 (
            echo [WARNING] File exceeds GitHub 100MB limit: %%A
            echo [WARNING] Move this file to Git LFS!
            pause
            exit /b
        )
    )
))

:: Clean repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive

:: Stage changes
echo [INFO] Staging changes...
git add .

:: Skip if nothing to commit
git diff --cached --exit-code >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] No changes detected. Nothing to commit.
    pause
    exit /b
)

:: Commit changes
echo [INFO] Committing...
git commit -m "Updated"

:: Push changes
echo [INFO] Pushing to remote...
git push origin main --force

echo [SUCCESS] Update complete.
pause

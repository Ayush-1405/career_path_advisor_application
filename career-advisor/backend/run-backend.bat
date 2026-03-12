@echo off
echo Starting Career Advisor Backend...
echo.

echo Option 1: Run with test configuration (no database required)
echo Option 2: Run with full configuration (requires MySQL)
echo Option 3: Compile only
echo.

set /p choice="Enter your choice (1, 2, or 3): "

if "%choice%"=="1" (
    echo Running with test configuration...
    mvnw.cmd spring-boot:run -Dspring.profiles.active=test
) else if "%choice%"=="2" (
    echo Running with full configuration...
    mvnw.cmd spring-boot:run
) else if "%choice%"=="3" (
    echo Compiling only...
    mvnw.cmd clean compile
) else (
    echo Invalid choice. Please run the script again.
)

pause

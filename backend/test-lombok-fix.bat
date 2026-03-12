@echo off
echo Testing Lombok fix with Java 24...
echo.

echo Step 1: Cleaning project...
call mvnw.cmd clean

echo.
echo Step 2: Compiling with Lombok 1.18.40...
call mvnw.cmd compile

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! Lombok compilation worked!
    echo.
    echo Step 3: Starting backend...
    call mvnw.cmd spring-boot:run -Dspring.profiles.active=test
) else (
    echo.
    echo FAILED! Lombok still has compatibility issues.
    echo.
    echo Let's try a different approach...
    echo.
    echo Option 1: Install Java 17
    echo Option 2: Use a different Lombok version
    echo Option 3: Remove Lombok completely
)

pause

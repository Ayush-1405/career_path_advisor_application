@echo off
echo Testing backend without Lombok...
echo.

echo Step 1: Cleaning project...
call mvnw.cmd clean

echo.
echo Step 2: Compiling without Lombok...
call mvnw.cmd compile

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! Compilation worked without Lombok.
    echo.
    echo Step 3: Starting backend...
    call mvnw.cmd spring-boot:run -Dspring.profiles.active=test
) else (
    echo.
    echo FAILED! There are still compilation errors.
    echo Please check the error messages above.
)

pause
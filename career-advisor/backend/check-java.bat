@echo off
echo Checking Java installation...
echo.

echo Java version:
java -version
echo.

echo Java compiler version:
javac -version
echo.

echo JAVA_HOME:
echo %JAVA_HOME%
echo.

echo Available Java installations:
where java
echo.

echo Maven version:
mvnw.cmd --version
echo.

pause

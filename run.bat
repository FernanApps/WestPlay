@echo off
setlocal
title WestPlay (dev)
cd /d "%~dp0"

echo ============================================
echo  WestPlay - lanzador de desarrollo
echo ============================================
echo.

where npm >nul 2>nul
if errorlevel 1 (
  echo [ERROR] No se encontro Node.js/npm. Instala Node.js 24 o superior.
  echo         https://nodejs.org
  pause
  exit /b 1
)

where cargo >nul 2>nul
if errorlevel 1 (
  echo [ERROR] No se encontro Rust/cargo. Instala Rust estable.
  echo         https://rustup.rs
  pause
  exit /b 1
)

if not exist "node_modules\.bin\tauri.cmd" (
  echo Instalando dependencias del proyecto...
  call npm install
  if errorlevel 1 (
    echo [ERROR] Fallo npm install.
    pause
    exit /b 1
  )
)

if not exist "ui\node_modules\vite\package.json" (
  echo Instalando dependencias de la interfaz...
  call npm --prefix ui install
  if errorlevel 1 (
    echo [ERROR] Fallo npm install en ui.
    pause
    exit /b 1
  )
)

echo Compilando el plugin del juego...
call cargo build --release -p westplay-plugin
if errorlevel 1 (
  echo [ERROR] No se pudo compilar el plugin westplay.dll.
  pause
  exit /b 1
)

rem Una sola instancia: si ya hay una abierta, se cierra para lanzar la nueva.
tasklist /FI "IMAGENAME eq westplay.exe" 2>nul | find /I "westplay.exe" >nul
if not errorlevel 1 (
  echo Cerrando la instancia anterior de WestPlay...
  taskkill /IM westplay.exe /F >nul 2>nul
  timeout /t 2 /nobreak >nul
)

rem El servidor de desarrollo (Vite) usa el puerto 5173: si quedo uno colgado de otra
rem ejecucion, tauri dev fallaria al arrancar. Solo se cierra si es node (Vite); otro
rem proceso que lo use se avisa y no se toca.
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":5173 .*LISTENING"') do (
  tasklist /FI "PID eq %%p" /NH 2>nul | find /I "node.exe" >nul
  if not errorlevel 1 (
    echo Liberando el puerto 5173 ^(node, PID %%p^)...
    taskkill /PID %%p /F >nul 2>nul
  ) else (
    echo [AVISO] El puerto 5173 lo usa otro proceso ^(PID %%p^); no lo cierro.
  )
)

echo Compilando y lanzando WestPlay...
echo.
call npx --no-install tauri dev
set "CODE=%ERRORLEVEL%"

echo.
if not "%CODE%"=="0" (
  echo WestPlay termino con error ^(codigo %CODE%^).
  echo Revisa los mensajes de arriba; si dice que el puerto 5173 esta ocupado,
  echo cierra las consolas de node que queden y vuelve a ejecutar run.bat.
) else (
  echo WestPlay se cerro.
)
pause
exit /b %CODE%

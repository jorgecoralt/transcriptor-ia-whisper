@echo off
setlocal EnableDelayedExpansion
color 0A
title TRANSCRIPTOR IA - WHISPER v1.0.0 - Ejecutar transcripcion

:: =============================================================
:: VERSION LOCAL
:: =============================================================
set "LOCAL_VERSION=desconocida"
if exist version.txt (
    for /f %%A in (version.txt) do set "LOCAL_VERSION=%%A"
)

:: =============================================================
:: VERSION REMOTA
:: =============================================================
for /f "usebackq tokens=* delims=" %%R in (`powershell -Command "(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jorgecoralt/transcriptor-ia-whisper/main/version.txt' -UseBasicParsing).Content.Trim()"`) do (
    set "REMOTE_VERSION=%%R"
)

:: =============================================================
:: COMPARAR VERSIONES
:: =============================================================
if defined REMOTE_VERSION if defined LOCAL_VERSION if not "!REMOTE_VERSION!"=="!LOCAL_VERSION!" (
    echo.
    echo [+] Hay una nueva version disponible del Transcriptor IA - Whisper
    echo.
    echo Version instalada : !LOCAL_VERSION!
    echo Version disponible: !REMOTE_VERSION!
    echo.
    echo Puedes descargarla aqui:
    echo https://jorgecoral.com/transcriptor-ia-whisper
    start https://jorgecoral.com/transcriptor-ia-whisper
    echo.
    pause
)

:: =============================================================
:: BIENVENIDA
:: =============================================================
cls
echo =============================================================
echo        TRANSCRIPTOR IA - WHISPER - INICIAR TRANSCRIPCION
echo =============================================================
echo.
echo Esta herramienta convierte tus audios y videos en texto
echo usando inteligencia artificial local.
echo.
echo Mas informacion y ejemplos:
echo https://jorgecoral.com/transcriptor-ia-whisper
echo.
pause

:: =============================================================
:: ACTIVAR ENTORNO VIRTUAL
:: =============================================================
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
) else (
    echo [X] No se encontro el entorno virtual.
    echo Ejecuta primero: instalar.bat
    pause
    exit /b
)

:: =============================================================
:: DETECCION Y CONVERSION
:: =============================================================
:inicio_validacion
set "ARCHIVO_ORIG="
set "MEDIA_DIR=%~dp0media"

:: Buscar el primer archivo en la carpeta media
for %%F in ("%MEDIA_DIR%\*") do (
    set "ARCHIVO_ORIG=%%F"
    goto :procesar_archivo
)

:no_hay_archivos
cls
echo.
echo [X] No se encontro ningun archivo en la carpeta "media".
echo Coloca un archivo y presiona una tecla para continuar.
echo.
pause >nul
goto :inicio_validacion

:procesar_archivo
:: Verificar si ya es .wav
for %%F in ("%ARCHIVO_ORIG%") do (
    set "EXT=%%~xF"
    set "NOMBRE=%%~nF"
)

if /I "%EXT%"==".wav" (
    set "ARCHIVO_WAV=%ARCHIVO_ORIG%"
    goto :normalizar_archivo
)

:: Si no es .wav, convertir
set "ARCHIVO_PROC=%MEDIA_DIR%\%NOMBRE%.wav"
echo.
echo [+] Convirtiendo archivo a WAV mono 16kHz...

:: Buscar ffmpeg
set "FFMPEG_EXE="
for /r "%~dp0ffmpeg" %%X in (ffmpeg.exe) do (
    echo %%X | findstr /i "\\bin\\ffmpeg.exe" >nul
    if not errorlevel 1 (
        set "FFMPEG_EXE=%%X"
        goto :ffmpeg_encontrado
    )
)

:ffmpeg_encontrado
if not defined FFMPEG_EXE (
    echo.
    echo [X] No se encontro ffmpeg en /ffmpeg\bin
    echo Ejecuta "instalar.bat" para restaurarlo.
    pause
    exit /b
)

:: Ejecutar conversion
"!FFMPEG_EXE!" -y -i "%ARCHIVO_ORIG%" -ar 16000 -ac 1 "%ARCHIVO_PROC%"

if exist "%ARCHIVO_PROC%" (
    echo [OK] Conversion exitosa: %ARCHIVO_PROC%
    set "ARCHIVO_WAV=%ARCHIVO_PROC%"
    goto :normalizar_archivo
) else (
    echo [X] No se pudo convertir el archivo.
    pause
    exit /b
)

:: =============================================================
:: RENOMBRAR ARCHIVO A NOMBRE SEGURO
:: =============================================================
:normalizar_archivo
echo.
echo -------------------------------------------------------------
echo Renombrando archivo a: medio_preparado.wav
echo -------------------------------------------------------------

set "NOMBRE_OBJETIVO=medio_preparado.wav"
set "DESTINO=%MEDIA_DIR%\%NOMBRE_OBJETIVO%"

:: Si ya tiene el nombre correcto, continuar sin renombrar
for %%F in ("%ARCHIVO_WAV%") do (
    if /I "%%~nxF"=="%NOMBRE_OBJETIVO%" (
        set "ARCHIVO=%ARCHIVO_WAV%"
        echo [OK] El archivo ya tiene el nombre esperado.
        goto :fin_normalizar
    )
)

:: Borrar destino si existe (solo si es otro)
if exist "%DESTINO%" del /f /q "%DESTINO%"

:: Renombrar el archivo original al nombre seguro
ren "%ARCHIVO_WAV%" "%NOMBRE_OBJETIVO%" >nul 2>&1
set "ARCHIVO=%DESTINO%"

if not exist "%ARCHIVO%" (
    echo [X] No se pudo renombrar el archivo.
    pause
    exit /b
)

echo [OK] Archivo listo: %ARCHIVO%

:fin_normalizar
goto :seleccionar_modo


:: =============================================================
:: SELECCION DE MODO
:: =============================================================
:seleccionar_modo
echo.
echo =============================================================
echo        TRANSCRIPTOR IA - WHISPER - SELECCION DE MODO
echo =============================================================
echo -------------------------------------------------------------
echo [1] Modo Basico        - Transcripcion directa
echo [2] Modo con Pausas    - Segmentado por silencios
::echo [3] Modo PRO           - Separacion de hablantes (requiere token)
echo -------------------------------------------------------------
echo.
::set /p MODO_ELEGIDO=Selecciona el modo (1, 2 o 3):
set /p MODO_ELEGIDO=Selecciona el modo (1 o 2):

if "%MODO_ELEGIDO%"=="1" goto :modo1
if "%MODO_ELEGIDO%"=="2" goto :modo2
::if "%MODO_ELEGIDO%"=="3" goto :modo3

echo.
echo [X] Opcion no valida.
goto :seleccionar_modo

:: =============================================================
:: MODOS DE EJECUCION
:: =============================================================
:modo1
echo Ejecutando modo basico...
python utils\modobasico.py
goto :fin

:modo2
echo Ejecutando modo con pausas...
python utils\modopausas.py
goto :fin

:modo3
echo Verificando token...

:: Leer y limpiar token de Hugging Face desde configuracion.txt
set "TOKEN_VALIDO="
for /f "usebackq tokens=1,* delims==" %%A in ("configuracion.txt") do (
    if /I "%%A"=="HUGGINGFACE_TOKEN" (
        set "TOKEN_VALIDO=%%B"
    )
)

:: Quitar espacios (por si hay copiados o errores)
set "TOKEN_VALIDO=%TOKEN_VALIDO: =%"
for /f "tokens=* delims=" %%X in ("%TOKEN_VALIDO%") do set "TOKEN_VALIDO=%%X"

:: Verificar si quedó vacío
if not defined TOKEN_VALIDO (
    echo.
    echo [X] No se encontro un token de Hugging Face valido.
    echo Asegurate de que el archivo configuracion.txt tenga esta linea:
    echo   HUGGINGFACE_TOKEN=tu_token_aqui
    echo.
    pause
    exit /b
)

:: Reescribir configuracion.txt con el valor limpio
(
  echo HUGGINGFACE_TOKEN=%TOKEN_VALIDO%
) > "configuracion.txt"

echo [OK] Token cargado y normalizado.



echo Token detectado. Ejecutando modo PRO...
python utils\modopro.py --token %TOKEN_VALIDO%
goto :fin

:: =============================================================
:: FINAL
:: =============================================================
:fin
echo.
echo =============================================================
echo Transcripcion finalizada.
echo =============================================================
echo Archivos guardados en la carpeta: salidas\
echo.
echo Presiona Enter para salir...
pause >nul
exit

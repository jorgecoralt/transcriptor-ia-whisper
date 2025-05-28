@echo off
:: ============================================================
:: INSTALADOR - TRANSCRIPTOR IA - WHISPER vCPU v2.0.0
:: Autor: Jorge Coral - https://jorgecoral.com
:: ============================================================

:: Verificar permisos de administrador
openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [+] Se requieren permisos de administrador.
    pause
    powershell Start-Process '%0' -Verb runAs
    exit /b
)

cls
color 0A
title Instalador Transcriptor IA - WHISPER (SOLO CPU)

echo ============================================================
echo INSTALADOR DE TRANSCRIPTOR IA - WHISPER (VERSION CPU)
echo ============================================================
echo.
echo Esta version funciona en cualquier equipo con CPU.
echo No requiere tarjeta grafica NVIDIA ni CUDA.
echo.
echo Carpeta de instalacion:
echo %~dp0
echo.
set /p CONFIRMAR_INSTALACION= Deseas continuar? [S/N] (Enter = Si):

if /i "%CONFIRMAR_INSTALACION%"=="N" (
    echo Instalacion cancelada por el usuario.
    pause
    exit /b
)

call :VERIFICAR_PYTHON

goto :CREAR_CARPETAS


:VERIFICAR_PYTHON
cls
echo.
echo Verificando instalacion de Python...
for /f "tokens=2 delims= " %%I in ('python --version 2^>nul') do set PY_VER=%%I

if "%PY_VER%"=="" goto INSTALAR_PYTHON

echo Version de Python detectada: %PY_VER%
set PY_MAJOR=%PY_VER:~0,1%
set PY_MINOR=%PY_VER:~2,2%

if not "%PY_MAJOR%"=="3" (
    goto INSTALAR_PYTHON
) else if not "%PY_MINOR%"=="11" (
    goto INSTALAR_PYTHON
)

echo Version compatible detectada.
goto :EOF


:INSTALAR_PYTHON
cls
echo =============================================================
echo INSTALANDO PYTHON 3.11.6 (veras todo el proceso en pantalla)
echo =============================================================

set "PYTHON_INSTALLER=python-3.11.6-amd64.exe"

echo [+] Descargando Python...
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe' -OutFile '%PYTHON_INSTALLER%'"

if not exist "%PYTHON_INSTALLER%" (
    echo [X] No se pudo descargar el instalador.
    pause
    exit /b
)

for %%A in ("%PYTHON_INSTALLER%") do if %%~zA lss 1024 (
    echo [X] El instalador parece estar corrupto.
    pause
    exit /b
)

echo [+] Ejecutando instalador...
start /wait "" "%PYTHON_INSTALLER%" /passive InstallAllUsers=1 PrependPath=1 Include_test=0

if %errorlevel% neq 0 (
    echo [X] Error en la instalacion de Python.
    start https://www.python.org/downloads/release/python-3116/
    pause
    exit
)

echo.
echo [OK] Python instalado correctamente.
echo.
echo Por favor reinicia este instalador para continuar.
pause
exit

:CREAR_CARPETAS
cls
color 0A
echo =============================================================
echo PREPARANDO ESTRUCTURA DE CARPETAS
echo =============================================================

:: Crear carpetas básicas si no existen
if not exist "%~dp0media" mkdir "%~dp0media"
if not exist "%~dp0salidas" mkdir "%~dp0salidas"

:: Crear archivo de versión
echo 1.0.0 > "%~dp0version.txt"
echo [OK] Archivo version.txt creado (v1.0.0)

:: Crear archivo de configuración para el token (modo PRO)
if not exist "%~dp0configuracion.txt" (
    echo HUGGINGFACE_TOKEN= > "%~dp0configuracion.txt"
    echo [OK] Archivo de configuracion.txt creado
)

goto :ENTORNO_VIRTUAL


:ENTORNO_VIRTUAL
cls
color 0A
echo =============================================================
echo CREANDO Y ACTIVANDO ENTORNO VIRTUAL
echo =============================================================

:: Crear entorno virtual si no existe
if not exist "%~dp0venv" (
    echo [+] Creando entorno virtual...
    python -m venv "%~dp0venv"
)

:: Activar entorno virtual
call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

:: Actualizar pip
echo [+] Actualizando pip...
python -m pip install --upgrade pip

goto :INSTALAR_DEPENDENCIAS_CPU


:INSTALAR_DEPENDENCIAS_CPU
cls
echo =============================================================
echo INSTALANDO DEPENDENCIAS (Modo CPU)
echo =============================================================

echo [+] Instalando PyTorch (CPU only)...
python -m pip install --force-reinstall torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2

echo [+] Instalando Whisper y WhisperX...
python -m pip install openai-whisper==20230918
python -m pip install whisperx==3.3.4 --no-deps

echo [+] Instalando librerías auxiliares...
python -m pip install pydub==0.25.1 ffmpeg-python==0.2.0 pandas==2.1.4
python -m pip install ctranslate2==4.4.0
python -m pip install faster-whisper==1.4.0

echo [+] Instalando dependencias adicionales para modo PRO...
python -m pip install "transformers==4.36.2" librosa numpy nltk
python -m pip install pyannote-audio==2.1.1
python -m pip install onnxruntime

echo [+] Descargando datos de tokenizacion de nltk (punkt)...
echo import nltk> nltk_download.py
echo nltk.download('punkt')>> nltk_download.py
python nltk_download.py
del nltk_download.py

echo.
echo -------------------------------------------------------------
echo NOTA: Estas versiones estan optimizadas para funcionar en CPU.
echo No se requieren drivers ni tarjetas graficas avanzadas.
echo -------------------------------------------------------------

if %errorlevel% neq 0 (
    echo [X] Error durante la instalacion de dependencias.
    pause
    exit /b
)

echo [OK] Dependencias instaladas correctamente.
goto :INSTALAR_FFMPEG


:INSTALAR_FFMPEG
cls
echo =============================================================
echo INSTALANDO FFMPEG (Requerido para audios y videos)
echo =============================================================

set "FFMPEG_DIR=%~dp0ffmpeg"
set "FFMPEG_ZIP=ffmpeg.zip"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

:: Verificar si ya existe la carpeta ffmpeg y contiene ffmpeg.exe
if exist "%FFMPEG_DIR%" (
    for /r "%FFMPEG_DIR%" %%F in (ffmpeg.exe) do (
        echo [+] FFmpeg ya esta instalado localmente en: %%F
        set "FFMPEG_BIN=%%~dpF"
        goto FFMPEG_ENCONTRADO
    )
)

:: Si no existe, descargar y extraer
echo [+] Descargando FFmpeg...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%FFMPEG_ZIP%' -UseBasicParsing"

echo [+] Extrayendo archivos...
powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_DIR%'"
del "%FFMPEG_ZIP%"

:: Buscar carpeta extraída
setlocal enabledelayedexpansion
for /d %%D in ("%FFMPEG_DIR%\ffmpeg-*") do (
    set "FFMPEG_BIN=%%D\bin"
)
endlocal & set "FFMPEG_BIN=%FFMPEG_BIN%"

:: Verificar que ffmpeg.exe existe
if not exist "%FFMPEG_BIN%\ffmpeg.exe" (
    echo [X] No se encontro ffmpeg.exe en la carpeta esperada.
    echo     Verifica la descarga manualmente en: %FFMPEG_DIR%
    pause
    goto :EOF
)

:FFMPEG_ENCONTRADO
:: Agregar a PATH para esta sesión
set "PATH=%PATH%;%FFMPEG_BIN%"
echo.
echo [OK] FFmpeg instalado y agregado correctamente.
goto :INSTALAR_MODOS


:INSTALAR_MODOS
cls
color 0A
echo =============================================================
echo INSTALACION DE MODOS DE TRANSCRIPCION
echo =============================================================
echo [+] Modo 1: Transcripcion directa
echo [+] Modo 2: Transcripcion segmentada por pausas
echo [+] Modo 3: Transcripcion con separacion de hablantes (requiere token)
echo -------------------------------------------------------------
echo Todos los modos fueron habilitados correctamente.
goto :CONFIGURAR_TOKEN


:CONFIGURAR_TOKEN
cls
color 0A
echo =============================================================
echo CONFIGURACION DEL TOKEN PARA MODO PRO (Hugging Face)
echo =============================================================
echo El modo PRO permite separar hablantes (diarizacion).
echo Necesitas un token gratuito de https://huggingface.co
echo -------------------------------------------------------------

set /p QUIERE_TOKEN=Deseas ingresar tu token ahora? [S/N] (Enter=No): 

if /i "%QUIERE_TOKEN%"=="S" (
    set /p TOKEN=Ingresa tu token:
    echo HUGGINGFACE_TOKEN=%TOKEN%>configuracion.txt
    echo.
    echo [OK] Token guardado correctamente.
) else (
    echo.
    echo Puedes agregar tu token luego en el archivo: configuracion.txt
)

goto :CIERRE


:CIERRE
cls
color 0A
echo =============================================================
echo INSTALACION COMPLETADA CON EXITO
echo =============================================================
echo.
echo Tus carpetas ya estan listas:
echo   - media\    → aqui van tus videos o audios
echo   - salidas\  → aqui verás los textos generados
echo.
echo Para comenzar, ejecuta:
echo   transcribir.bat
echo.
echo Si necesitas ejemplos, tutoriales o soporte, visita:
echo   https://jorgecoral.com/transcriptor-ia-whisper
echo.
start https://jorgecoral.com/transcriptor-ia-whisper
echo.
goto :EOF

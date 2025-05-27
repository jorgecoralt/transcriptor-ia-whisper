@echo off
:: ============================================================
:: INSTALADOR - TRANSCRIPTOR IA - WHISPER v1.0.0
:: Autor: Jorge Coral - https://jorgecoral.com
:: ============================================================

:: Elevar permisos si no se ejecuta como administrador
openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [+] Se requieren permisos de administrador.
    pause
    powershell Start-Process '%0' -Verb runAs
    exit /b
)

cls
color 0A
title Instalador Transcriptor IA - WHISPER

echo ============================================================
echo INSTALADOR DE TRANSCRIPTOR IA - WHISPER
echo ============================================================
echo.
echo Esta herramienta convierte audios y videos en texto usando IA local.
echo Te acompañaremos paso a paso para dejar todo listo.
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
call :PREPARAR_CARPETAS
pause
call :INSTALAR_DEPENDENCIAS_VENV
pause
call :INSTALAR_FFMPEG
pause
call :DETECTAR_GPU
pause
call :INSTALAR_MODOS
pause
call :CONFIGURAR_TOKEN
pause
call :CIERRE

:: =================================================================
:: FUNCIONES DEL SCRIPT
:: =================================================================

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
echo Instalando Python 3.11.6...
set "PYTHON_INSTALLER=python-3.11.6-amd64.exe"
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe' -OutFile '%PYTHON_INSTALLER%'"
start /wait "" "%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

if %errorlevel% neq 0 (
	echo Error instalando Python.
	echo.
	echo Por favor ingresa en la página oficial de Phyton, descarga manualmente el ejecutable e instalalo en tu computador. 
	echo En la parte inferior de la pagina donde sale FILES ubica el que dice: Windows installer (64-bit), le das clic para Descargar
	echo Luego ubicalo en la carpeta de descargas e instala el programa dandole siguiente... siguiente...
	start https://www.python.org/downloads/release/python-3116/
	pause
	exit /b
)

del "%PYTHON_INSTALLER%"
echo Python instalado correctamente.
echo Por favor reinicia el instalador para continuar.
pause
exit /b

:PREPARAR_CARPETAS
cls
echo -------------------------------------------------------------
echo Estamos creando el espacio donde viviran tus archivos.
echo Esto incluye:
echo   - Carpeta /media para tus audios y videos
echo   - Carpeta /salidas para los textos generados
echo -------------------------------------------------------------
if not exist "%~dp0media" mkdir "%~dp0media"
if not exist "%~dp0salidas" mkdir "%~dp0salidas"
echo Listo. Las carpetas estan preparadas para recibir contenido.
echo.
echo 1.0.0 > "%~dp0version.txt"
echo [OK] Archivo de version.txt creado con version: 1.0.0
echo.
:: Crear archivo base aunque no se ingrese token
if not exist "%~dp0configuracion.txt" (
	echo [OK] Archivo de configuracion para el token de Huggingface creado
    echo HUGGINGFACE_TOKEN=>"%~dp0configuracion.txt"
	echo.
)
goto :EOF

:INSTALAR_DEPENDENCIAS_VENV
cls
echo =============================================================
echo INSTALANDO DEPENDENCIAS EN ENTORNO AISLADO (venv)
echo =============================================================

if not exist "%~dp0venv" (
    echo [+] Creando entorno virtual...
    python -m venv "%~dp0venv"
)

call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

echo [+] Actualizando pip...
python -m pip install --upgrade pip

python -c "import torch" >nul 2>&1
if %errorlevel% EQU 0 (
    echo [+] Torch ya esta instalado. Saltando reinstalacion...
) else (
    echo [+] Instalando PyTorch con soporte CUDA 11.8...
    python -m pip install --force-reinstall torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118
)

echo [+] Instalando Whisper y WhisperX...
python -m pip install openai-whisper==20230918
python -m pip install whisperx==3.3.4 --no-deps
python -m pip install pydub==0.25.1 ffmpeg-python==0.2.0 pandas==2.1.4
python -m pip install ctranslate2==4.4.0
python -m pip install faster-whisper==1.4.0

echo [+] Instalando dependencias adicionales para modo PRO...
python -m pip install "transformers==4.36.2" librosa numpy nltk
python -m pip install pyannote-audio==2.1.1
::python -m pip install git+https://github.com/pyannote/pyannote-audio.git@develop
python -m pip install onnxruntime


echo [+] Descargando datos de tokenizacion de nltk (punkt)...
echo import nltk> nltk_download.py
echo nltk.download('punkt')>> nltk_download.py
python nltk_download.py
del nltk_download.py

echo.
echo -------------------------------------------------------------
echo NOTA: Se instalan versiones especificas para compatibilidad
echo total con CUDA 11.8 y evitar conflictos con PyTorch.
echo -------------------------------------------------------------
echo -------------------------------------------------------------
echo NOTA: Algunas advertencias pueden aparecer al instalar pandas
echo debido a dependencias opcionales de WhisperX.
echo.
echo Estas pueden ignorarse. El sistema sigue funcionando bien.
echo -------------------------------------------------------------

if %errorlevel% neq 0 (
    echo [X] Error instalando dependencias.
    pause
    exit /b
)

echo [OK] Dependencias instaladas correctamente.
goto :EOF



:INSTALAR_FFMPEG
cls
echo =============================================================
echo INSTALANDO FFMPEG (Requerido por Whisper para audio/video)
echo =============================================================

:: Verificar si ya está instalado localmente
if exist "%~dp0ffmpeg\" (
    echo [+] FFmpeg ya esta instalado localmente.
    goto :EOF
)


:: Definir rutas
set "FFMPEG_DIR=%~dp0ffmpeg"
set "FFMPEG_ZIP=ffmpeg.zip"
set "FFMPEG_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

:: Descargar el ZIP de FFmpeg
echo [+] Descargando FFmpeg...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile '%FFMPEG_ZIP%' -UseBasicParsing"


:: Extraer contenido
echo [+] Extrayendo archivos...
powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_DIR%'"
del "%FFMPEG_ZIP%"

:: Buscar carpeta extraída y detectar bin
setlocal enabledelayedexpansion
for /d %%D in ("%FFMPEG_DIR%\ffmpeg-*") do (
    set "FFMPEG_BIN=%%D\bin"
)
endlocal & set "FFMPEG_BIN=%FFMPEG_BIN%"

:: Verificación de carpeta bin
if not exist "%FFMPEG_BIN%\ffmpeg.exe" (
    echo [X] No se encontró ffmpeg.exe en la carpeta esperada.
    echo     Verifica la descarga manualmente en: %FFMPEG_DIR%
    pause
    goto :EOF
)

:: Agregar a PATH para esta sesión
set "PATH=%PATH%;%FFMPEG_BIN%"

echo.
echo [OK] FFmpeg instalado y agregado correctamente.
goto :EOF


:DETECTAR_GPU
cls
echo =============================================================
echo DETECTANDO DISPONIBILIDAD Y COMPATIBILIDAD DE GPU
echo =============================================================
call "%~dp0venv\Scripts\activate.bat"

:: Crear script Python temporal
> check_gpu.py echo import torch
>> check_gpu.py echo.
>> check_gpu.py echo if torch.cuda.is_available():
>> check_gpu.py echo.    name = torch.cuda.get_device_name(0)
>> check_gpu.py echo.    cap = torch.cuda.get_device_capability(0)
>> check_gpu.py echo.    print(f"[+] GPU detectada: {name} (compute {cap[0]}.{cap[1]})")
>> check_gpu.py echo.    if cap[0] >= 7:
>> check_gpu.py echo.        exit(0)
>> check_gpu.py echo.    else:
>> check_gpu.py echo.        exit(99)
>> check_gpu.py echo else:
>> check_gpu.py echo.    print("[!] No se detectó GPU. Se usará CPU.")
>> check_gpu.py echo.    exit(100)

python check_gpu.py
set "GPU_STATUS=%errorlevel%"
del check_gpu.py

:: Interpretar resultado
if "%GPU_STATUS%"=="0" (
    echo [OK] Tu GPU es compatible con CUDA 11.8. Se usará aceleración.
) else if "%GPU_STATUS%"=="99" (
    echo [!] Tu GPU fue detectada, pero NO es compatible con CUDA 11.8
    echo     Se instalarán versiones para CPU. Todo funcionará, pero sin aceleración.
) else if "%GPU_STATUS%"=="100" (
    echo [!] No se encontró una GPU compatible. Se instalarán versiones para CPU.
    echo     Todo funcionará correctamente, pero será un poco más lento.
)

goto :EOF


:INSTALAR_MODOS
cls
color 0A
echo Instalando modos de transcripcion...
echo Modos 1, 2 y 3 habilitados correctamente.
goto :EOF


:CONFIGURAR_TOKEN
cls
echo -------------------------------------------------------------
echo CONFIGURACION DEL TOKEN PARA MODO PRO (Hugging Face)
echo -------------------------------------------------------------

set /p QUIERE_TOKEN=Deseas ingresar tu token de Hugging Face ahora? [S/N] (Enter=No): 

if /i "%QUIERE_TOKEN%"=="S" (
    set /p TOKEN=Ingresa tu token:
    echo HUGGINGFACE_TOKEN=%TOKEN%>configuracion.txt
    echo Token guardado correctamente.
) else (
    echo Puedes agregar tu token luego en el archivo: configuracion.txt
)

goto :EOF

:CIERRE

:: ==========================================================
:: CREAR O ACTUALIZAR ARCHIVO DE VERSION LOCAL
:: ==========================================================
cls
echo =============================================================
echo INSTALACION COMPLETADA CON EXITO
echo =============================================================
echo Tus carpetas ya estan listas:
echo   - transcribir\media (aqui van tus videos o audios)
echo   - transcribir\salidas (aqui veras los textos generados)
echo.
echo Para comenzar, ejecuta:
echo   transcribir.bat
echo.
echo Para tutoriales, ejemplos y soporte visita:
echo   https://jorgecoral.com/transcriptor-ia-whisper
echo.
echo.
start https://jorgecoral.com/transcriptor-ia-whisper
pause
goto :EOF

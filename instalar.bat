@echo off
:: ============================================================
:: INSTALADOR - TRANSCRIPTOR IA - WHISPER v1.2.0 (modular)
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
echo Te guiare paso a paso para dejar todo listo.
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
call :INSTALAR_VENV_Y_BASE
pause
call :INSTALAR_TORCH_CPU_TEMP
pause
call :DETECTAR_GPU
pause
call :INSTALAR_TORCH_SEGUN_GPU
pause
call :INSTALAR_OTRAS_DEPENDENCIAS
pause
call :INSTALAR_FFMPEG
pause
call :INSTALAR_MODOS
pause
call :CONFIGURAR_TOKEN
pause
call :CIERRE

goto :EOF

:VERIFICAR_PYTHON
cls
echo =============================================================
echo VERIFICANDO INSTALACION DE PYTHON 3.11
echo =============================================================

for /f "tokens=2 delims= " %%I in ('python --version 2^>nul') do set "PY_VER=%%I"

if "%PY_VER%"=="" goto INSTALAR_PYTHON

echo Version de Python detectada: %PY_VER%
set "PY_MAJOR=%PY_VER:~0,1%"
set "PY_MINOR=%PY_VER:~2,2%"

if not "%PY_MAJOR%"=="3" (
    goto INSTALAR_PYTHON
) else if not "%PY_MINOR%"=="11" (
    goto INSTALAR_PYTHON
)

echo [OK] Version compatible detectada.
goto :EOF

:PREPARAR_CARPETAS
cls
color 0A
echo =============================================================
echo PREPARANDO ESTRUCTURA DE CARPETAS DEL PROYECTO
echo =============================================================

:: Crear carpetas base
if not exist "%~dp0media" (
    mkdir "%~dp0media"
    echo [+] Carpeta creada: media
)
if not exist "%~dp0salidas" (
    mkdir "%~dp0salidas"
    echo [+] Carpeta creada: salidas
)

:: Crear archivo de version
if not exist "%~dp0version.txt" (
    echo 1.0.0 > "%~dp0version.txt"
    echo [+] Archivo version.txt creado con version 1.0.0
)

:: Crear archivo base de configuración
if not exist "%~dp0configuracion.txt" (
    echo HUGGINGFACE_TOKEN= > "%~dp0configuracion.txt"
    echo [+] Archivo configuracion.txt creado (sin token)
)

echo.
echo [OK] Estructura inicial lista.
goto :EOF

:INSTALAR_VENV_Y_BASE
cls
color 0A
echo =============================================================
echo CREANDO ENTORNO VIRTUAL Y ACTUALIZANDO PIP
echo =============================================================

:: Verifica si el entorno ya existe
if not exist "%~dp0venv" (
    echo [+] Creando entorno virtual...
    python -m venv "%~dp0venv"
)

:: Activar entorno
call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

:: Actualizar pip
echo [+] Actualizando pip...
python -m pip install --upgrade pip

goto :EOF

:DETECTAR_GPU
cls
color 0A
echo =============================================================
echo DETECTANDO DISPONIBILIDAD Y COMPATIBILIDAD DE GPU
echo =============================================================

:: Activar entorno virtual
call "%~dp0venv\Scripts\activate.bat"

:: Crear archivo Python temporal
echo import torch > check_gpu.py
echo. >> check_gpu.py
echo if torch.cuda.is_available(): >> check_gpu.py
echo     cap = torch.cuda.get_device_capability(0) >> check_gpu.py
echo     if cap[0] ^>= 7: >> check_gpu.py
echo         exit(0) >> check_gpu.py
echo     else: >> check_gpu.py
echo         exit(99) >> check_gpu.py
echo else: >> check_gpu.py
echo     exit(100) >> check_gpu.py

python check_gpu.py
set "GPU_STATUS=%errorlevel%"
del check_gpu.py

if "%GPU_STATUS%"=="0" (
    echo [OK] GPU compatible con CUDA 11.8. Se usara aceleracion.
) else if "%GPU_STATUS%"=="99" (
    echo [!] GPU detectada, pero NO compatible con CUDA 11.8.
    echo     Se instalaran versiones para CPU.
) else if "%GPU_STATUS%"=="100" (
    echo [!] No se encontro GPU. Se utilizara CPU.
)

goto :EOF

:INSTALAR_DEPENDENCIAS_POR_GPU
cls
color 0A
echo =============================================================
echo INSTALANDO DEPENDENCIAS DE IA SEGUN TU COMPUTADOR
echo =============================================================

:: Activar entorno virtual por si se invoca aisladamente
call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

echo [+] Actualizando pip...
python -m pip install --upgrade pip

:: Instalar PyTorch según compatibilidad GPU detectada
if "%GPU_STATUS%"=="0" (
    echo [+] Instalando PyTorch con soporte CUDA 11.8...
    python -m pip install --force-reinstall torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118
) else (
    echo [+] Instalando PyTorch solo para CPU...
    python -m pip install --force-reinstall torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2
)

if %errorlevel% neq 0 (
    echo [X] Error durante la instalacion de PyTorch.
    pause
    exit /b
)

echo [OK] PyTorch instalado correctamente segun tu sistema.
goto :EOF


:INSTALAR_LIBRERIAS_RESTO
cls
color 0A
echo =============================================================
echo INSTALANDO LIBRERIAS BASE DEL TRANSCRIPTOR IA
echo =============================================================

call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

echo [+] Instalando Whisper y WhisperX...
python -m pip install openai-whisper==20230918
python -m pip install whisperx==3.3.4 --no-deps

echo [+] Instalando librerias auxiliares...
python -m pip install pydub==0.25.1 ffmpeg-python==0.2.0 pandas==2.1.4
python -m pip install ctranslate2==4.4.0
python -m pip install faster-whisper==1.4.0

if %errorlevel% neq 0 (
    echo [X] Error durante la instalacion de librerias base.
    pause
    exit /b
)

echo [OK] Librerias base instaladas correctamente.
goto :EOF


:INSTALAR_LIBRERIAS_PRO
cls
color 0A
echo =============================================================
echo INSTALANDO DEPENDENCIAS PARA MODO PRO (Separacion de voces)
echo =============================================================

call "%~dp0venv\Scripts\activate.bat"
echo [+] Entorno virtual activado.

echo [+] Instalando transformers, librosa, numpy, nltk...
python -m pip install "transformers==4.36.2" librosa numpy nltk

echo [+] Instalando pyannote-audio...
python -m pip install pyannote-audio==2.1.1
:: Alternativa (dev): 
:: python -m pip install git+https://github.com/pyannote/pyannote-audio.git@develop

echo [+] Instalando onnxruntime...
python -m pip install onnxruntime

echo [+] Descargando datos de tokenización para nltk (punkt)...
echo import nltk > nltk_download.py
echo nltk.download('punkt') >> nltk_download.py
python nltk_download.py
del nltk_download.py

if %errorlevel% neq 0 (
    echo [X] Error durante la instalacion de librerias PRO.
    pause
    exit /b
)

echo [OK] Dependencias PRO instaladas correctamente.
goto :EOF


:CONFIGURAR_TOKEN
cls
color 0A
echo =============================================================
echo CONFIGURACION DEL TOKEN PARA MODO PRO (Hugging Face)
echo =============================================================

set /p QUIERE_TOKEN=¿Deseas ingresar tu token de Hugging Face ahora? [S/N] (Enter=No): 

if /i "%QUIERE_TOKEN%"=="S" (
    set /p TOKEN=Ingresa tu token:
    echo HUGGINGFACE_TOKEN=%TOKEN%>configuracion.txt
    echo Token guardado correctamente.
) else (
    echo Puedes agregar tu token luego editando el archivo: configuracion.txt
    if not exist "configuracion.txt" (
        echo HUGGINGFACE_TOKEN= > configuracion.txt
        echo [OK] Archivo de configuracion creado por defecto.
    )
)

goto :EOF


:CIERRE
cls
color 0A
echo =============================================================
echo INSTALACION COMPLETADA CON EXITO
echo =============================================================
echo Tus carpetas ya estan listas:
echo   - transcribir\media    → aqui van tus videos o audios
echo   - transcribir\salidas  → aqui veras los textos generados
echo.
echo Para comenzar, ejecuta:
echo   transcribir.bat
echo.
echo Para tutoriales, ejemplos y soporte visita:
echo   https://jorgecoral.com/transcriptor-ia-whisper
echo.
start https://jorgecoral.com/transcriptor-ia-whisper
pause
goto :EOF

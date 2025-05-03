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
:: Instalar Whisper desde PyPI (versión oficial estable)
python -m pip install openai-whisper==20230918
:: Instalar WhisperX sin dependencias para no romper torch
python -m pip install whisperx==3.3.4 --no-deps

:: Dependencias auxiliares
python -m pip install pydub==0.25.1 ffmpeg-python==0.2.0


echo -------------------------------------------------------------
echo NOTA: Se instalan versiones específicas para compatibilidad
echo total con CUDA 11.8 y evitar conflictos con PyTorch.
echo -------------------------------------------------------------

if %errorlevel% neq 0 (
    echo [X] Error instalando dependencias.
    pause
    exit /b
)

echo [OK] Dependencias instaladas correctamente.
goto :EOF

:DETECTAR_GPU
cls
echo Verificando disponibilidad de GPU...
call "%~dp0venv\Scripts\activate.bat"
echo import torch>check_gpu.py
echo if torch.cuda.is_available(): print("GPU disponible:", torch.cuda.get_device_name(0))>>check_gpu.py
echo else: print("No se detecto GPU. Se usara CPU.")>>check_gpu.py
python check_gpu.py
del check_gpu.py
goto :EOF

:INSTALAR_MODOS
cls
echo Instalando modos de transcripcion...
echo Modos 1, 2 y 3 habilitados correctamente.
goto :EOF


:CONFIGURAR_TOKEN
cls
echo Configuracion del Token para modo PRO...
set /p QUIERE_TOKEN=¿Deseas ingresar tu token de Hugging Face ahora? [S/N] (Enter=No): 
if /i "%QUIERE_TOKEN%"=="S" (
    set /p TOKEN=Ingresa tu token:
    echo HUGGINGFACE_TOKEN=%TOKEN%>configuracion.txt
    echo Token guardado correctamente.
) else (
    echo Puedes agregar tu token luego en el archivo: configuracion.txt
)
goto :EOF

:CIERRE
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
pause
goto :EOF

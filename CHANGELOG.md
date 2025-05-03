# 📜 Changelog - Transcriptor IA Local

Todos los cambios notables de este proyecto serán documentados aquí.

---

## [1.0.0] - 2025-05-01

🚀 **Primera versión oficial lanzada**

### Agregado

- Instalador automatizado `instalar.bat` con selección de modos:
  - Modo Básico
  - Modo con Pausas
  - Modo PRO (diarización con WhisperX)
- Verificación automática de Python y detección de GPU compatible.
- Instalación de dependencias específicas por modo.
- Solicitud de token Hugging Face para el modo PRO.
- `transcribir.bat` con selección dinámica de modos y ejecución guiada.
- Carpeta `/Utils/` con lógica modular para:
  - `Modobasico.py`
  - `Modopausas.py`
  - `Modopro.py`
  - `Commons.py` (funciones compartidas)
- Carpetas de salida separadas: `/salidas/`, `/salidas_pausas/`, `/salidas_pro/`
- Carpeta `/transcribir/media/` para archivo de entrada.
- `.gitignore` para excluir carpetas sensibles y temporales.
- Documentación extendida en `README.md` y `docs/`:
  - Instalación
  - Comparativa de modos y modelos
  - Token Hugging Face
  - Análisis con IA
- Guía de prompts descargable para análisis post-transcripción.
- CTA de apoyo vía PayPal.

---

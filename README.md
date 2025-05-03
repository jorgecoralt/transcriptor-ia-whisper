# 📝 Transcriptor IA Local

Convierte tus audios o videos en texto estructurado usando modelos de inteligencia artificial como **Whisper** y **WhisperX**, directamente desde tu computador y sin conexión a internet.

---

## 🚀 ¿Qué es esto?

Es una herramienta gratuita y local para transcribir grabaciones sin subirlas a la nube.  
Funciona completamente offline, protege tu privacidad y te permite convertir ideas habladas en documentos útiles.

---

## 🔧 ¿Qué hace esta herramienta?

✅ Transcribe audios o videos (.mp3, .mp4, .wav, .mkv, etc.)  
✅ Genera texto limpio y subtítulos `.srt`  
✅ Detecta silencios para estructurar el texto por bloques  
✅ Usa diarización de hablantes (modo PRO con WhisperX)  
✅ Funciona en CPU o GPU (si tienes una)  
✅ Te guía paso a paso y abre la web oficial para ayudarte

---

## 🛠 Cómo empezar

1. Descarga este repositorio
2. Ejecuta `instalar.bat` → Instala todo de forma automática
3. Coloca un archivo en `transcribir/media/`
4. Ejecuta `transcribir.bat` → Elige el modo y listo

> El sistema instalará todos los modos (básico, pausas, PRO) por defecto.

---

## 🔐 ¿Y el modo PRO?

El modo PRO te permite detectar **quién habla** en cada parte del audio.

Este modo necesita un token gratuito de Hugging Face.  
Puedes obtenerlo con esta guía:

📄 [Guía para activar el modo PRO](https://jorgecoral.com/token-huggingface-transcripcion)

Una vez tengas tu token, guárdalo en el archivo `configuracion.txt` así:
  HUGGINGFACE_TOKEN=tu_token_aqui


---

## 📁 Carpetas y 📄 Archivos del sistema 

- 📁 `media/` → aquí el usuario pone su archivo de audio o video
- 📁 `salidas/` → aquí se guardan todos los resultados con nombres por modo
- 📁 `utils/` → scripts en Python por modo + commons
- 📄 `instalar.bat` → ejecuta la instalación automática del sistema
- 📄 `transcribir.bat` → ejecuta la transcripción según el modo elegido
- 📄 `configuracion.txt` → archivo opcional donde se guarda el token del modo PRO
- 📄 `README.md` → esta guía
- 📄 `CHANGELOG.md` → registro de cambios del proyecto
- 📄 `CONTRIBUTING.md` → instrucciones para colaborar
- 📄 `LICENSE` → licencia del proyecto
- 📄 `.gitignore` → exclusiones de Git

---

## 🌐 Más guías y ejemplos

- [Guía principal del proyecto](https://jorgecoral.com/transcriptor-ia-whisper)
- [Guía para activar el modo PRO](https://jorgecoral.com/token-huggingface-transcripcion)
- [Guía de prompts para ChatGPT](https://jorgecoral.com/guia-prompts-transcripcion)

---

### ❤️ Apoya este proyecto

Si esta herramienta te ahorra tiempo, te ayuda a tomar mejores decisiones o te aporta claridad,  
puedes apoyarme para seguir creando herramientas como esta:

[Hey sí, ¡quiero apoyar esto!](https://paypal.me/jorgecoralt)

---

## 🧠 Autor

Desarrollado por [Jorge Coral](https://jorgecoral.com)  
**IA con alma. Herramientas con propósito.**

---

## 🎯 ¿Listo para usarlo?

Coloca tu archivo en `transcribir/media/`, ejecuta `transcribir.bat` y deja que la claridad haga su trabajo.

Cada vez que ejecutes una transcripción, se abrirá la web oficial con más recursos y ejemplos.


import os
import whisper
import torch
from datetime import timedelta

# --------------------------------------------------------
# Transcripción - Modo Básico
# --------------------------------------------------------
def transcribir_whisper(ruta_audio, modelo="small"):
    model = whisper.load_model(modelo)
    return model.transcribe(ruta_audio)

# --------------------------------------------------------
# Transcripción con segmentación por pausas
# --------------------------------------------------------
def transcribir_whisper_con_pausas(ruta_audio, modelo="small"):
    model = whisper.load_model(modelo)
    result = model.transcribe(ruta_audio, verbose=False, word_timestamps=False)

    bloques = []
    texto_actual = ""
    anterior_fin = 0.0

    for segmento in result["segments"]:
        inicio = segmento["start"]
        texto = segmento["text"].strip()

        if inicio - anterior_fin > 2.0 and texto_actual:
            bloques.append(texto_actual.strip())
            texto_actual = ""

        texto_actual += " " + texto
        anterior_fin = segmento["end"]

    if texto_actual:
        bloques.append(texto_actual.strip())

    result["bloques"] = bloques
    return result

# --------------------------------------------------------
# Transcripción con WhisperX + Diarización (Modo PRO)
# --------------------------------------------------------
def transcribir_whisperx(ruta_audio, token, modelo="large-v3"):
    from whisperx import load_model as load_whisperx_model, DiarizationPipeline, alignment

    device = "cuda" if torch.cuda.is_available() else "cpu"
    batch_size = 16
    compute_type = "float16" if device == "cuda" else "float32"

    model, metadata = load_whisperx_model(modelo, device, compute_type=compute_type, token=token)

    audio = whisper.load_audio(ruta_audio)
    audio = whisper.pad_or_trim(audio)
    result = model.transcribe(audio, batch_size=batch_size)

    diarize_model = DiarizationPipeline(use_auth_token=token)
    diarization = diarize_model(ruta_audio)

    if diarization is None:
        raise ValueError("No se pudo realizar la diarización. Verifica el token y el archivo de audio.")

    segments = alignment.assign_speakers(result["segments"], diarization, max_overlap=0.8)
    result["segments"] = segments
    return result

# --------------------------------------------------------
# Formatear tiempo estilo SRT
# --------------------------------------------------------
def format_srt_time(seconds):
    ms = int((seconds % 1) * 1000)
    h, rem = divmod(int(seconds), 3600)
    m, s = divmod(rem, 60)
    return f"{h:02}:{m:02}:{s:02},{ms:03}"

# --------------------------------------------------------
# Guardar resultados (texto limpio o subtítulos)
# --------------------------------------------------------
def guardar_transcripcion(resultado, ruta_salida, como="texto"):
    if "segments" not in resultado:
        print("[X] No se encontró contenido para guardar.")
        return

    with open(ruta_salida, "w", encoding="utf-8") as f:
        if como == "texto":
            if "bloques" in resultado:
                for bloque in resultado["bloques"]:
                    f.write(bloque + "\n\n")
            else:
                for segmento in resultado["segments"]:
                    f.write(segmento["text"].strip() + "\n")
        elif como == "srt":
            for i, segmento in enumerate(resultado["segments"], start=1):
                inicio = format_srt_time(segmento["start"])
                fin = format_srt_time(segmento["end"])
                f.write(f"{i}\n{inicio} --> {fin}\n{segmento['text'].strip()}\n\n")

# --------------------------------------------------------
# Leer token desde archivo de configuración
# --------------------------------------------------------
def cargar_token():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    ruta = os.path.join(base_dir, "configuracion.txt")

    if not os.path.exists(ruta):
        return None

    try:
        with open(ruta, "r", encoding="utf-8") as f:
            for linea in f:
                if "HUGGINGFACE_TOKEN=" in linea:
                    token = linea.split("=", 1)[1].strip()
                    print("[OK] Token detectado desde configuracion.txt")
                    return token
    except Exception:
        return None

    return None

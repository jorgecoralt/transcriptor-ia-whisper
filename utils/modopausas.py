import os
import sys

# ----------------------------------------------------------
# Agregar ffmpeg local al PATH (si existe en carpeta /ffmpeg)
# ----------------------------------------------------------
ffmpeg_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "ffmpeg"))
for root, dirs, files in os.walk(ffmpeg_dir):
    if "ffmpeg.exe" in files and "ffprobe.exe" in files:
        os.environ["PATH"] += os.pathsep + os.path.abspath(root)
        print(f"[+] ffmpeg agregado al PATH: {root}")
        break

# ----------------------------------------------------------
# Agregar carpeta raiz al path de importacion
# ----------------------------------------------------------
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from utils.commons import transcribir_whisper_con_pausas, guardar_transcripcion

# ----------------------------------------------------------
# Rutas base
# ----------------------------------------------------------
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
media_dir = os.path.join(base_dir, "media")
salidas_dir = os.path.join(base_dir, "salidas")
archivo_entrada = os.path.join(media_dir, "medio_preparado.wav")

if not os.path.isfile(archivo_entrada):
    print("[X] No se encontro el archivo medio_preparado.wav en /media.")
    sys.exit(1)

# ----------------------------------------------------------
# Transcripcion con segmentacion por pausas
# ----------------------------------------------------------
print(f"[+] Transcribiendo con pausas: {archivo_entrada}")
resultado = transcribir_whisper_con_pausas(archivo_entrada, modelo="small")

# ----------------------------------------------------------
# Guardar resultados
# ----------------------------------------------------------
nombre_base = "medio_preparado"
os.makedirs(salidas_dir, exist_ok=True)

ruta_txt = os.path.join(salidas_dir, f"{nombre_base}_pausas.txt")
ruta_srt = os.path.join(salidas_dir, f"{nombre_base}_pausas.srt")

guardar_transcripcion(resultado, ruta_txt, como="texto")
guardar_transcripcion(resultado, ruta_srt, como="srt")

# ----------------------------------------------------------
# Confirmacion final
# ----------------------------------------------------------
print()
print(f"[OK] Transcripcion segmentada completada.")
print(f"[OK] Texto con pausas guardado en: {ruta_txt}")
print(f"[OK] Subtitulos .srt guardados en: {ruta_srt}")

# -*- coding: utf-8 -*-
"""
Arma la base de fotos de la agenda: una carpeta por código, con UNA foto.

Recorre la ruta de campo buscando las subcarpetas «b.INFRA_SUPERFICIE»,
deduce a qué código pertenece cada una, elige una foto de fachada y la
copia a la ruta de destino dentro de una carpeta con el nombre del código.

    G:\\...\\1. ID_CAMPO\\...\\INFBR08-058\\b.INFRA_SUPERFICIE\\*.jpg
        -->  G:\\...\\26. SISTEMA DE GESTION DE VISITAS\\INFBR08-058\\INFBR08-058.jpg

Uso (en la computadora que tiene la unidad G:):

    python fotos-fachada.py

o indicando rutas distintas:

    python fotos-fachada.py --origen "G:\\...\\1. ID_CAMPO" ^
                            --destino "G:\\...\\26. SISTEMA DE GESTION DE VISITAS" ^
                            --padron "padron.csv"

Opciones:
    --prueba        no copia nada; solo informa qué haría
    --ancho 1200    reduce el ancho de la foto (necesita Pillow: pip install Pillow)
    --calidad 78    calidad del JPG al reducir

Al terminar deja en el destino:
    _resumen.csv    una fila por código: qué foto se eligió y por qué
    _sin_foto.csv   los códigos del padrón que se quedaron sin foto
"""

import argparse, csv, re, shutil, sys, unicodedata
from pathlib import Path

ORIGEN_POR_DEFECTO = r"G:\Unidades compartidas\39. SULLANA-ROGGIO\1. FASE_I-TOP_CAM\1. ID_CAMPO"
DESTINO_POR_DEFECTO = r"G:\Mi unidad\PHYTON GIULI\26. SISTEMA DE GESTION DE VISITAS"

IMAGENES = {".jpg", ".jpeg", ".png", ".heic", ".webp"}

# Palabras que delatan una foto de fachada, de la más clara a la más vaga.
PISTAS = [
    ("fachada", "dice «fachada»"),
    ("frontis", "dice «frontis»"),
    ("frontal", "dice «frontal»"),
    ("frente", "dice «frente»"),
    ("exterior", "dice «exterior»"),
    ("ingreso", "dice «ingreso»"),
    ("entrada", "dice «entrada»"),
    ("puerta", "dice «puerta»"),
    ("panoramica", "dice «panorámica»"),
    ("vista", "dice «vista»"),
]

# Fotos que casi nunca son la fachada: se dejan para el final.
DESCARTES = ["dni", "documento", "ficha", "croquis", "plano", "interior",
             "detalle", "medicion", "wincha", "firma", "acta", "cargo"]


def sin_tildes(t):
    t = unicodedata.normalize("NFD", str(t))
    return "".join(c for c in t if unicodedata.category(c) != "Mn").lower()


def es_carpeta_superficie(nombre):
    """«b.INFRA_SUPERFICIE», «B. INFRA SUPERFICIE», «b_infra-superficie»…"""
    n = re.sub(r"[^a-z]", "", sin_tildes(nombre))
    return n.startswith("binfrasuperficie") or n == "infrasuperficie"


def leer_padron(ruta):
    """Códigos válidos, para no inventar carpetas con nombres raros."""
    if not ruta or not Path(ruta).exists():
        return None
    codigos = set()
    with open(ruta, encoding="utf-8-sig", newline="") as fh:
        for fila in csv.DictReader(fh, delimiter=";"):
            c = (fila.get("codigo") or "").strip().upper()
            if c:
                for parte in re.split(r"[\s,/]+", c):
                    if parte:
                        codigos.add(parte)
    return codigos or None


PATRON_CODIGO = re.compile(r"\b((?:INF)?[A-Z]{1,4}\d{1,3}-\d{1,4})\b")


def codigo_de(carpeta, validos):
    """Sube por las carpetas padre hasta encontrar un código."""
    for padre in carpeta.parents:
        m = PATRON_CODIGO.search(padre.name.upper())
        if m:
            c = m.group(1)
            if validos is None or c in validos:
                return c
    return None


def elegir_foto(carpeta):
    """Devuelve (archivo, motivo). Sin pistas, la primera por nombre."""
    fotos = sorted((f for f in carpeta.iterdir()
                    if f.is_file() and f.suffix.lower() in IMAGENES),
                   key=lambda f: f.name.lower())
    if not fotos:
        return None, "la carpeta no tiene fotos"

    def descartable(f):
        n = sin_tildes(f.name)
        return any(d in n for d in DESCARTES)

    candidatas = [f for f in fotos if not descartable(f)] or fotos

    for pista, motivo in PISTAS:
        for f in candidatas:
            if pista in sin_tildes(f.name):
                return f, motivo
    return candidatas[0], "sin pistas en el nombre: la primera"


def reducir(origen, destino, ancho, calidad):
    try:
        from PIL import Image, ImageOps
    except ImportError:
        return False
    with Image.open(origen) as im:
        im = ImageOps.exif_transpose(im).convert("RGB")
        if im.width > ancho:
            im = im.resize((ancho, round(im.height * ancho / im.width)), Image.LANCZOS)
        im.save(destino, "JPEG", quality=calidad, optimize=True)
    return True


def main():
    ap = argparse.ArgumentParser(description="Arma la base de fotos por código.")
    ap.add_argument("--origen", default=ORIGEN_POR_DEFECTO)
    ap.add_argument("--destino", default=DESTINO_POR_DEFECTO)
    ap.add_argument("--padron", default="padron.csv")
    ap.add_argument("--ancho", type=int, default=0)
    ap.add_argument("--calidad", type=int, default=78)
    ap.add_argument("--prueba", action="store_true")
    a = ap.parse_args()

    origen, destino = Path(a.origen), Path(a.destino)
    if not origen.exists():
        sys.exit("No encuentro la ruta de origen:\n  %s" % origen)

    validos = leer_padron(a.padron)
    print("Origen : %s" % origen)
    print("Destino: %s" % destino)
    print("Padrón : %s" % ("%d códigos de %s" % (len(validos), a.padron) if validos
                           else "sin padrón: se acepta cualquier código que parezca uno"))
    if a.prueba:
        print("MODO PRUEBA: no se copia nada.\n")

    filas, vistos = [], {}
    for carpeta in origen.rglob("*"):
        if not carpeta.is_dir() or not es_carpeta_superficie(carpeta.name):
            continue
        codigo = codigo_de(carpeta, validos)
        if not codigo:
            filas.append({"codigo": "", "carpeta": str(carpeta), "foto": "",
                          "motivo": "no se pudo deducir el código", "fotos_en_la_carpeta": ""})
            continue
        foto, motivo = elegir_foto(carpeta)
        cuantas = sum(1 for f in carpeta.iterdir()
                      if f.is_file() and f.suffix.lower() in IMAGENES)
        if not foto:
            filas.append({"codigo": codigo, "carpeta": str(carpeta), "foto": "",
                          "motivo": motivo, "fotos_en_la_carpeta": 0})
            continue
        if codigo in vistos:
            filas.append({"codigo": codigo, "carpeta": str(carpeta), "foto": foto.name,
                          "motivo": "ya se había tomado una foto de %s" % vistos[codigo],
                          "fotos_en_la_carpeta": cuantas})
            continue
        vistos[codigo] = carpeta

        sufijo = ".jpg" if a.ancho else foto.suffix.lower()
        salida = destino / codigo / (codigo + sufijo)
        if not a.prueba:
            salida.parent.mkdir(parents=True, exist_ok=True)
            if not (a.ancho and reducir(foto, salida, a.ancho, a.calidad)):
                shutil.copy2(foto, destino / codigo / (codigo + foto.suffix.lower()))
                salida = destino / codigo / (codigo + foto.suffix.lower())
        filas.append({"codigo": codigo, "carpeta": str(carpeta), "foto": foto.name,
                      "motivo": motivo, "fotos_en_la_carpeta": cuantas})
        print("  %-14s %-46s (%s)" % (codigo, foto.name[:46], motivo))

    if not a.prueba:
        destino.mkdir(parents=True, exist_ok=True)
        with open(destino / "_resumen.csv", "w", encoding="utf-8-sig", newline="") as fh:
            w = csv.DictWriter(fh, delimiter=";",
                               fieldnames=["codigo", "foto", "motivo", "fotos_en_la_carpeta", "carpeta"])
            w.writeheader()
            for f in filas:
                w.writerow(f)
        if validos:
            faltan = sorted(validos - set(vistos))
            with open(destino / "_sin_foto.csv", "w", encoding="utf-8-sig", newline="") as fh:
                fh.write("codigo\n")
                for c in faltan:
                    fh.write(c + "\n")

    copiadas = [f for f in filas if f["codigo"] in vistos and f["foto"]
                and not f["motivo"].startswith("ya se hab")]
    con_pista = sum(1 for f in copiadas if "sin pistas" not in f["motivo"])
    print("\nCarpetas «b.INFRA_SUPERFICIE» encontradas: %d" % len(filas))
    print("Códigos con foto copiada               : %d" % len(vistos))
    print("  de esos, elegida por el nombre       : %d" % con_pista)
    print("  de esos, la primera por no haber pista: %d" % (len(vistos) - con_pista))
    if validos:
        print("Códigos del padrón sin ninguna foto    : %d" % len(validos - set(vistos)))
    if not a.prueba:
        print("\nRevisa %s antes de subir nada." % (destino / "_resumen.csv"))


if __name__ == "__main__":
    main()

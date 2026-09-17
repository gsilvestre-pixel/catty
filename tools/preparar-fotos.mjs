/* =====================================================================
   Prepara las fotos de las entidades para subirlas a la agenda.

   Recorre una ruta con carpetas nombradas por CÓDIGO, elige UNA foto de
   cada una, la reduce de peso y la deja en una carpeta de salida con el
   nombre CODIGO.jpg. Después basta con arrastrar esa carpeta al panel de
   Supabase: la agenda las encuentra sola por el código.

   Uso:
     node tools/preparar-fotos.mjs "D:\\ruta\\con\\carpetas" [salida]

   Opciones:
     --elegir=primera|ultima|mayor   cuál foto tomar de cada carpeta
                                     (por defecto: primera, por nombre)
     --ancho=1400                    ancho máximo en píxeles
     --calidad=78                    calidad del JPG (1-100)

   La reducción de peso necesita la librería «sharp»:
     npm install sharp
   Si no está instalada, el programa copia la foto original tal cual y
   lo avisa al final.
   ===================================================================== */

import { readdir, mkdir, copyFile, stat, writeFile } from "node:fs/promises";
import { join, extname, basename } from "node:path";

const IMAGENES = [".jpg", ".jpeg", ".png", ".webp"];
const args = process.argv.slice(2);
const opcion = (n, d) => { const a = args.find((x) => x.startsWith("--" + n + "=")); return a ? a.split("=")[1] : d; };
const rutas = args.filter((a) => !a.startsWith("--"));
const ORIGEN = rutas[0];
const SALIDA = rutas[1] || "fotos-para-subir";
const ELEGIR = opcion("elegir", "primera");
const ANCHO = Number(opcion("ancho", 1400));
const CALIDAD = Number(opcion("calidad", 78));

if (!ORIGEN) {
  console.error('Falta la ruta. Ejemplo:\n  node tools/preparar-fotos.mjs "D:\\\\Inspecciones\\\\Fotos"');
  process.exit(1);
}

let sharp = null;
try { sharp = (await import("sharp")).default; }
catch { /* sin sharp se copia el original */ }

const kb = (n) => Math.round(n / 1024);
const esImagen = (f) => IMAGENES.includes(extname(f).toLowerCase());

async function elegirFoto(carpeta) {
  const archivos = (await readdir(carpeta, { withFileTypes: true }))
    .filter((d) => d.isFile() && esImagen(d.name))
    .map((d) => d.name)
    .sort((a, b) => a.localeCompare(b, "es", { numeric: true }));
  if (!archivos.length) return null;
  if (ELEGIR === "ultima") return archivos[archivos.length - 1];
  if (ELEGIR === "mayor") {
    let mejor = archivos[0], mayor = 0;
    for (const f of archivos) {
      const { size } = await stat(join(carpeta, f));
      if (size > mayor) { mayor = size; mejor = f; }
    }
    return mejor;
  }
  return archivos[0];
}

const carpetas = (await readdir(ORIGEN, { withFileTypes: true })).filter((d) => d.isDirectory());
await mkdir(SALIDA, { recursive: true });

const conFoto = [], sinFoto = [];
let pesoTotal = 0;

for (const c of carpetas) {
  const codigo = c.name.trim();
  const foto = await elegirFoto(join(ORIGEN, c.name));
  if (!foto) { sinFoto.push(codigo); continue; }
  const origen = join(ORIGEN, c.name, foto);
  const destino = join(SALIDA, codigo + (sharp ? ".jpg" : extname(foto).toLowerCase()));
  if (sharp) {
    await sharp(origen).rotate().resize({ width: ANCHO, withoutEnlargement: true })
      .jpeg({ quality: CALIDAD, mozjpeg: true }).toFile(destino);
  } else {
    await copyFile(origen, destino);
  }
  const { size } = await stat(destino);
  pesoTotal += size;
  conFoto.push({ codigo, origen: basename(foto), kb: kb(size) });
}

/* Deja constancia de qué se tomó de cada carpeta */
await writeFile(join(SALIDA, "_resumen.csv"),
  "codigo;archivo_original;kb\n" + conFoto.map((f) => f.codigo + ";" + f.origen + ";" + f.kb).join("\n") + "\n",
  "utf8");

console.log("\nCarpetas revisadas: " + carpetas.length);
console.log("Con foto:  " + conFoto.length);
console.log("Sin foto:  " + sinFoto.length + (sinFoto.length ? "  →  " + sinFoto.slice(0, 12).join(", ") + (sinFoto.length > 12 ? "…" : "") : ""));
console.log("Peso total: " + (pesoTotal / 1048576).toFixed(1) + " MB" + (pesoTotal > 1073741824 ? "   ⚠ supera el 1 GB del plan gratuito" : ""));
console.log("Carpeta lista para subir: " + SALIDA);
if (!sharp) console.log("\nNota: sin la librería «sharp» las fotos se copiaron sin reducir.\n      Para reducirlas: npm install sharp   y vuelve a ejecutar.");

#!/usr/bin/env node
/* Extrae el padrón de entidades del cuadro de control en Excel.
 *
 *   node tools/padron-desde-excel.mjs <archivo.xlsx> [hoja] > datos/padron.csv
 *
 * Busca la fila de encabezados (la que contiene "CODIGO" y un nombre de
 * titular), toma código, titular y clase de obra, y deja una fila por
 * entidad. El código puede faltar: no toda entidad lo tiene.
 */
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

const [archivo, hoja] = process.argv.slice(2);
if (!archivo) { console.error("Uso: node tools/padron-desde-excel.mjs <archivo.xlsx> [hoja]"); process.exit(1); }

/* Se apoya en Python + openpyxl, que es lo que hay disponible sin instalar
   dependencias de npm. */
const py = `
import openpyxl, re, json, sys
wb = openpyxl.load_workbook(sys.argv[1], data_only=True, read_only=True)
ws = wb[sys.argv[2]] if len(sys.argv) > 2 and sys.argv[2] else wb[wb.sheetnames[0]]
filas = [list(r) for r in ws.iter_rows(values_only=True)]
lim = lambda v: re.sub(r"\\s+", " ", str(v)).strip() if v is not None else ""
norm = lambda v: lim(v).lower()
cab = -1
for i, f in enumerate(filas):
    t = [norm(v) for v in f]
    if any(c.startswith("codigo") or c.startswith("código") for c in t) and any("titular" in c or c.startswith("entidad") or c.startswith("nombre") for c in t):
        cab = i; break
if cab < 0: print(json.dumps({"error": "no se encontró la fila de encabezados"})); sys.exit()
t = [norm(v) for v in filas[cab]]
jc = next((j for j, c in enumerate(t) if c.startswith("codigo") or c.startswith("código")), -1)
jn = next((j for j, c in enumerate(t) if "titular" in c or c.startswith("entidad") or c.startswith("nombre")), -1)
jt = next((j for j, c in enumerate(t) if "infraestructura" in c and "tipo" in c), -1)
def clase(x):
    x = lim(x).upper()
    e, u = "EDIFICACI" in x, "SUPERFICIE" in x
    return "ambas" if e and u else "edificaciones" if e else "superficies" if u else ""
out, vistos = [], set()
for f in filas[cab+1:]:
    n = lim(f[jn]) if jn >= 0 and jn < len(f) else ""
    c = lim(f[jc]) if jc >= 0 and jc < len(f) else ""
    if c in ("-", "--") or c.lower() in ("na", "n/a"): c = ""
    if not n: continue
    if n.upper() == "VISITAR NUEVAMENTE":
        if not c: continue
        n = "VISITAR NUEVAMENTE · " + c   # titular sin identificar: se distingue por su código
    k = n.lower()
    if k in vistos: continue
    vistos.add(k)
    out.append({"codigo": c, "nombre": n, "tipo": clase(f[jt]) if 0 <= jt < len(f) else ""})
print(json.dumps({"fila_encabezado": cab + 1, "filas": out}, ensure_ascii=False))
`;
const salida = JSON.parse(execFileSync("python3", ["-c", py, archivo, hoja || ""], { encoding: "utf-8", maxBuffer: 64 * 1024 * 1024 }));
if (salida.error) { console.error(salida.error); process.exit(1); }

const campo = (v) => (/[";\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v);
process.stdout.write("codigo;entidad;tipo\n");
for (const f of salida.filas) process.stdout.write(campo(f.codigo) + ";" + campo(f.nombre) + ";" + campo(f.tipo) + "\n");
const cuenta = (t) => salida.filas.filter((f) => f.tipo === t).length;
console.error(`Encabezados en la fila ${salida.fila_encabezado} · ${salida.filas.length} entidades`
  + ` · ${salida.filas.filter((f) => !f.codigo).length} sin código`
  + ` · ${cuenta("edificaciones")} edificaciones, ${cuenta("superficies")} superficies, ${cuenta("ambas")} ambas, ${cuenta("")} sin clasificar`);

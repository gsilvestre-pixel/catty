#!/usr/bin/env node
/* Extrae el padrón de entidades del cuadro de control en Excel.
 *
 *   node tools/padron-desde-excel.mjs <archivo.xlsx> [hoja] > datos/padron.csv
 *
 * Busca la fila de encabezados y arma el nombre de cada entidad con las
 * dos formas en que el equipo la conoce: el negocio primero —que es como
 * lo nombran en la calle— y la razón social después.
 *
 *     HOTEL LEO'S - JALS SERVICIOS GENERALES J.L.S E.I.R.L.
 *
 * Reglas:
 *   · si falta uno de los dos, queda el que haya;
 *   · si uno ya contiene al otro, no se repite: gana el más completo;
 *   · si juntos pasan de 80 caracteres, queda solo el negocio (o el
 *     titular, si no hubiera negocio): en el celular un nombre de cuatro
 *     líneas no se lee.
 *
 * El código puede faltar: no toda entidad lo tiene.
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
jn = next((j for j, c in enumerate(t) if "titular" in c), -1)
if jn < 0: jn = next((j for j, c in enumerate(t) if c.startswith("entidad") or c.startswith("nombre")), -1)
jg = next((j for j, c in enumerate(t) if "negocio" in c or "nombrecomercial" in c or "comercial" in c), -1)
LARGO_MAX = 80
MARCADORES = {"", "-", "--", "N/A", "NA", "NO CORRESPONDE", "POR CONFIRMAR", "PENDIENTE", "VISITAR NUEVAMENTE"}
def sirve(x): return lim(x).upper() not in MARCADORES
def juntar(titular, negocio):
    tt, nn = lim(titular), lim(negocio)
    t, n = sirve(tt), sirve(nn)
    if not t and not n: return ""
    if not n: return tt
    if not t: return nn
    if tt.upper() in nn.upper(): return nn      # uno ya contiene al otro
    if nn.upper() in tt.upper(): return tt
    junto = nn + " - " + tt
    return junto if len(junto) <= LARGO_MAX else nn
jt = next((j for j, c in enumerate(t) if "infraestructura" in c and "tipo" in c), -1)
def clase(x):
    x = lim(x).upper()
    e, u = "EDIFICACI" in x, "SUPERFICIE" in x
    return "ambas" if e and u else "edificaciones" if e else "superficies" if u else ""
out, vistos = [], set()
for f in filas[cab+1:]:
    titular = f[jn] if 0 <= jn < len(f) else ""
    negocio = f[jg] if 0 <= jg < len(f) else ""
    n = juntar(titular, negocio)
    c = lim(f[jc]) if jc >= 0 and jc < len(f) else ""
    if c in ("-", "--") or c.lower() in ("na", "n/a"): c = ""
    if not n:
        # sin ningún nombre útil: se distingue por su código, si lo tiene
        if not c: continue
        n = "VISITAR NUEVAMENTE - " + c
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
  + ` · ${cuenta("edificaciones")} edificaciones, ${cuenta("superficies")} superficies, ${cuenta("ambas")} ambas, ${cuenta("")} sin clasificar`
  + ` · ${salida.filas.filter((f) => f.nombre.includes(" - ")).length} con negocio y titular`);

/* Genera dist/artifact.html: la misma aplicación sin el envoltorio del
   documento, que es lo que espera el publicador de Artifacts (la página
   se inserta dentro de <!doctype html><head>…</head><body>).            */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";

const raiz = resolve(new URL("..", import.meta.url).pathname);
const src = readFileSync(resolve(raiz, "index.html"), "utf8");

const head = src.match(/<head>([\s\S]*?)<\/head>/)[1]
  .replace(/^\s*<meta charset[^>]*>\s*$/m, "")
  .replace(/^\s*<meta name="viewport"[^>]*>\s*$/m, "")
  /* lo propio del sitio publicado: no aplica dentro del visor de Artifacts */
  .replace(/^\s*<(meta name="(theme-color|robots|apple-[^"]*)"|link rel="(manifest|apple-touch-icon|icon)")[^>]*>\s*$/gm, "")
  .replace(/^\s*<script src="config\.js"><\/script>\s*$/m, "")
  .trim();
const body = src.match(/<body>([\s\S]*?)<\/body>/)[1].trim();

const salida = resolve(raiz, "dist/artifact.html");
mkdirSync(dirname(salida), { recursive: true });
writeFileSync(salida, head + "\n\n" + body + "\n");
console.log("dist/artifact.html generado (" + (head.length + body.length) + " bytes)");

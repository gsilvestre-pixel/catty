# Padrón de entidades

`padron.csv` es el padrón que alimenta las sugerencias del campo **Entidad**
en la agenda. Se generó desde el cuadro de control en Excel:

```
node tools/padron-desde-excel.mjs "CONTROL DE INFORMACIÓN - CARTAS INFRAESTRUCTURA.xlsx" CONTROL > datos/padron.csv
```

La herramienta busca sola la fila de encabezados, toma las columnas
**CODIGO**, **NOMBRE DEL TITULAR DE INFRAESTRUCTURA** y **TIPO DE
INFRAESTRUCTURA**, descarta las demás y deja una fila por entidad.

## Cómo cargarlo

En la agenda, con la sesión de administrador abierta: botón **Administrar →
Archivo del padrón → Revisar cambios → Aplicar**. Antes de aplicar muestra
qué entra, qué cambia y qué sale.

## Reglas del padrón

- **El nombre es obligatorio**: es lo que se sugiere al escribir.
- **El código es opcional.** En el padrón de trabajo hay entidades sin
  código (empresas de servicios, entidades del Estado, titulares recién
  agregados). Un guion `-` en la columna cuenta como "sin código".
- **El código, cuando existe, no se repite**: es lo que enlaza con la
  carpeta de fotos.
- **El tipo es opcional** y admite tres valores: `edificaciones`,
  `superficies` y `ambas`. El cuadro de control lo escribe de varias formas
  ("INFRAESTRUCTURA EDIFICACIONES", "INFRAESTRUCTURA DE SUPERFICIE", las dos
  en la misma celda); la herramienta lo normaliza. Lo que dice
  "NO CORRESPONDE", "PENDIENTE" o "POR CONFIRMAR" queda sin clasificar.
- Al volver a cargar el archivo, cada fila se empareja primero por código y
  luego por nombre. Así, corregir el nombre de una entidad con código se
  registra como un cambio y no como una baja seguida de un alta.

## Para qué sirve el tipo

Al elegir la entidad en el formulario, el tipo de infraestructura se propone
solo. Es una propuesta: en cuanto alguien lo cambia a mano deja de tocarse,
y al abrir una visita ya guardada nunca se autocompleta — lo guardado manda.

# Padrón de entidades

`padron.csv` es el padrón que alimenta las sugerencias del campo **Entidad**
en la agenda. Se generó desde el cuadro de control en Excel:

```
node tools/padron-desde-excel.mjs "CONTROL DE INFORMACIÓN - CARTAS INFRAESTRUCTURA.xlsx" CONTROL > datos/padron.csv
```

La herramienta busca sola la fila de encabezados, toma las columnas
**CODIGO** y **NOMBRE DEL TITULAR DE INFRAESTRUCTURA**, descarta las demás
y deja una fila por entidad.

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
- Al volver a cargar el archivo, cada fila se empareja primero por código y
  luego por nombre. Así, corregir el nombre de una entidad con código se
  registra como un cambio y no como una baja seguida de un alta.

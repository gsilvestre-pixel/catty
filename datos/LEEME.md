# Padrón de entidades

El padrón alimenta las sugerencias del campo **Entidad** en la agenda.

## Cómo cargarlo

Con la sesión de administrador abierta: **Administrar → Archivo del padrón →
Revisar cambios → Aplicar**. Antes de aplicar muestra qué entra, qué cambia
y qué sale.

Acepta el **.xlsx tal cual**: la agenda lo lee sin librerías, descomprimiendo
el ZIP con el propio navegador. También acepta CSV, por si hiciera falta.

Busca sola la fila de encabezados y toma las columnas **CODIGO**, **NOMBRE
DEL TITULAR DE INFRAESTRUCTURA**, **NOMBRE DE NEGOCIO** y **TIPO DE
INFRAESTRUCTURA**; descarta las demás.

## El nombre de cada entidad

Lleva las dos formas en que el equipo la conoce, el negocio primero:

    TIENDAS MASS - COMPAÑIA HARD DISCOUNT S.A.C.

Si falta uno de los dos queda el que haya; si uno ya contiene al otro no se
repite; y si juntos pasan de 80 caracteres queda solo el negocio, porque un
nombre de cuatro líneas no se lee en el celular.

## El mismo padrón en texto

`padron.csv` es el resultado en CSV, útil para revisarlo fuera de la agenda.
Se genera con:

```
node tools/padron-desde-excel.mjs "CONTROL DE INFORMACIÓN - CARTAS INFRAESTRUCTURA.xlsx" CONTROL > datos/padron.csv
```

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

## Cómo se busca una entidad

El campo Entidad **no** usa la lista desplegable del navegador: esa solo
compara contra el comienzo del nombre y en iPhone casi no aparece. La agenda
arma su propio buscador, que encuentra por partes.

Escribir `salon belleza` encuentra
`MIRELLA DEL ROCIO GIRON CRUZ SALON DE BELLEZA UNISEX...`, porque todas las
palabras escritas deben aparecer en algún lugar del nombre, en cualquier
orden, sin distinguir tildes ni mayúsculas. También busca por código.

Esto importa porque el equipo conoce a los titulares por su nombre de campo
y el padrón los guarda por su razón social.

## El código del predio

El formulario tiene su propio campo **Código del predio**, después de la
entidad. Al elegir una entidad del padrón se llena solo, pero se puede
escribir a mano: hay 55 entidades sin código en el cuadro de control, y
esas se completan aquí. En cuanto alguien lo escribe, deja de tocarse
aunque cambie la entidad.

El código queda escrito en la visita, no deducido cada vez, de modo que si
mañana el padrón cambia o la entidad se renombra, lo inspeccionado ese día
sigue siendo lo que fue. Las visitas programadas antes de la migración 06
lo deducen del padrón por el nombre de la entidad, y al volver a guardarlas
queda escrito.

Se ve bajo el nombre en la agenda y en Resultados, en el rótulo del
calendario, en el formulario y en la columna Código del Excel. También se
puede buscar por él.

## Para qué sirve el tipo

Al elegir la entidad en el formulario, el tipo de infraestructura se propone
solo. Es una propuesta: en cuanto alguien lo cambia a mano deja de tocarse,
y al abrir una visita ya guardada nunca se autocompleta — lo guardado manda.

# Cartas e inspecciones a entidades

Panel de seguimiento de las actividades pendientes sobre un padrón de entidades,
con un calendario de **setiembre y octubre**.

El ciclo de cada entidad tiene tres actividades, y cada una registra a **una o
más personas encargadas**:

1. **Notificar la carta.**
2. **Primera inspección**, que además define si la entidad **requiere una
   segunda inspección**.
3. **Segunda inspección**, cuando la primera la haya requerido.

Cada inspección cierra con resultado **positivo** o **negativo**.

La aplicación es un solo archivo (`index.html`) sin proceso de compilación.

## Qué muestra

| Sección | Contenido |
|---|---|
| **Indicadores** | Entidades del padrón, cartas por notificar, inspecciones en agenda, inspecciones realizadas (primeras y segundas, con % de entidades concluidas) y resultados positivos. |
| **Pendientes** | Inspecciones vencidas sin registrar, cartas por notificar, primeras inspecciones por programar, entidades donde falta definir si requieren segunda, segundas inspecciones por programar, próximas inspecciones y realizadas sin resultado. Es la vista por defecto. |
| **Calendario** | Setiembre y octubre lado a lado. Cada día indica si es 1.ª o 2.ª inspección, la entidad y el color del estado; al pasar el cursor se ven los encargados y al hacer clic se abre el día para registrar o programar. |
| **Responsables** | Carga por persona —cartas notificadas, primeras y segundas inspecciones, actividades en agenda y vencidas— y el listado de actividades que todavía no tienen encargado. |
| **Padrón** | Tabla completa: notificación, 1.ª inspección, si requiere 2.ª, 2.ª inspección y estado, con los encargados de cada etapa. Incluye búsqueda (también por persona), filtros, importación y exportación a CSV. |

El periodo del calendario se cambia en `CONFIG.meses` (por ejemplo
`["2026-09", "2026-10", "2026-11"]`).

## Origen de datos

`index.html` elige automáticamente, en este orden:

1. **PostgreSQL (Supabase)** — si `CONFIG.supabase` tiene `url` y `anonKey`.
   Es el modo para el enlace público con base de datos SQL en línea.
2. **Base de datos del panel publicado** — si la página corre como Artifact de
   Claude. No requiere configuración; el permiso de escritura lo da el nivel de
   compartición del panel («puede editar»).
3. **Navegador local** — respaldo sin servidor; los datos no se comparten.

Mientras no haya padrón cargado, la página muestra un conjunto de **datos de
ejemplo** claramente rotulado, que desaparece al importar el padrón real.

## Despliegue público con SQL (Supabase + GitHub Pages)

1. Crear un proyecto en [supabase.com](https://supabase.com) (plan gratuito).
2. En **SQL Editor**, ejecutar `db/schema.sql`.
3. Registrar los correos autorizados:

   ```sql
   insert into public.editores (email, nombre) values
     ('persona1@dominio.pe', 'Nombre 1'),
     ('persona2@dominio.pe', 'Nombre 2'),
     ('persona3@dominio.pe', 'Nombre 3')
   on conflict (email) do nothing;
   ```

4. En **Project Settings → API**, copiar `Project URL` y la clave `anon` y
   pegarlas en `CONFIG.supabase` dentro de `index.html`. La clave `anon` es
   pública por diseño: quién puede escribir lo decide el RLS del paso 2, no la
   clave.
5. En **Authentication → URL Configuration**, agregar la URL del sitio
   publicado como *Site URL* y como *Redirect URL*.
6. En GitHub: **Settings → Pages → Source: Deploy from a branch**, rama de este
   repositorio, carpeta `/ (root)`.

Resultado: el enlace queda abierto para lectura y quien esté en `editores`
entra con **Activar edición**, recibe un enlace de acceso por correo y desde ahí
puede modificar. Los tres editores ven los cambios del otro en vivo.

## Publicar como Artifact de Claude

```bash
node tools/build-artifact.mjs   # genera dist/artifact.html
```

Se publica `dist/artifact.html`. El panel usa su propia base de datos en línea y
la edición queda habilitada para quienes tengan el panel compartido con permiso
de edición. Los artefactos con base de datos son internos a la organización: no
admiten enlace público abierto.

## Importar el padrón

**Padrón → Importar padrón**, pegando desde Excel o en CSV. La primera fila es
el encabezado; se reconocen (en cualquier orden, y se ignora lo demás):

`entidad` · `ubicación` · `responsable` (o `responsables`) · `carta` ·
`fecha carta` · `n° carta` · `fecha visita` · `observación`

Cuando una actividad tiene varias personas, sepáralas con `/`, `,` o `;`
(por ejemplo `J. Quispe / L. Ramos`). Los encargados importados quedan como
responsables de la notificación de la carta y se proponen por defecto al
programar la inspección.

Fechas admitidas: `2026-09-14`, `14/09/2026` o `14-09-26`.

## Estructura

```
index.html                 aplicación completa (HTML + CSS + JS)
db/schema.sql              tablas, restricciones, vista de carga y RLS para PostgreSQL
tools/build-artifact.mjs   genera la variante publicable como Artifact
```

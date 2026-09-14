# Cartas e inspecciones a entidades

Panel de seguimiento de las actividades pendientes sobre un padrón de entidades:
cartas por cursar, visitas programadas, visitas realizadas y su resultado
(positivo / negativo), con un calendario de **setiembre y octubre**.

La aplicación es un solo archivo (`index.html`) sin proceso de compilación.

## Qué muestra

| Sección | Contenido |
|---|---|
| **Indicadores** | Entidades del padrón, cartas por cursar, visitas programadas, visitas realizadas (con % de avance) y resultados positivos. |
| **Pendientes** | Visitas vencidas sin registrar, cartas por cursar, visitas por programar, próximas visitas y visitas realizadas sin resultado. Es la vista por defecto. |
| **Calendario** | Setiembre y octubre lado a lado. Cada día muestra la entidad y el color del estado; al hacer clic se abren las visitas del día y se puede programar una nueva. |
| **Padrón** | Tabla completa con búsqueda y filtros por estado y resultado, importación del padrón y exportación a CSV. |

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

`entidad` · `ubicación` · `responsable` · `carta` · `fecha carta` ·
`n° carta` · `fecha visita` · `observación`

Fechas admitidas: `2026-09-14`, `14/09/2026` o `14-09-26`.

## Estructura

```
index.html                 aplicación completa (HTML + CSS + JS)
db/schema.sql              tablas, restricciones y RLS para PostgreSQL
tools/build-artifact.mjs   genera la variante publicable como Artifact
```

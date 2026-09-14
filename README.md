# Agenda de inspecciones

Calendario para programar las visitas de inspección, con vistas de **mes,
semana y día**. Cada visita registra únicamente:

**entidad · fecha · hora · personas que harán la inspección · observaciones**

Y se puede **filtrar por persona** desde la barra superior, en cualquiera de las
tres vistas.

La aplicación es un solo archivo (`index.html`) sin proceso de compilación.

## Uso

| Acción | Cómo |
|---|---|
| Programar una visita | **+ Visita**, o clic en un día (vista mes) o en una franja horaria (vistas semana y día). |
| Ver o editar una visita | Clic sobre ella. En modo lectura se abre solo para consultar. |
| Cambiar de vista | Botones **Mes / Semana / Día**, o las teclas `m`, `s`, `d`. |
| Navegar | **‹ ›** avanza mes, semana o día según la vista; **Hoy** vuelve a la fecha actual. |
| Ir al detalle de un día | Clic en el número del día. |
| Filtrar por persona | Selector **Todas las personas** en la barra superior. |

Solo quien tenga permiso de edición ve los botones de creación: los demás
consultan la agenda en modo lectura.

## Origen de datos

`index.html` elige automáticamente, en este orden:

1. **PostgreSQL (Supabase)** — si `CONFIG.supabase` tiene `url` y `anonKey`.
   Es el modo para el enlace público con base de datos SQL en línea.
2. **Base de datos de la agenda publicada** — si la página corre como Artifact
   de Claude. No requiere configuración; el permiso de escritura lo da el nivel
   de compartición («puede editar»).
3. **Navegador local** — respaldo sin servidor; los datos no se comparten.

Mientras no haya visitas, se muestran unas de ejemplo claramente rotuladas, que
desaparecen al crear la primera real.

## Despliegue público con SQL (Supabase + GitHub Pages)

1. Crear un proyecto en [supabase.com](https://supabase.com) (plan gratuito).
2. En **SQL Editor**, ejecutar `db/schema.sql`.
3. Registrar los correos autorizados en `public.editores` (ver el comentario
   del propio archivo).
4. En **Project Settings → API**, copiar `Project URL` y la clave `anon` y
   pegarlas en `CONFIG.supabase` dentro de `index.html`. La clave `anon` es
   pública por diseño: quién puede escribir lo decide el RLS del paso 2.
5. En **Authentication → URL Configuration**, agregar la URL del sitio
   publicado como *Site URL* y como *Redirect URL*.
6. En GitHub: **Settings → Pages → Source: Deploy from a branch**, rama de este
   repositorio, carpeta `/ (root)`.

Los editores entran con **Activar edición**, reciben un enlace de acceso por
correo y desde ahí pueden programar. Los cambios se ven en vivo en los demás
navegadores abiertos.

## Publicar como Artifact de Claude

```bash
node tools/build-artifact.mjs   # genera dist/artifact.html
```

Se publica `dist/artifact.html`. Los artefactos con base de datos son internos
a la organización: no admiten enlace público abierto.

## Estructura

```
index.html                 aplicación completa (HTML + CSS + JS)
db/schema.sql              tabla, índices y RLS para PostgreSQL
tools/build-artifact.mjs   genera la variante publicable como Artifact
```

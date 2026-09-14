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

## Despliegue público con SQL

Ver **[DESPLIEGUE.md](DESPLIEGUE.md)**: base de datos y editores en Supabase,
credenciales en `config.js` y dirección pública en GitHub Pages o Cloudflare
Pages. Resultado: enlace abierto para todo el equipo y edición reservada a los
correos registrados en la tabla `editores`.

## En el celular

La aplicación es instalable: *Agregar a pantalla principal* (Android) o *Añadir
a pantalla de inicio* (iPhone) la deja con ícono propio y a pantalla completa.
En pantallas angostas abre en la vista de día.

## Publicar como Artifact de Claude

```bash
node tools/build-artifact.mjs   # genera dist/artifact.html
```

Se publica `dist/artifact.html`. Los artefactos con base de datos son internos
a la organización: no admiten enlace público abierto.

## Estructura

```
index.html                 aplicación completa (HTML + CSS + JS)
config.js                  credenciales de Supabase (las únicas dos líneas a editar)
manifest.webmanifest       datos de instalación en el celular
icons/                     íconos de la aplicación
db/schema.sql              tabla, índices y RLS para PostgreSQL
tools/build-artifact.mjs   genera la variante publicable como Artifact
DESPLIEGUE.md              pasos para el enlace público
```

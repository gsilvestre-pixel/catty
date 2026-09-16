# Publicar la agenda con enlace público

Objetivo: **un enlace que todo el equipo abra sin contraseña** —en computadora y
en celular— donde **solo 2 o 3 personas puedan editar**.

Son dos piezas independientes:

| Pieza | Para qué | Costo |
|---|---|---|
| **Supabase** | Guarda las visitas y decide quién puede escribir. | Gratis |
| **Hosting estático** | Sirve el archivo `index.html` en una dirección pública. | Gratis |

---

## Paso 1 — Base de datos y editores (Supabase)

1. Crear una cuenta en [supabase.com](https://supabase.com) y un proyecto nuevo
   (región recomendada: *South America (São Paulo)*).
2. Abrir **SQL Editor → New query**, pegar el contenido de
   [`db/schema.sql`](db/schema.sql) y ejecutarlo. Crea la tabla `visitas`, la
   tabla `editores` y las políticas que dejan **leer a cualquiera** y
   **escribir solo a los correos autorizados**.
3. En el mismo editor, registrar a los editores:

   ```sql
   insert into public.editores (email, nombre) values
     ('persona1@dominio.pe', 'Nombre 1'),
     ('persona2@dominio.pe', 'Nombre 2'),
     ('persona3@dominio.pe', 'Nombre 3')
   on conflict (email) do nothing;
   ```

   Para quitar o agregar un editor más adelante basta con otro `insert` o un
   `delete` sobre esta tabla: no hay que tocar la aplicación.
4. Registrar a los inspectores, con el nombre **tal cual** se escribe en la
   agenda:

   ```sql
   insert into public.inspectores (nombre, email) values
     ('J. Quispe', 'jquispe@dominio.pe'),
     ('R. Vargas', 'rvargas@dominio.pe')
   on conflict (nombre) do update set email = excluded.email;
   ```

   Cada uno podrá cambiar el **estado** y las **observaciones** de sus propias
   visitas, y nada más. Los editores del paso 3 administran todo.

5. **Project Settings → API**: copiar `Project URL` y la clave `anon`, y
   pegarlas en [`config.js`](config.js).

> La clave `anon` viaja en el navegador de cualquier visitante y eso es normal:
> quién puede escribir lo decide el RLS del paso 2, no la clave.

6. **Authentication → Email Templates → Magic Link**: agregar el código al
   correo, para que el acceso también funcione cuando alguien pide el ingreso
   desde el celular y abre el correo en otro equipo. El contenido queda así:

   ```html
   <h2>Acceso a la agenda de inspecciones</h2>
   <p>Tu código es: <strong>{{ .Token }}</strong></p>
   <p>Escríbelo en la aplicación, en el mismo dispositivo donde lo pediste.</p>
   <p>O entra directo desde este dispositivo:
      <a href="{{ .ConfirmationURL }}">abrir la agenda</a></p>
   ```

   Sin `{{ .Token }}` el correo solo trae el enlace, y el enlace inicia sesión
   únicamente en el aparato donde se abre.

7. **Authentication → URL Configuration**: poner
   `https://gsilvestre-pixel.github.io/catty/` como *Site URL* y agregarla
   también en *Redirect URLs*. Sin esto, el enlace de acceso que reciben los
   editores por correo no los devuelve a la agenda.

> **Proyecto que ya estaba funcionando:** no vuelvas a ejecutar `schema.sql`.
> Ejecuta una sola vez
> [`db/migracion-01-estados-e-inspectores.sql`](db/migracion-01-estados-e-inspectores.sql),
> que renombra `resultado` a `estado`, agrega *reprogramado* y crea la tabla
> `inspectores` con sus permisos, sin tocar las visitas ya cargadas.

## Paso 2 — Dirección pública (GitHub Pages)

GitHub Pages publica repositorios privados solo en los planes de pago, así que
el repositorio debe hacerse público. Se publica únicamente el código de la
aplicación: **las visitas viven en Supabase, no en el repositorio**, y
`config.js` solo lleva la clave `anon`, que es pública por diseño.

1. **Settings → General → Danger Zone → Change repository visibility →
   Make public**, y confirmar escribiendo el nombre del repositorio.
2. **Settings → Pages → Build and deployment**
   - *Source*: **Deploy from a branch**
   - *Branch*: `claude/entity-visits-management-h90pe8` (es la rama por
     defecto del repositorio) y carpeta **`/ (root)`** → **Save**.
3. Esperar uno o dos minutos. El enlace queda en:

   ```
   https://gsilvestre-pixel.github.io/catty/
   ```

Ese es el enlace para el equipo. Cada vez que se actualice la rama, el sitio se
republica solo.

> Si más adelante prefiere mantener el repositorio privado, el mismo contenido
> se publica igual desde Cloudflare Pages, Netlify o Vercel (plan gratuito,
> framework *None*, directorio de salida `/`).

## Paso 3 — Uso en el celular

El enlace funciona en el navegador del teléfono tal cual. Para que se vea como
una aplicación:

- **Android (Chrome)**: menú ⋮ → *Agregar a pantalla principal*.
- **iPhone (Safari)**: botón compartir → *Añadir a pantalla de inicio*.

Queda con ícono propio y a pantalla completa, y abre en la vista de **día**, que
es la más legible en pantalla chica.

## Cómo queda el acceso

| Quién | Qué puede hacer |
|---|---|
| Cualquiera con el enlace | Ver la agenda en las tres vistas y filtrar por persona. |
| Los correos de `editores` | **Activar edición**, recibir un enlace de acceso por correo y programar, editar o eliminar visitas. |

Los cambios de un editor aparecen en vivo en los navegadores que estén abiertos.

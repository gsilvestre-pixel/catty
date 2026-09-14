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
4. **Project Settings → API**: copiar `Project URL` y la clave `anon`, y
   pegarlas en [`config.js`](config.js).

> La clave `anon` viaja en el navegador de cualquier visitante y eso es normal:
> quién puede escribir lo decide el RLS del paso 2, no la clave.

5. **Authentication → URL Configuration**: poner la dirección pública del paso 2
   como *Site URL* y agregarla también en *Redirect URLs*.

## Paso 2 — Dirección pública

Este repositorio es **privado**, y GitHub Pages solo publica repositorios
privados en los planes de pago. Dos caminos, ambos gratuitos:

**A. Hacer público el repositorio y usar GitHub Pages**
   *Settings → General → Danger Zone → Change visibility → Public*, y luego
   *Settings → Pages → Source: Deploy from a branch →* rama de este trabajo,
   carpeta `/ (root)`. El enlace queda como
   `https://gsilvestre-pixel.github.io/catty/`.
   Se publica solo el código de la aplicación: las visitas viven en Supabase,
   no en el repositorio.

**B. Mantener el repositorio privado y publicar con Cloudflare Pages**
   Crear una cuenta en [pages.cloudflare.com](https://pages.cloudflare.com),
   *Create a project → Connect to Git*, autorizar el repositorio, dejar el
   framework en **None** y el directorio de salida en `/`. El enlace queda como
   `https://catty.pages.dev`. (Netlify y Vercel funcionan igual.)

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

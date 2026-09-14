/* Conexión a la base de datos en línea (PostgreSQL / Supabase).
   Pegar aquí los dos valores de Project Settings → API.
   La clave anon es pública por diseño: quién puede escribir lo decide el
   RLS declarado en db/schema.sql, no esta clave.                          */
window.CONFIG_SUPABASE = {
  url: "",
  anonKey: ""
};

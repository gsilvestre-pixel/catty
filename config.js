/* Conexión a la base de datos en línea (PostgreSQL / Supabase).
   Pegar aquí los dos valores de Project Settings → API.
   La clave anon es pública por diseño: quién puede escribir lo decide el
   RLS declarado en db/schema.sql, no esta clave.                          */
/* Acceso privado: con true, la agenda pide correo y contraseña al abrirse y
   no muestra nada a quien no inicie sesión. Las contraseñas viven en
   Supabase, nunca en este archivo.                                        */
window.CONFIG_ACCESO = {
  privado: false
};

window.CONFIG_SUPABASE = {
  url: "https://mekiuidgbtztzhysyykd.supabase.co",
  anonKey: "sb_publishable_8RKW_rzTBpVMj1aVtK_V7A_vnGtdidz"
};

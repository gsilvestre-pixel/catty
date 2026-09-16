/* Conexión a la base de datos en línea (PostgreSQL / Supabase).
   Pegar aquí los dos valores de Project Settings → API.
   La clave anon es pública por diseño: quién puede escribir lo decide el
   RLS declarado en db/schema.sql, no esta clave.                          */
/* Cuenta compartida con la que el equipo ve la agenda con una sola clave.
   El correo NO es secreto; la contraseña la escribe cada persona y la
   valida Supabase, nunca se guarda en este archivo.                      */
window.CONFIG_EQUIPO = {
  correo: ""      // ej. "equipo@jmasociados.pe"
};

window.CONFIG_SUPABASE = {
  url: "https://mekiuidgbtztzhysyykd.supabase.co",
  anonKey: "sb_publishable_8RKW_rzTBpVMj1aVtK_V7A_vnGtdidz"
};

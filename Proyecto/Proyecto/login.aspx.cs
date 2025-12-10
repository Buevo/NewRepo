using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Security.Cryptography;
using System.Text;
using System.Web.Services;
using System.Web.Script.Services;

namespace Proyecto
{
    public partial class login : System.Web.UI.Page
    {
        private readonly string _cnxName = "CnxVanguardia3";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Intentar restaurar sesión desde cookie (si existe)
                TryRestoreSessionFromCookie();

                // Si la sesión ya existe, redirigir según rol
                if (Session["IDUsuario"] != null)
                {
                    RedirectByRole(Session["Rol"]?.ToString());
                }
            }
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            string usuario = txtUsername.Text?.Trim();
            string password = txtPassword.Text ?? string.Empty;
            bool remember = chkRemember.Checked;

            if (string.IsNullOrWhiteSpace(usuario) || string.IsNullOrWhiteSpace(password))
            {
                ShowMessage("Completa usuario y contraseña", "text-danger");
                return;
            }

            try
            {
                byte[] passwordHash = ComputeSHA256Bytes(password);

                using (var da = new DataAccess(_cnxName))
                {
                    // Asegúrate que ValidateUser reciba byte[] para PasswordHash
                    var user = da.ValidateUser(usuario, passwordHash);
                    if (user == null)
                    {
                        ShowMessage("Usuario o contraseña incorrectos", "text-danger");
                        return;
                    }

                    if (!user.Activo)
                    {
                        ShowMessage("Usuario inactivo. Contacte al administrador.", "text-danger");
                        return;
                    }

                    // Establecer sesión
                    Session["IDUsuario"] = user.IdUsuario;
                    Session["NombreUsuario"] = user.NombreUsuario;
                    Session["Rol"] = user.Rol;

                    // Crear cookie de autenticación (server-side)
                    CreateAuthCookie(user.IdUsuario, user.NombreUsuario, user.Rol, remember);

                    // Intentar actualizar último ingreso (no fatal)
                    try { da.UpdateLastLogin(user.IdUsuario); } catch { }

                    RedirectByRole(user.Rol);
                }
            }
            catch (Exception ex)
            {
                ShowMessage("Error interno al intentar autenticar: " + ex.Message, "text-danger");
            }
        }

        #region Helpers

        /// <summary>
        /// Devuelve SHA-256 en formato binario (byte[32]) — compatible con VARBINARY(32) en SQL.
        /// </summary>
        private static byte[] ComputeSHA256Bytes(string input)
        {
            if (input == null) return null;
            using (var sha = SHA256.Create())
            {
                return sha.ComputeHash(Encoding.UTF8.GetBytes(input));
            }
        }

        private void CreateAuthCookie(int idUsuario, string nombreUsuario, string rol, bool remember)
        {
            string valor = $"{idUsuario}|{nombreUsuario}|{rol}|{DateTime.UtcNow.Ticks}";
            HttpCookie cookie = new HttpCookie("AuthUser", valor)
            {
                HttpOnly = true,
                Secure = Request.IsSecureConnection
            };

            if (remember) cookie.Expires = DateTime.UtcNow.AddDays(7);
            else cookie.Expires = DateTime.UtcNow.AddDays(-8);

            // Path root para que esté disponible en todo el sitio
            cookie.Path = "/";

            Response.Cookies.Add(cookie);
        }

        private void TryRestoreSessionFromCookie()
        {
            try
            {
                var cookie = Request.Cookies["AuthUser"];
                if (cookie == null || string.IsNullOrEmpty(cookie.Value)) return;

                var partes = cookie.Value.Split('|');
                if (partes.Length < 3) return;

                if (!int.TryParse(partes[0], out int idUsuario)) return;
                string nombreUsuario = partes[1];
                string rol = partes[2];

                // Restaurar sesión
                Session["IDUsuario"] = idUsuario;
                Session["NombreUsuario"] = nombreUsuario;
                Session["Rol"] = rol;
            }
            catch
            {
                // No critico si falla restaurar sesión desde cookie
            }
        }

        private void RedirectByRole(string rol)
        {
            if (string.Equals(rol, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/products.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            else
            {
                Response.Redirect("~/user_products.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        /// <summary>
        /// Expone un WebMethod logout para que el cliente pueda pedir cierre por AJAX.
        /// </summary>
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object Logout()
        {
            try
            {
                // Limpiar sesión server-side
                HttpContext.Current.Session.Clear();
                HttpContext.Current.Session.Abandon();

                // Borrar cookie de autenticación HttpOnly (se reemplaza con expiración pasada)
                var cookie = new HttpCookie("AuthUser", "");
                cookie.Expires = DateTime.UtcNow.AddDays(-7);
                cookie.Path = "/";
                HttpContext.Current.Response.Cookies.Add(cookie);

                // También borrar posible cookie de sesión
                var sessionCookie = new HttpCookie("ASP.NET_SessionId", "");
                sessionCookie.Expires = DateTime.UtcNow.AddDays(-7);
                sessionCookie.Path = "/";
                HttpContext.Current.Response.Cookies.Add(sessionCookie);

                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        private void ShowMessage(string text, string cssClass)
        {
            litLoginMsg.Text = $"<div class=\"mt-3 {cssClass}\">{HttpUtility.HtmlEncode(text)}</div>";
        }

        #endregion
    }
}

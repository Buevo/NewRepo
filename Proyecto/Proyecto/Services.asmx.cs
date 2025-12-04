using System;
using System.Web;
using System.Web.Services;
using System.Web.Script.Services;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

namespace Proyecto
{
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    [System.Web.Script.Services.ScriptService] // habilita JSON desde JS
    public class Services : System.Web.Services.WebService
    {
        private readonly string _cnxName = "CnxVanguardia3";

        public Services() { }

        // DTO para respuesta
     

        // ===========================
        // Helpers: Hash
        // ===========================
        private static byte[] ComputeSHA256Bytes(string input)
        {
            using (var sha = SHA256.Create())
            {
                return sha.ComputeHash(Encoding.UTF8.GetBytes(input));
            }
        }

        private static byte[] HexStringToBytes(string hex)
        {
            if (string.IsNullOrEmpty(hex)) return new byte[0];
            if (hex.Length % 2 != 0) throw new ArgumentException("Hex string must have even length");
            var bytes = new byte[hex.Length / 2];
            for (int i = 0; i < bytes.Length; i++)
            {
                bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
            }
            return bytes;
        }

        // ===========================
        // Helpers: Cookie manual (AuthUser)
        // formato: IdUsuario|NombreUsuario|Rol|Ticks
        // ===========================
        private void CrearCookieSesion(int idUsuario, string nombreUsuario, string rol, bool remember)
        {
            string valor = $"{idUsuario}|{nombreUsuario}|{rol}|{DateTime.UtcNow.Ticks}";
            HttpCookie cookie = new HttpCookie("AuthUser", valor)
            {
                HttpOnly = true,
                SameSite = SameSiteMode.Lax,
                Secure = Context.Request.IsSecureConnection
            };

            if (remember) cookie.Expires = DateTime.UtcNow.AddDays(7);
            else cookie.Expires = DateTime.UtcNow.AddHours(8); // cookie temporal con expiración corta

            Context.Response.Cookies.Add(cookie);
        }

        private bool TryRestaurarSesionDesdeCookie()
        {
            try
            {
                if (Session["IDUsuario"] != null) return true;

                var cookie = Context.Request.Cookies["AuthUser"];
                if (cookie == null || string.IsNullOrEmpty(cookie.Value)) return false;

                var partes = cookie.Value.Split('|');
                if (partes.Length < 4) return false;

                if (!int.TryParse(partes[0], out int idUsuario)) return false;
                var nombreUsuario = partes[1];
                var rol = partes[2];

                // Reconstruir sesión mínima
                Session["IDUsuario"] = idUsuario;
                Session["NombreUsuario"] = nombreUsuario;
                Session["Rol"] = rol;
                return true;
            }
            catch
            {
                return false;
            }
        }

        private void BorrarCookieSesion()
        {
            if (Context.Request.Cookies["AuthUser"] != null)
            {
                HttpCookie cookie = new HttpCookie("AuthUser") { Expires = DateTime.UtcNow.AddDays(-1) };
                Context.Response.Cookies.Add(cookie);
            }
        }

        // ===========================
        // WebMethod: Login
        // ===========================
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public LoginResult Login(string usuario, string password, bool remember)
        {
            var result = new LoginResult();

            if (string.IsNullOrWhiteSpace(usuario) || string.IsNullOrWhiteSpace(password))
            {
                result.message = "Usuario y contraseña son requeridos.";
                return result;
            }

            try
            {
                byte[] passwordHash = ComputeSHA256Bytes(password);

                using (var da = new DataAccess(_cnxName))
                {
                    var user = da.ValidateUser(usuario, passwordHash);
                    if (user == null)
                    {
                        result.message = "Credenciales inválidas.";
                        return result;
                    }

                    if (!user.Activo)
                    {
                        result.message = "Usuario inactivo. Contacte al administrador.";
                        return result;
                    }

                    // setear session
                    Session["IDUsuario"] = user.IdUsuario;
                    Session["NombreUsuario"] = user.NombreUsuario;
                    Session["Rol"] = user.Rol;

                    // crear cookie manual
                    CrearCookieSesion(user.IdUsuario, user.NombreUsuario, user.Rol, remember);

                    // actualizar fecha ultimo ingreso (no fatal)
                    try { da.UpdateLastLogin(user.IdUsuario); } catch { }

                    result.success = true;
                    result.IdUsuario = user.IdUsuario;
                    result.NombreUsuario = user.NombreUsuario;
                    result.Rol = user.Rol;
                    return result;
                }
            }
            catch (SqlException)
            {
                result.message = "Error en la conexión a la base de datos.";
                return result;
            }
            catch (Exception ex)
            {
                result.message = "Error interno: " + ex.Message;
                return result;
            }
        }

        // ===========================
        // WebMethod: Logout
        // ===========================
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public object Logout()
        {
            try
            {
                Session.Clear();
                Session.Abandon();
                BorrarCookieSesion();
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        // ===========================
        // WebMethod: CheckSession (reconstruye desde cookie si es posible)
        // ===========================
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public object CheckSession()
        {
            if (Session["IDUsuario"] == null)
            {
                var ok = TryRestaurarSesionDesdeCookie();
                if (!ok) return new { authenticated = false };
            }

            return new
            {
                authenticated = true,
                IdUsuario = Session["IDUsuario"],
                NombreUsuario = Session["NombreUsuario"],
                Rol = Session["Rol"]
            };
        }
    }
}

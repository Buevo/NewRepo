using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using System.Web.Script.Services;

namespace Proyecto
{
    public partial class user_products : System.Web.UI.Page
    {
        private readonly string _cnxName = "CnxVanguardia3";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Seguridad: requerir sesión
                if (Session["IDUsuario"] == null)
                {
                    Response.Redirect("~/login.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                // Si es Admin redirigimos a la vista admin (opcional)
                var rol = Session["Rol"]?.ToString() ?? "";
                if (string.Equals(rol, "Admin", StringComparison.OrdinalIgnoreCase))
                {
                    // si prefieres que Admin vea la vista normal, quita la siguiente redirección
                    Response.Redirect("~/products.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
        }

        // Reuso de WebMethods: GetProducts (idéntico a products.cs)
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetProducts(string filtro)
        {
            var list = new List<Dictionary<string, object>>();
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetProducts", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@filtro", SqlDbType.NVarChar, 500) { Value = (object)filtro ?? DBNull.Value });
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            var row = new Dictionary<string, object>
                            {
                                ["IdProducto"] = rdr.GetInt32(rdr.GetOrdinal("IdProducto")),
                                ["Codigo"] = rdr["Codigo"] as string ?? "",
                                ["Descripcion"] = rdr["Descripcion"] as string ?? "",
                                ["Precio"] = rdr["Precio"] == DBNull.Value ? 0m : rdr.GetDecimal(rdr.GetOrdinal("Precio")),
                                ["Stock"] = rdr["Stock"] == DBNull.Value ? 0 : rdr.GetInt32(rdr.GetOrdinal("Stock")),
                                ["Activo"] = rdr["Activo"] == DBNull.Value ? false : rdr.GetBoolean(rdr.GetOrdinal("Activo"))
                            };
                            list.Add(row);
                        }
                    }
                }
                return new { success = true, data = list };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        // Logout AJAX (puedes reutilizar el de products.cs — lo incluyo aquí también para facilitar llamadas si cambias la URL)
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object Logout()
        {
            try
            {
                HttpContext.Current.Session.Clear();
                HttpContext.Current.Session.Abandon();

                var authCookie = new HttpCookie("AuthUser", "");
                authCookie.Expires = DateTime.UtcNow.AddDays(-7);
                authCookie.Path = "/";
                HttpContext.Current.Response.Cookies.Add(authCookie);

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
    }
}

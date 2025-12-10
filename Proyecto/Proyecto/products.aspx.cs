using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Services;
using System.Web.Script.Services;

namespace Proyecto
{
    public partial class products : System.Web.UI.Page
    {
        // Nombre de la cadena de conexión en web.config
        private readonly string _cnxName = "CnxVanguardia3";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Seguridad: asegurarse que haya sesión (igual que login)
                if (Session["IDUsuario"] == null)
                {
                    Response.Redirect("~/login.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                // Solo Admin puede ver esta página
                var rol = Session["Rol"]?.ToString() ?? "";
                if (!string.Equals(rol, "Admin", StringComparison.OrdinalIgnoreCase))
                {
                    Response.Redirect("~/user_products.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
        }

        #region WebMethods (JSON)

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetProducts(string filtro)
        {
            var list = new List<Dictionary<string, object>>();
            var cnxName = "CnxVanguardia3"; // campo estático por WebMethod
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

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetProductById(int idProducto)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetProductById", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Int) { Value = idProducto });
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            var obj = new
                            {
                                IdProducto = rdr.GetInt32(rdr.GetOrdinal("IdProducto")),
                                Codigo = rdr["Codigo"] as string ?? "",
                                Descripcion = rdr["Descripcion"] as string ?? "",
                                Precio = rdr["Precio"] == DBNull.Value ? 0m : rdr.GetDecimal(rdr.GetOrdinal("Precio")),
                                Stock = rdr["Stock"] == DBNull.Value ? 0 : rdr.GetInt32(rdr.GetOrdinal("Stock")),
                                Activo = rdr["Activo"] == DBNull.Value ? false : rdr.GetBoolean(rdr.GetOrdinal("Activo"))
                            };
                            return new { success = true, data = obj };
                        }
                    }
                }

                return new { success = false, message = "Producto no encontrado" };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object CreateProduct(string codigo, string descripcion, decimal precio, int stock)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_CreateProduct", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@Codigo", SqlDbType.NVarChar, 50) { Value = codigo });
                    cmd.Parameters.Add(new SqlParameter("@Descripcion", SqlDbType.NVarChar, 500) { Value = descripcion });
                    cmd.Parameters.Add(new SqlParameter("@Precio", SqlDbType.Decimal) { Value = precio, Precision = 18, Scale = 2 });
                    cmd.Parameters.Add(new SqlParameter("@Stock", SqlDbType.Int) { Value = stock });
                    var outId = new SqlParameter("@NewIdProducto", SqlDbType.Int) { Direction = ParameterDirection.Output };
                    cmd.Parameters.Add(outId);

                    cn.Open();
                    cmd.ExecuteNonQuery();
                    int newId = (outId.Value == DBNull.Value) ? 0 : Convert.ToInt32(outId.Value);
                    return new { success = true, newId = newId };
                }
            }
            catch (SqlException ex)
            {
                return new { success = false, message = ex.Message };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object UpdateProduct(int idProducto, string codigo, string descripcion, decimal precio, int stock)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_UpdateProduct", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Int) { Value = idProducto });
                    cmd.Parameters.Add(new SqlParameter("@Codigo", SqlDbType.NVarChar, 50) { Value = codigo });
                    cmd.Parameters.Add(new SqlParameter("@Descripcion", SqlDbType.NVarChar, 500) { Value = descripcion });
                    cmd.Parameters.Add(new SqlParameter("@Precio", SqlDbType.Decimal) { Value = precio, Precision = 18, Scale = 2 });
                    cmd.Parameters.Add(new SqlParameter("@Stock", SqlDbType.Int) { Value = stock });

                    cn.Open();
                    cmd.ExecuteNonQuery();
                    return new { success = true };
                }
            }
            catch (SqlException ex)
            {
                return new { success = false, message = ex.Message };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object DeleteProduct(int idProducto)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_DeleteProduct", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Int) { Value = idProducto });
                    cn.Open();
                    cmd.ExecuteNonQuery();
                    return new { success = true };
                }
            }
            catch (SqlException ex)
            {
                return new { success = false, message = ex.Message };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }

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
            #endregion
        }
}

       
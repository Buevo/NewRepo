using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.UI;

namespace Proyecto
{
    public partial class admin_users : Page
    {
        private readonly string _cnxName = "CnxVanguardia3";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Requiere sesión y rol Admin (misma lógica que products.aspx.cs)
                if (Session["IDUsuario"] == null)
                {
                    Response.Redirect("~/login.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                var rol = Session["Rol"]?.ToString() ?? "";
                if (!string.Equals(rol, "Admin", StringComparison.OrdinalIgnoreCase))
                {
                    Response.Redirect("~/user_products.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
        }

        #region Helpers

        private static string HashSha256(string input)
        {
            if (string.IsNullOrEmpty(input)) return null;
            using (var sha = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(input);
                var hash = sha.ComputeHash(bytes);
                var sb = new StringBuilder();
                foreach (var b in hash) sb.Append(b.ToString("x2"));
                return sb.ToString();
            }
        }

        #endregion

        #region WebMethods

        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetUsers(string filtro)
        {
            var list = new List<Dictionary<string, object>>();
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetUsers", cn))
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
                                ["IdUsuario"] = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : 0,
                                ["NombreUsuario"] = rdr["NombreUsuario"] as string ?? "",
                                ["NombreCompleto"] = rdr["NombreCompleto"] as string ?? "",
                                ["Email"] = rdr["Email"] as string ?? "",
                                ["Rol"] = rdr["Rol"] as string ?? "Usuario",
                                ["Activo"] = rdr["Activo"] != DBNull.Value ? Convert.ToBoolean(rdr["Activo"]) : false
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
        private static byte[] HashSha256Bytes(string input)
        {
            if (string.IsNullOrEmpty(input)) return null;
            using (var sha = System.Security.Cryptography.SHA256.Create())
            {
                return sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(input));
            }
        }





        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object GetUserById(int idUsuario)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetUserById", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            var obj = new
                            {
                                IdUsuario = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : 0,
                                NombreUsuario = rdr["NombreUsuario"] as string ?? "",
                                NombreCompleto = rdr["NombreCompleto"] as string ?? "",
                                Email = rdr["Email"] as string ?? "",
                                Rol = rdr["Rol"] as string ?? "Usuario",
                                Activo = rdr["Activo"] != DBNull.Value ? Convert.ToBoolean(rdr["Activo"]) : false
                            };
                            return new { success = true, data = obj };
                        }
                    }
                }

                return new { success = false, message = "Usuario no encontrado" };
            }
            catch (Exception ex)
            {
                return new { success = false, message = ex.Message };
            }
        }


        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static object CreateUser(string nombreUsuario, string nombreCompleto, string email, string password, string rol, bool activo)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                if (string.IsNullOrWhiteSpace(nombreUsuario))
                    return new { success = false, message = "Nombre de usuario requerido." };

                // Para creación: exigir contraseña no vacía (ajusta si quieres permitir usuarios sin password)
                if (string.IsNullOrEmpty(password))
                    return new { success = false, message = "Contraseña requerida para crear usuario." };

                var passHash = HashSha256Bytes(password); // byte[] o null

                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_CreateUser", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario });
                    cmd.Parameters.Add(new SqlParameter("@NombreCompleto", SqlDbType.NVarChar, 200) { Value = (object)nombreCompleto ?? DBNull.Value });
                    cmd.Parameters.Add(new SqlParameter("@Email", SqlDbType.NVarChar, 200) { Value = (object)email ?? DBNull.Value });

                    var pPass = new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32);
                    pPass.Value = (object)passHash ?? DBNull.Value;
                    cmd.Parameters.Add(pPass);

                    cmd.Parameters.Add(new SqlParameter("@Rol", SqlDbType.NVarChar, 50) { Value = (object)rol ?? "Usuario" });
                    cmd.Parameters.Add(new SqlParameter("@Activo", SqlDbType.Bit) { Value = activo });

                    var outId = new SqlParameter("@NewIdUsuario", SqlDbType.Int) { Direction = ParameterDirection.Output };
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
        public static object UpdateUser(int idUsuario, string nombreUsuario, string nombreCompleto, string email, string password, string rol, bool activo)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                if (idUsuario <= 0) return new { success = false, message = "IdUsuario inválido." };
                if (string.IsNullOrWhiteSpace(nombreUsuario)) return new { success = false, message = "Nombre de usuario requerido." };

                var passHash = string.IsNullOrEmpty(password) ? null : HashSha256Bytes(password);

                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_UpdateUser", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                    cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario });
                    cmd.Parameters.Add(new SqlParameter("@NombreCompleto", SqlDbType.NVarChar, 200) { Value = (object)nombreCompleto ?? DBNull.Value });
                    cmd.Parameters.Add(new SqlParameter("@Email", SqlDbType.NVarChar, 200) { Value = (object)email ?? DBNull.Value });

                    var pPass = new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32);
                    pPass.Value = (object)passHash ?? DBNull.Value; // SP acepta NULL -> no cambia
                    cmd.Parameters.Add(pPass);

                    cmd.Parameters.Add(new SqlParameter("@Rol", SqlDbType.NVarChar, 50) { Value = (object)rol ?? "Usuario" });
                    cmd.Parameters.Add(new SqlParameter("@Activo", SqlDbType.Bit) { Value = activo });

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
        public static object DeleteUser(int idUsuario)
        {
            var cnxName = "CnxVanguardia3";
            try
            {
                if (idUsuario <= 0) return new { success = false, message = "IdUsuario inválido." };

                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[cnxName].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_DeleteUser", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
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

        #endregion
    }
}

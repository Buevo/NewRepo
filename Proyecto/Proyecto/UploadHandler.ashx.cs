using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.SessionState;

namespace Proyecto
{
    /// <summary>
    /// Summary description for UploadHandler
    /// </summary>
    public class UploadHandler : IHttpHandler, IRequiresSessionState
    {
        private readonly string[] _allowedExt = new[] { ".jpg", ".jpeg", ".png", ".pdf", ".docx" };
        private const long MAX_BYTES = 5 * 1024 * 1024; // 5 MB
        private const string CNX = "CnxVanguardia3";

        public void ProcessRequest(HttpContext context)
        {
            try
            {
                // Sesión: validar usuario logueado
                var idUsuarioObj = context.Session != null ? context.Session["IDUsuario"] : null;
                if (idUsuarioObj == null)
                {
                    context.Response.StatusCode = 401;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"Usuario no autenticado.\"}");
                    return;
                }

                // Leer IdProducto
                int idProducto = 0;
                int.TryParse(context.Request.Form["IdProducto"], out idProducto);
                if (idProducto <= 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"IdProducto inválido.\"}");
                    return;
                }

                if (context.Request.Files.Count == 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"No se envió archivo.\"}");
                    return;
                }

                HttpPostedFile file = context.Request.Files[0];
                if (file == null || file.ContentLength == 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"Archivo vacio.\"}");
                    return;
                }

                if (file.ContentLength > MAX_BYTES)
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"Archivo excede el tamaño máximo de 5 MB.\"}");
                    return;
                }

                string ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!_allowedExt.Contains(ext))
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("{\"success\":false, \"message\":\"Tipo de archivo no permitido.\"}");
                    return;
                }

                // Preparar carpeta física: /ArchivosProductos/{IdProducto}/
                string productFolder = context.Server.MapPath($"~/ArchivosProductos/{idProducto}/");
                if (!Directory.Exists(productFolder)) Directory.CreateDirectory(productFolder);

                // Renombrar: SHA256(originalName + timestamp) + ext
                string timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
                string originalName = Path.GetFileName(file.FileName);
                string shaName = ComputeSHA256Hex(originalName + "|" + timestamp) + ext;
                string savePath = Path.Combine(productFolder, shaName);

                file.SaveAs(savePath);

                // Registrar en BD (sp_InsertFile)
                long tamano = file.ContentLength;
                string tipo = file.ContentType;
                string nombreVisible = context.Request.Form["NombreVisible"] ?? originalName;
                int idUsuarioSubio = Convert.ToInt32(idUsuarioObj);

                int newIdArchivo = 0;
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[CNX].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_InsertFile", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Int) { Value = idProducto });
                    cmd.Parameters.Add(new SqlParameter("@NombreVisible", SqlDbType.NVarChar, 250) { Value = (object)nombreVisible ?? DBNull.Value });
                    cmd.Parameters.Add(new SqlParameter("@NombreFisico", SqlDbType.NVarChar, 260) { Value = shaName });
                    cmd.Parameters.Add(new SqlParameter("@TipoArchivo", SqlDbType.NVarChar, 100) { Value = tipo });
                    cmd.Parameters.Add(new SqlParameter("@TamanoBytes", SqlDbType.BigInt) { Value = tamano });
                    cmd.Parameters.Add(new SqlParameter("@IdUsuarioSubio", SqlDbType.Int) { Value = idUsuarioSubio });
                    var outId = new SqlParameter("@NewIdArchivo", SqlDbType.Int) { Direction = ParameterDirection.Output };
                    cmd.Parameters.Add(outId);

                    cn.Open();
                    cmd.ExecuteNonQuery();
                    if (outId.Value != DBNull.Value) newIdArchivo = Convert.ToInt32(outId.Value);
                }

                context.Response.ContentType = "application/json";
                context.Response.Write("{\"success\":true, \"message\":\"Archivo subido correctamente.\", \"IdArchivo\":" + newIdArchivo + "}");
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.ContentType = "application/json";
                context.Response.Write("{\"success\":false, \"message\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
            }
        }

        private static string ComputeSHA256Hex(string input)
        {
            using (var sha = SHA256.Create())
            {
                var b = sha.ComputeHash(Encoding.UTF8.GetBytes(input));
                var sb = new StringBuilder();
                foreach (var bt in b) sb.Append(bt.ToString("x2"));
                return sb.ToString();
            }
        }

        public bool IsReusable
        {
            get
            {
                return false;
            }
        }
    }
}
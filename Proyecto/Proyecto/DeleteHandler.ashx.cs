using System;
using System.IO;
using System.Web;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.SessionState;

namespace Proyecto
{

    public class DeleteHandler : IHttpHandler
    {
        private const string CNX = "CnxVanguardia3";

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            try
            {
                // Validar sesión
                
               
                // Leer idArchivo (POST preferido)
                int idArchivo = 0;
                if (string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
                {
                    int.TryParse(context.Request.Form["idArchivo"], out idArchivo);
                }
                if (idArchivo <= 0)
                {
                    int.TryParse(context.Request.QueryString["idArchivo"], out idArchivo);
                }

                if (idArchivo <= 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write("{\"success\":false,\"message\":\"Parámetro idArchivo inválido.\"}");
                    return;
                }

                // Obtener info del archivo desde BD
                string nombreFisico = null;
                int idProducto = 0;
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[CNX].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetFileById", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdArchivo", SqlDbType.Int) { Value = idArchivo });
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        if (rdr.Read())
                        {
                            nombreFisico = rdr["NombreFisico"] as string;
                            idProducto = rdr["IdProducto"] != DBNull.Value ? Convert.ToInt32(rdr["IdProducto"]) : 0;
                        }
                    }
                }

                if (string.IsNullOrEmpty(nombreFisico) || idProducto <= 0)
                {
                    context.Response.StatusCode = 404;
                    context.Response.Write("{\"success\":false,\"message\":\"Archivo no encontrado en la base de datos.\"}");
                    return;
                }

                // Construir ruta y eliminar fichero físico (si existe)
                string filePath = context.Server.MapPath($"~/ArchivosProductos/{idProducto}/{nombreFisico}");
                try
                {
                    if (File.Exists(filePath))
                    {
                        File.Delete(filePath);
                    }
                }
                catch (Exception exDelete)
                {
                    // No abortamos DB delete por ahora, pero reportamos error si no se puede borrar físicamente.
                    context.Response.StatusCode = 500;
                    context.Response.Write("{\"success\":false,\"message\":\"Error al eliminar archivo físico: " + HttpUtility.JavaScriptStringEncode(exDelete.Message) + "\"}");
                    return;
                }

                // Eliminar registro en BD (sp_DeleteFile)
                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[CNX].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_DeleteFile", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdArchivo", SqlDbType.Int) { Value = idArchivo });
                    cn.Open();
                    cmd.ExecuteNonQuery();
                }

                // Responder éxito
                context.Response.Write("{\"success\":true,\"message\":\"Archivo eliminado correctamente.\"}");
                return;
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"success\":false,\"message\":\"" + HttpUtility.JavaScriptStringEncode(ex.Message) + "\"}");
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
using System;
using System.IO;
using System.Web;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.SessionState;

public class DownloadHandler : IHttpHandler, IRequiresSessionState
{
    private const string CNX = "CnxVanguardia3";

    public void ProcessRequest(HttpContext context)
    {
        bool debug = string.Equals(context.Request.QueryString["debug"], "1", StringComparison.OrdinalIgnoreCase);

        try
        {
            // Validar sesión (si tu sistema exige login para descargar)
            var ses = context.Session;
            if (ses == null || ses["IDUsuario"] == null)
            {
                context.Response.StatusCode = 401;
                if (debug) { context.Response.ContentType = "application/json"; context.Response.Write("{\"success\":false,\"message\":\"Usuario no autenticado.\"}"); }
                else { context.Response.ContentType = "text/plain"; context.Response.Write("401 Unauthorized - usuario no autenticado."); }
                return;
            }

            // Leer idArchivo
            int idArchivo = 0;

            // Primero intentar leer desde Request.Form (POST usando FormData)
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
                context.Response.ContentType = "application/json";
                context.Response.Write("{\"success\":false,\"message\":\"Parámetro idArchivo inválido.\"}");
                return;
            }

            // Obtener info desde BD
            string nombreFisico = null;
            string nombreVisible = null;
            string tipo = null;
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
                        nombreVisible = rdr["NombreVisible"] as string;
                        tipo = rdr["TipoArchivo"] as string;
                        idProducto = rdr["IdProducto"] != DBNull.Value ? Convert.ToInt32(rdr["IdProducto"]) : 0;
                    }
                }
            }

            if (string.IsNullOrEmpty(nombreFisico) || idProducto <= 0)
            {
                context.Response.StatusCode = 404;
                context.Response.ContentType = "application/json";
                context.Response.Write("{\"success\":false,\"message\":\"Archivo no encontrado en la base de datos.\"}");
                return;
            }

            // Construir ruta y validar existencia
            string filePath = context.Server.MapPath($"~/ArchivosProductos/{idProducto}/{nombreFisico}");
            if (!File.Exists(filePath))
            {
                context.Response.StatusCode = 404;
                if (debug) { context.Response.ContentType = "application/json"; context.Response.Write("{\"success\":false,\"message\":\"Archivo físico no encontrado.\",\"path\":\"" + HttpUtility.JavaScriptStringEncode(filePath) + "\"}"); }
                else { context.Response.ContentType = "text/plain"; context.Response.Write("Archivo físico no encontrado."); }
                return;
            }

            // Enviar archivo al cliente
            string downloadName = string.IsNullOrEmpty(nombreVisible) ? nombreFisico : nombreVisible;
            string encodedName = HttpUtility.UrlPathEncode(downloadName);

            context.Response.Clear();
            context.Response.ContentType = string.IsNullOrEmpty(tipo) ? "application/octet-stream" : tipo;
            context.Response.AddHeader("Content-Disposition", $"attachment; filename=\"{encodedName}\"");
            context.Response.TransmitFile(filePath);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
            return;
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            if (debug) { context.Response.ContentType = "application/json"; context.Response.Write("{\"success\":false,\"message\":\"" + HttpUtility.JavaScriptStringEncode(ex.ToString()) + "\"}"); }
            else { context.Response.ContentType = "text/plain"; context.Response.Write("Error interno al procesar la descarga."); }
        }
    }

    public bool IsReusable { get { return false; } }
}
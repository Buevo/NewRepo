using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace Proyecto
{
    /// <summary>
    /// Summary description for DownloadHandler
    /// </summary>
    public class DownloadHandler : IHttpHandler
    {

        public void ProcessRequest(HttpContext context)
        {
            string idProducto = context.Request.QueryString["id"];
            string fileName = context.Request.QueryString["file"];

            if (string.IsNullOrEmpty(idProducto) || string.IsNullOrEmpty(fileName))
            {
                context.Response.StatusCode = 400;
                context.Response.Write("Parámetros inválidos.");
                return;
            }

            // Ruta: ~/ArchivosProductos/{idProducto}/{fileName}
            string filePath = context.Server.MapPath($"~/ArchivosProductos/{idProducto}/{fileName}");

            if (File.Exists(filePath))
            {
                context.Response.ContentType = "application/octet-stream";
                context.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName);
                context.Response.WriteFile(filePath);
                context.Response.End();
            }
            else
            {
                context.Response.StatusCode = 404;
                context.Response.Write("<script>alert('Archivo no encontrado');</script>");
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
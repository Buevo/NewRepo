using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.Script.Serialization;

namespace Proyecto
{
    /// <summary>
    /// Summary description for ListHandler
    /// </summary>
    public class ListHandler : IHttpHandler
    {
        private const string CNX = "CnxVanguardia3";
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                int idProducto = 0;
                int.TryParse(context.Request.QueryString["IdProducto"], out idProducto);
                if (idProducto <= 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "application/json";
                    context.Response.Write("[]");
                    return;
                }

                var files = new List<object>();

                using (var cn = new SqlConnection(ConfigurationManager.ConnectionStrings[CNX].ConnectionString))
                using (var cmd = new SqlCommand("dbo.sp_GetFilesByProduct", cn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@IdProducto", SqlDbType.Int) { Value = idProducto });
                    cn.Open();
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            files.Add(new
                            {
                                IdArchivo = rdr["IdArchivo"],
                                NombreVisible = rdr["NombreVisible"],
                                NombreFisico = rdr["NombreFisico"],
                                TipoArchivo = rdr["TipoArchivo"],
                                TamanoBytes = rdr["TamanoBytes"],
                                FechaSubida = rdr["FechaSubida"],
                                IdUsuarioSubio = rdr["IdUsuarioSubio"]
                            });
                        }
                    }
                }

                context.Response.ContentType = "application/json";
                context.Response.Write(new JavaScriptSerializer().Serialize(files));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.ContentType = "application/json";
                context.Response.Write("[]");
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
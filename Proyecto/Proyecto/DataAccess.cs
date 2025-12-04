using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

namespace Proyecto
{
    public class DataAccess : IDisposable
    {
        private readonly SqlConnection _cn;

        public DataAccess(string connectionStringName)
        {
            var cs = ConfigurationManager.ConnectionStrings[connectionStringName];
            if (cs == null) throw new ArgumentException($"Connection string '{connectionStringName}' not found.");
            _cn = new SqlConnection(cs.ConnectionString);
            _cn.Open();
        }

        public UserModel ValidateUser(string nombreUsuario, byte[] passwordHash)
        {
            using (var cmd = new SqlCommand("dbo.sp_ValidateUser", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario });
                cmd.Parameters.Add(new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32) { Value = passwordHash });

                using (var rdr = cmd.ExecuteReader())
                {
                    if (!rdr.Read()) return null;

                    var user = new UserModel
                    {
                        IdUsuario = rdr.GetInt32(rdr.GetOrdinal("IdUsuario")),
                        NombreUsuario = rdr.GetString(rdr.GetOrdinal("NombreUsuario")),
                        Rol = rdr.GetString(rdr.GetOrdinal("Rol")),
                        Activo = rdr.GetBoolean(rdr.GetOrdinal("Activo"))
                    };
                    return user;
                }
            }
        }

        public void UpdateLastLogin(int idUsuario)
        {
            using (var cmd = new SqlCommand("dbo.sp_UpdateLastLogin", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                cmd.ExecuteNonQuery();
            }
        }

        public void Dispose()
        {
            try { if (_cn != null && _cn.State != ConnectionState.Closed) _cn.Close(); }
            catch { }
        }
    }
}

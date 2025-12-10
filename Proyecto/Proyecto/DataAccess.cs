using System;
using System.Collections.Generic;
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

        /// <summary>
        /// Valida usuario con passwordHash (byte[] - VARBINARY(32)). Retorna UserModel o null.
        /// </summary>
        public UserModel ValidateUser(string nombreUsuario, byte[] passwordHash)
        {
            using (var cmd = new SqlCommand("dbo.sp_ValidateUser", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario ?? (object)DBNull.Value });

                var p = new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32) { Value = (object)passwordHash ?? DBNull.Value };
                cmd.Parameters.Add(p);

                using (var rdr = cmd.ExecuteReader())
                {
                    if (!rdr.Read()) return null;

                    var user = new UserModel
                    {
                        IdUsuario = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : 0,
                        NombreUsuario = rdr["NombreUsuario"] as string ?? "",
                        Rol = rdr["Rol"] as string ?? "",
                        Activo = rdr["Activo"] != DBNull.Value ? Convert.ToBoolean(rdr["Activo"]) : false
                    };
                    return user;
                }
            }
        }

        /// <summary>
        /// Actualiza la fecha de último ingreso.
        /// </summary>
        public void UpdateLastLogin(int idUsuario)
        {
            using (var cmd = new SqlCommand("dbo.sp_UpdateLastLogin", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                cmd.ExecuteNonQuery();
            }
        }

        // ----------------- Métodos para admin_users -----------------

        /// <summary>
        /// Devuelve lista de usuarios (filtro opcional).
        /// </summary>
        public List<UserModel> GetUsers(string filtro)
        {
            var list = new List<UserModel>();
            using (var cmd = new SqlCommand("dbo.sp_GetUsers", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@filtro", SqlDbType.NVarChar, 500) { Value = (object)filtro ?? DBNull.Value });

                using (var rdr = cmd.ExecuteReader())
                {
                    while (rdr.Read())
                    {
                        list.Add(new UserModel
                        {
                            IdUsuario = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : 0,
                            NombreUsuario = rdr["NombreUsuario"] as string ?? "",
                            NombreCompleto = rdr["NombreCompleto"] as string ?? "",
                            Email = rdr["Email"] as string ?? "",
                            Rol = rdr["Rol"] as string ?? "Usuario",
                            Activo = rdr["Activo"] != DBNull.Value ? Convert.ToBoolean(rdr["Activo"]) : false,
                            FechaRegistro = rdr["FechaRegistro"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(rdr["FechaRegistro"]) : null,
                            FechaUltimoIngreso = rdr["FechaUltimoIngreso"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(rdr["FechaUltimoIngreso"]) : null
                        });
                    }
                }
            }
            return list;
        }

        /// <summary>
        /// Obtiene un usuario por Id.
        /// </summary>
        public UserModel GetUserById(int idUsuario)
        {
            using (var cmd = new SqlCommand("dbo.sp_GetUserById", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });

                using (var rdr = cmd.ExecuteReader())
                {
                    if (!rdr.Read()) return null;
                    return new UserModel
                    {
                        IdUsuario = rdr["IdUsuario"] != DBNull.Value ? Convert.ToInt32(rdr["IdUsuario"]) : 0,
                        NombreUsuario = rdr["NombreUsuario"] as string ?? "",
                        NombreCompleto = rdr["NombreCompleto"] as string ?? "",
                        Email = rdr["Email"] as string ?? "",
                        Rol = rdr["Rol"] as string ?? "Usuario",
                        Activo = rdr["Activo"] != DBNull.Value ? Convert.ToBoolean(rdr["Activo"]) : false,
                        FechaRegistro = rdr["FechaRegistro"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(rdr["FechaRegistro"]) : null,
                        FechaUltimoIngreso = rdr["FechaUltimoIngreso"] != DBNull.Value ? (DateTime?)Convert.ToDateTime(rdr["FechaUltimoIngreso"]) : null
                    };
                }
            }
        }

        /// <summary>
        /// Inserta usuario. PasswordHash es byte[] (VARBINARY(32)). Retorna nuevo Id.
        /// </summary>
        public int CreateUser(string nombreUsuario, string nombreCompleto, string email, byte[] passwordHash, string rol, bool activo)
        {
            using (var cmd = new SqlCommand("dbo.sp_CreateUser", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario ?? (object)DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@NombreCompleto", SqlDbType.NVarChar, 200) { Value = (object)nombreCompleto ?? DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@Email", SqlDbType.NVarChar, 200) { Value = (object)email ?? DBNull.Value });

                var pPass = new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32) { Value = (object)passwordHash ?? DBNull.Value };
                cmd.Parameters.Add(pPass);

                cmd.Parameters.Add(new SqlParameter("@Rol", SqlDbType.NVarChar, 50) { Value = (object)rol ?? "Usuario" });
                cmd.Parameters.Add(new SqlParameter("@Activo", SqlDbType.Bit) { Value = activo });

                var outParam = new SqlParameter("@NewIdUsuario", SqlDbType.Int) { Direction = ParameterDirection.Output };
                cmd.Parameters.Add(outParam);

                cmd.ExecuteNonQuery();

                return (outParam.Value == DBNull.Value) ? 0 : Convert.ToInt32(outParam.Value);
            }
        }

        /// <summary>
        /// Actualiza usuario. Si passwordHash == null no cambia la contraseña.
        /// </summary>
        public void UpdateUser(int idUsuario, string nombreUsuario, string nombreCompleto, string email, byte[] passwordHash, string rol, bool activo)
        {
            using (var cmd = new SqlCommand("dbo.sp_UpdateUser", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                cmd.Parameters.Add(new SqlParameter("@NombreUsuario", SqlDbType.NVarChar, 100) { Value = nombreUsuario ?? (object)DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@NombreCompleto", SqlDbType.NVarChar, 200) { Value = (object)nombreCompleto ?? DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@Email", SqlDbType.NVarChar, 200) { Value = (object)email ?? DBNull.Value });

                var pPass = new SqlParameter("@PasswordHash", SqlDbType.VarBinary, 32) { Value = (object)passwordHash ?? DBNull.Value };
                cmd.Parameters.Add(pPass);

                cmd.Parameters.Add(new SqlParameter("@Rol", SqlDbType.NVarChar, 50) { Value = (object)rol ?? "Usuario" });
                cmd.Parameters.Add(new SqlParameter("@Activo", SqlDbType.Bit) { Value = activo });

                cmd.ExecuteNonQuery();
            }
        }

        /// <summary>
        /// Elimina usuario por Id.
        /// </summary>
        public void DeleteUser(int idUsuario)
        {
            using (var cmd = new SqlCommand("dbo.sp_DeleteUser", _cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@IdUsuario", SqlDbType.Int) { Value = idUsuario });
                cmd.ExecuteNonQuery();
            }
        }

        // ------------------------------------------------------

        public void Dispose()
        {
            try { if (_cn != null && _cn.State != ConnectionState.Closed) _cn.Close(); }
            catch { }
        }
    }
}

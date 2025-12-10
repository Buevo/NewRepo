using System;

namespace Proyecto
{
    public class LoginResult
    {
        public bool success { get; set; } = false;
        public int IdUsuario { get; set; }
        public string NombreUsuario { get; set; }
        public string Rol { get; set; }
        public string message { get; set; }
    }

    public class UserModel
    {
        public int IdUsuario { get; set; }
        public string NombreUsuario { get; set; }
        public string NombreCompleto { get; set; }     // nuevo
        public string Email { get; set; }              // nuevo
        public string Rol { get; set; }
        public bool Activo { get; set; }

        // Fechas (opcionales)
        public DateTime? FechaRegistro { get; set; }         // nuevo
        public DateTime? FechaUltimoIngreso { get; set; }    // nuevo
    }
}


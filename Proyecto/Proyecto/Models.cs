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
        public string Rol { get; set; }
        public bool Activo { get; set; }
    }
}

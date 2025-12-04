<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="Proyecto.login" %>

<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Portal Inventario — Login</title>

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">

    <style>
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f6f8fb;
        }
        .card { width: 100%; max-width: 420px; }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="w-100 d-flex align-items-center justify-content-center" style="min-height:100vh;">
        <div class="card shadow-sm">
            <div class="card-body">
                <h4 class="card-title mb-3">Iniciar sesión</h4>

                <div class="mb-3">
                    <label for="txtUsername" class="form-label">Usuario</label>
                    <asp:TextBox ID="txtUsername" runat="server" CssClass="form-control" />
                </div>

                <div class="mb-3">
                    <label for="txtPassword" class="form-label">Contraseña</label>
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="form-control" />
                </div>

                <div class="mb-3 form-check d-flex align-items-center">
                    <asp:CheckBox ID="chkRemember" runat="server" CssClass="form-check-input me-2" />
                    <label class="form-check-label" for="chkRemember">Recordarme por 7 días</label>
                </div>

                <div class="d-grid mb-2">
                    <asp:Button ID="btnLogin" runat="server" CssClass="btn btn-primary" Text="Entrar" OnClick="btnLogin_Click" />
                </div>

                <asp:Literal ID="litLoginMsg" runat="server" EnableViewState="false" />

                <hr />
                <div class="text-center small text-muted">Proyecto: Portal de Inventario</div>
            </div>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
</body>
</html>

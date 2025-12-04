<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="admin_users.aspx.cs" Inherits="Proyecto.admin_users" %>

<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Portal Inventario — Admin Usuarios</title>

    <!-- Bootstrap para estilos -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">

    <style>
        body {
            padding-top: 65px;
        }
    </style>
</head>
<body>

    <!-- NAVBAR SUPERIOR -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">Admin — Usuarios</a>

            <!-- Botones superiores -->
            <div class="d-flex">
                <a class="btn btn-sm btn-primary me-2" href="products.aspx">Ir a Productos</a>
                <button class="btn btn-sm btn-light" id="btnLogout">Cerrar sesión</button>
            </div>
        </div>
    </nav>

    <!-- CONTENIDO PRINCIPAL -->
    <div class="container">

        <!-- Encabezado + Botón -->
        <div class="d-flex justify-content-between align-items-center my-3">
            <h4>Gestión de Usuarios</h4>
            <button class="btn btn-success" id="btnNewUser">+ Nuevo Usuario</button>
        </div>

        <!-- BUSCADOR -->
        <div class="row mb-2">
            <div class="col-md-5">
                <div class="input-group">
                    <input id="txtUserSearch" class="form-control" placeholder="Buscar por usuario o email">
                    <button class="btn btn-outline-secondary" id="btnUserSearch">Buscar</button>
                </div>
            </div>
        </div>

        <!-- TABLA DE USUARIOS -->
        <div class="table-responsive">
            <table class="table table-bordered" id="tblUsers">
                <thead class="table-light">
                    <tr>
                        <th>Usuario</th>
                        <th>Nombre</th>
                        <th>Email</th>
                        <th>Rol</th>
                        <th>Activo</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody></tbody> <!-- Se llena dinamicamente -->
            </table>
        </div>
    </div>

    <!-- MODAL PARA CREAR/EDITAR USUARIOS -->
    <div class="modal fade" id="modalUser" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <form class="modal-content" id="formUser">

                <div class="modal-header">
                    <h5 class="modal-title" id="modalUserTitle">Nuevo Usuario</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>

                <div class="modal-body">

                    <!-- Campo oculto para ID -->
                    <input type="hidden" id="userId" value="0" />

                    <!-- Nombre de usuario -->
                    <div class="mb-3">
                        <label class="form-label">Nombre de usuario</label>
                        <input id="userName" class="form-control" required />
                    </div>

                    <!-- Nombre completo -->
                    <div class="mb-3">
                        <label class="form-label">Nombre completo</label>
                        <input id="userFullName" class="form-control" />
                    </div>

                    <!-- Email -->
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <input id="userEmail" class="form-control" type="email" />
                    </div>

                    <!-- Contraseña -->
                    <div class="mb-3">
                        <label class="form-label">Contraseña</label>
                        <input id="userPassword" class="form-control" type="password" />
                        <div class="form-text">Dejar vacío para no cambiar la contraseña en edición.</div>
                    </div>

                    <!-- Rol -->
                    <div class="mb-3">
                        <label class="form-label">Rol</label>
                        <select id="userRole" class="form-select">
                            <option value="Usuario">Usuario</option>
                            <option value="Admin">Admin</option>
                        </select>
                    </div>

                    <!-- Activo -->
                    <div class="form-check mb-2">
                        <input type="checkbox" id="userActive" class="form-check-input" checked />
                        <label class="form-check-label" for="userActive">Activo</label>
                    </div>

                    <!-- Mensajes del formulario -->
                    <div id="userFormMsg" class="small text-danger"></div>
                </div>

                <div class="modal-footer">
                    <button class="btn btn-secondary" type="button" data-bs-dismiss="modal">Cancelar</button>
                    <button class="btn btn-primary" type="submit">Guardar</button>
                </div>

            </form>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>

    <!-- SCRIPT PRINCIPAL -->
    <script>

        // Ruta para futuros llamados a API
        const API_USERS = '/Users.asmx';

        // Elementos del DOM reutilizados
        const usersTblBody = document.querySelector('#tblUsers tbody');
        const modalUserEl = document.getElementById('modalUser');
        const bsModalUser = new bootstrap.Modal(modalUserEl);

        // Lista de usuarios simulada
        let users = [
            { IdUsuario: 1, NombreUsuario: 'admin', NombreCompleto: 'Administrador', Email: 'admin@dom.local', Rol: 'Admin', Activo: true },
            { IdUsuario: 2, NombreUsuario: 'jdoe', NombreCompleto: 'Juan Doe', Email: 'jdoe@dom.local', Rol: 'Usuario', Activo: true }
        ];

        /**
         * Renderiza la tabla de usuarios en pantalla.
         */
        function renderUsers(list) {
            usersTblBody.innerHTML = '';

            if (!list.length) {
                usersTblBody.innerHTML = '<tr><td colspan="6" class="text-muted">No hay usuarios</td></tr>';
                return;
            }

            for (const u of list) {
                const tr = document.createElement('tr');

                tr.innerHTML = `
        <td>${escapeHtml(u.NombreUsuario)}</td>
        <td>${escapeHtml(u.NombreCompleto || '')}</td>
        <td>${escapeHtml(u.Email || '')}</td>
        <td>${escapeHtml(u.Rol)}</td>
        <td>${u.Activo ? 'Sí' : 'No'}</td>
        <td>
          <button class="btn btn-sm btn-warning" onclick="editUser(${u.IdUsuario})">Editar</button>
          <button class="btn btn-sm btn-danger" onclick="deleteUser(${u.IdUsuario})">Eliminar</button>
        </td>`;

                usersTblBody.appendChild(tr);
            }
        }

        // Inicializar tabla
        renderUsers(users);

        /**
         * Buscar usuarios por nombre o email.
         */
        document.getElementById('btnUserSearch').addEventListener('click', () => {
            const q = document.getElementById('txtUserSearch').value.trim().toLowerCase();

            if (!q) {
                renderUsers(users);
                return;
            }

            renderUsers(
                users.filter(u =>
                    `${u.NombreUsuario} ${u.Email}`.toLowerCase().includes(q)
                )
            );
        });

        /**
         * Abrir modal para crear usuario nuevo.
         */
        document.getElementById('btnNewUser').addEventListener('click', () => {

            document.getElementById('userId').value = 0;
            document.getElementById('userName').value = '';
            document.getElementById('userFullName').value = '';
            document.getElementById('userEmail').value = '';
            document.getElementById('userPassword').value = '';
            document.getElementById('userRole').value = 'Usuario';
            document.getElementById('userActive').checked = true;
            document.getElementById('modalUserTitle').innerText = 'Nuevo Usuario';
            document.getElementById('userFormMsg').innerText = '';

            bsModalUser.show();
        });

        /**
         * Guardar o actualizar usuario.
         */
        document.getElementById('formUser').addEventListener('submit', (e) => {
            e.preventDefault();

            const id = Number(document.getElementById('userId').value);
            const nombreUsuario = document.getElementById('userName').value.trim();
            const nombreCompleto = document.getElementById('userFullName').value.trim();
            const email = document.getElementById('userEmail').value.trim();
            const password = document.getElementById('userPassword').value;
            const rol = document.getElementById('userRole').value;
            const activo = document.getElementById('userActive').checked;

            if (!nombreUsuario) {
                document.getElementById('userFormMsg').innerText = 'El nombre de usuario es obligatorio.';
                return;
            }

            // Crear nuevo usuario
            if (id === 0) {
                const newId = users.length ? Math.max(...users.map(u => u.IdUsuario)) + 1 : 1;

                users.push({
                    IdUsuario: newId,
                    NombreUsuario: nombreUsuario,
                    NombreCompleto: nombreCompleto,
                    Email: email,
                    Rol: rol,
                    Activo: activo
                });
            }

            // Editar usuario existente
            else {
                const idx = users.findIndex(u => u.IdUsuario === id);
                if (idx >= 0) {
                    users[idx].NombreUsuario = nombreUsuario;
                    users[idx].NombreCompleto = nombreCompleto;
                    users[idx].Email = email;
                    users[idx].Rol = rol;
                    users[idx].Activo = activo;
                }
            }

            renderUsers(users);
            bsModalUser.hide();
        });

        /**
         * Cargar datos en el modal para editar usuario.
         */
        function editUser(id) {
            const u = users.find(x => x.IdUsuario === id);
            if (!u) { alert('Usuario no encontrado'); return; }

            document.getElementById('userId').value = u.IdUsuario;
            document.getElementById('userName').value = u.NombreUsuario;
            document.getElementById('userFullName').value = u.NombreCompleto;
            document.getElementById('userEmail').value = u.Email;
            document.getElementById('userPassword').value = '';
            document.getElementById('userRole').value = u.Rol;
            document.getElementById('userActive').checked = !!u.Activo;
            document.getElementById('modalUserTitle').innerText = 'Editar Usuario';
            document.getElementById('userFormMsg').innerText = '';

            bsModalUser.show();
        }

        /**
         * Eliminar usuario por ID.
         */
        function deleteUser(id) {
            if (!confirm('Eliminar usuario?')) return;

            users = users.filter(u => u.IdUsuario !== id);
            renderUsers(users);
        }

        /**
         * Cerrar sesión redirigiendo a login.
         */
        document.getElementById('btnLogout').addEventListener('click', () => {
            window.location.href = 'login.aspx';
        });

        /**
         * Evitar inyección HTML.
         */
        function escapeHtml(str = '') {
            return String(str)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
        }

    </script>

</body>
</html>


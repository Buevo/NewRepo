<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="admin_users.aspx.cs" Inherits="Proyecto.admin_users" %>

<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Portal Inventario — Admin Usuarios</title>

    <!-- Bootstrap para estilos -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet"
          crossorigin="anonymous">

    <style>
        body {
            padding-top: 65px;
        }
        .small-muted { font-size: 0.9rem; color: #666; }
    </style>
</head>
<body>

    <!-- NAVBAR SUPERIOR -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">Admin — Usuarios</a>

            <!-- Botones superiores -->
            <div class="d-flex">
                <a class="btn btn-sm btn-primary me-2" href="products.aspx">Regresar</a>
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
                    <button class="btn btn-light" id="btnUserClear">Limpiar</button>
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
                <tbody></tbody> <!-- Se llena dinámicamente -->
            </table>
        </div>
    </div>

    <!-- MODAL PARA CREAR/EDITAR USUARIOS -->
    <div class="modal fade" id="modalUser" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <form class="modal-content" id="formUser" novalidate>

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
                        <input id="userName" class="form-control" maxlength="20" required />
                        <div class="form-text small-muted">Máx. 20 caracteres.</div>
                    </div>

                    <!-- Nombre completo -->
                    <div class="mb-3">
                        <label class="form-label">Nombre completo</label>
                        <input id="userFullName" class="form-control" required />
                    </div>

                    <!-- Email -->
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <input id="userEmail" class="form-control" type="email" required />
                        <div class="form-text small-muted">Debe terminar en <code>@dominio.com</code>.</div>
                    </div>

                    <!-- Contraseña -->
                    <div class="mb-3">
                        <label class="form-label">Contraseña</label>
                        <input id="userPassword" class="form-control" type="password" />
                        <div class="form-text small-muted">Al crear es obligatoria. Debe incluir al menos 1 mayúscula, 1 número y 1 carácter especial. Mínimo 8 caracteres.</div>
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

    <!-- SCRIPT PRINCIPAL (usa WebMethods en admin_users.aspx.cs) -->
    <script>
        (function () {
            const API = 'admin_users.aspx';

            // Elementos DOM
            const usersTblBody = document.querySelector('#tblUsers tbody');
            const modalUserEl = document.getElementById('modalUser');
            const bsModalUser = new bootstrap.Modal(modalUserEl);

            // Buscar / estado
            const txtSearch = document.getElementById('txtUserSearch');
            document.getElementById('btnUserSearch').addEventListener('click', loadUsers);
            document.getElementById('btnUserClear').addEventListener('click', function () { txtSearch.value = ''; loadUsers(); });

            // New user button
            document.getElementById('btnNewUser').addEventListener('click', function () {
                clearUserForm();
                document.getElementById('modalUserTitle').innerText = 'Nuevo Usuario';
                bsModalUser.show();
            });

            // Escape html helper
            function escapeHtml(str = '') {
                return String(str).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
            }

            // Render users list
            function renderUsers(list) {
                usersTblBody.innerHTML = '';
                if (!list || !list.length) {
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
                            <button class="btn btn-sm btn-warning me-1" data-id="${u.IdUsuario}" data-action="edit">Editar</button>
                            <button class="btn btn-sm btn-danger" data-id="${u.IdUsuario}" data-action="delete">Eliminar</button>
                        </td>`;
                    usersTblBody.appendChild(tr);
                }
            }

            // Delegación: editar / eliminar
            usersTblBody.addEventListener('click', function (ev) {
                const btn = ev.target.closest('button');
                if (!btn) return;
                const id = Number(btn.getAttribute('data-id'));
                const action = btn.getAttribute('data-action');
                if (action === 'edit') editUser(id);
                if (action === 'delete') deleteUser(id);
            });

            // Load users (from WebMethod)
            function loadUsers() {
                const filtro = txtSearch.value.trim();
                fetch(API + '/GetUsers', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ filtro: filtro })
                })
                    .then(r => r.json())
                    .then(resp => {
                        const payload = resp && resp.d ? resp.d : resp;
                        if (!payload || !payload.success) {
                            alert('No se pudieron cargar usuarios: ' + (payload && payload.message ? payload.message : 'Error'));
                            renderUsers([]);
                            return;
                        }
                        renderUsers(payload.data || []);
                    })
                    .catch(err => {
                        console.error('GetUsers error', err);
                        alert('Error al cargar usuarios. Revisa la consola.');
                    });
            }

            // Clear form helper
            function clearUserForm() {
                document.getElementById('userId').value = 0;
                document.getElementById('userName').value = '';
                document.getElementById('userFullName').value = '';
                document.getElementById('userEmail').value = '';
                document.getElementById('userPassword').value = '';
                document.getElementById('userRole').value = 'Usuario';
                document.getElementById('userActive').checked = true;
                document.getElementById('userFormMsg').innerText = '';
            }

            // Edit user -> load data via WebMethod
            function editUser(id) {
                fetch(API + '/GetUserById', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ idUsuario: id })
                })
                    .then(r => r.json())
                    .then(resp => {
                        const payload = resp && resp.d ? resp.d : resp;
                        if (!payload || !payload.success) { alert('No se pudo obtener usuario'); return; }
                        const u = payload.data;
                        document.getElementById('userId').value = u.IdUsuario;
                        document.getElementById('userName').value = u.NombreUsuario || '';
                        document.getElementById('userFullName').value = u.NombreCompleto || '';
                        document.getElementById('userEmail').value = u.Email || '';
                        
                        document.getElementById('userPassword').value = '';
                        document.getElementById('userRole').value = u.Rol || 'Usuario';
                        document.getElementById('userActive').checked = !!u.Activo;
                        document.getElementById('modalUserTitle').innerText = 'Editar Usuario';
                        document.getElementById('userFormMsg').innerText = '';
                        bsModalUser.show();
                    })
                    .catch(err => { console.error('GetUserById', err); alert('Error al obtener usuario'); });
            }

            // Delete user
            function deleteUser(id) {
                if (!confirm('¿Eliminar usuario?')) return;
                fetch(API + '/DeleteUser', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ idUsuario: id })
                })
                    .then(r => r.json())
                    .then(resp => {
                        const payload = resp && resp.d ? resp.d : resp;
                        if (!payload || !payload.success) {
                            alert('No se pudo eliminar: ' + (payload && payload.message ? payload.message : 'Error'));
                            return;
                        }
                        loadUsers();
                    })
                    .catch(err => { console.error('DeleteUser', err); alert('Error al eliminar usuario'); });
            }

            // --- Función de validación ---
            function validateUserForm({ id, nombreUsuario, nombreCompleto, email, password }) {
                const msg = [];

                // Requeridos
                if (!nombreUsuario) msg.push('El nombre de usuario es obligatorio.');
                if (!nombreCompleto) msg.push('El nombre completo es obligatorio.');
                if (!email) msg.push('El email es obligatorio.');

                // Nombre usuario longitud
                if (nombreUsuario && nombreUsuario.length > 20) msg.push('El nombre de usuario no debe exceder 20 caracteres.');

                // Email: debe terminar en @dominio.com
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (email && !emailRegex.test(email)) msg.push('Debe ser un correo válido.');

                // Contraseña:
                // - Si estamos creando (id === 0) la contraseña es obligatoria.
                // - Si estamos editando (id !== 0) la contraseña es opcional; validamos sólo si se ingresó.
                const pwdRequired = (id === 0);
                if (pwdRequired && !password) {
                    msg.push('La contraseña es obligatoria al crear un usuario.');
                }
                if (password) {
                    // Requisitos: al menos una mayúscula, un número y un carácter especial.
                    const pwdRegex = /^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$/;
                    if (!pwdRegex.test(password)) {
                        msg.push('La contraseña debe incluir al menos: una letra mayúscula, un número y un signo (carácter especial).');
                    }
                    // Recomendación de longitud mínima
                    if (password.length < 8) {
                        msg.push('La contraseña debe tener al menos 8 caracteres');
                    }
                }

                return {
                    ok: msg.length === 0,
                    message: msg.join(' ')
                };
            }

            // Submit form (create / update)
            // Submit form (create / update) - handler que ENVÍA password siempre (null si está vacío)
            document.getElementById('formUser').addEventListener('submit', function (e) {
                e.preventDefault();

                const id = Number(document.getElementById('userId').value || 0);
                const nombreUsuario = document.getElementById('userName').value.trim();
                const nombreCompleto = document.getElementById('userFullName').value.trim();
                const email = document.getElementById('userEmail').value.trim();
                const password = document.getElementById('userPassword').value;
                const rol = document.getElementById('userRole').value;
                const activo = document.getElementById('userActive').checked;
                const userFormMsgEl = document.getElementById('userFormMsg');

                // Validación cliente
                const v = validateUserForm({ id, nombreUsuario, nombreCompleto, email, password });
                if (!v.ok) {
                    userFormMsgEl.innerText = v.message;
                    return;
                } else {
                    userFormMsgEl.innerText = '';
                }

                // Preparar payload: incluir password siempre; si está vacío enviamos null
                const payload = {
                    nombreUsuario: nombreUsuario,
                    nombreCompleto: nombreCompleto,
                    email: email,
                    rol: rol,
                    activo: activo,
                    password: (password && password.length > 0) ? password : null
                };

                if (id !== 0) {
                    payload.idUsuario = id;
                }

                // Depuración opcional (quita en producción)
                console.log('Enviando payload a servidor:', (id === 0 ? API + '/CreateUser' : API + '/UpdateUser'), payload);

                const endpoint = (id === 0) ? '/CreateUser' : '/UpdateUser';

                fetch(API + endpoint, {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                })
                    .then(r => r.json())
                    .then(resp => {
                        const payloadResp = resp && resp.d ? resp.d : resp;
                        if (!payloadResp || !payloadResp.success) {
                            userFormMsgEl.innerText = (payloadResp && payloadResp.message) || 'Error';
                            return;
                        }
                        bsModalUser.hide();
                        loadUsers();
                    })
                    .catch(err => {
                        console.error(endpoint, err);
                        userFormMsgEl.innerText = (id === 0) ? 'Error al crear usuario.' : 'Error al actualizar usuario.';
                    });
            });


            // Inicializar
            loadUsers();
        })();
    </script>

</body>
</html>

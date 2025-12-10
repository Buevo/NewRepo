<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="products.aspx.cs" Inherits="Proyecto.products" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <title>Productos - Portal Inventario</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <style>
        .table-actions {
            width: 140px;
        }

        .cursor-pointer {
            cursor: pointer;
        }
    </style>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <div class="container mt-4">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>Productos</h2>
            <div>
                <button id="btnAddProduct" class="btn btn-primary">Nuevo producto</button>
                <a href="admin_users.aspx" class="btn btn-secondary">Ir a Usuarios</a>
                <button id="btnLogout" class="btn btn-danger">Cerrar sesión</button>
            </div>
        </div>

        <div class="form-row mb-3">
            <div class="col-md-6">
                <input id="txtFilter" class="form-control" placeholder="Buscar por código o descripción..." />
            </div>
            <div class="col-auto">
                <button id="btnSearch" class="btn btn-secondary">Buscar</button>
                <button id="btnClear" class="btn btn-light">Limpiar</button>
            </div>
        </div>

        <div id="alertPlaceholder"></div>

        <table class="table table-striped table-bordered" id="tblProducts">
            <thead class="thead-light">
                <tr>
                    <th>Código</th>
                    <th>Descripción</th>
                    <th class="text-right">Precio</th>
                    <th class="text-right">Stock</th>
                    <th>Activo</th>
                    <th class="table-actions">Acciones</th>
                </tr>
            </thead>
            <tbody>
                <!-- filas por JS -->
            </tbody>
        </table>
    </div>

    <!-- Modal Agregar/Editar -->
    <div class="modal fade" id="productModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 id="modalTitle" class="modal-title">Nuevo producto</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Cerrar">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form id="frmProduct">
                        <input type="hidden" id="hfIdProducto" value="0" />
                        <div class="form-group">
                            <label for="txtCodigo">Código</label>
                            <input id="txtCodigo" class="form-control" maxlength="50" required />
                        </div>
                        <div class="form-group">
                            <label for="txtDescripcion">Descripción</label>
                            <textarea id="txtDescripcion" class="form-control" maxlength="500" required></textarea>
                        </div>
                        <div class="form-row">
                            <div class="form-group col">
                                <label for="txtPrecio">Precio</label>
                                <input id="txtPrecio" class="form-control" type="number" step="0.01" min="0" value="0" />
                            </div>
                            <div class="form-group col">
                                <label for="txtStock">Stock</label>
                                <input id="txtStock" class="form-control" type="number" min="0" value="0" />
                            </div>
                        </div>
                    </form>
                    <div id="modalMsg"></div>
                </div>
                <div class="modal-footer">
                    <button id="btnSaveProduct" class="btn btn-primary">Guardar</button>
                    <button class="btn btn-secondary" data-dismiss="modal">Cancelar</button>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="filesModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 id="filesModalLabel" class="modal-title">Archivos</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Cerrar">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="hfFileProductoId" value="0" />
                    <div class="mb-3">
                        <form id="frmUploadFile" onsubmit="return false;">
                            <div class="form-row align-items-center">
                                <div class="col-auto">
                                    <input id="fileInput" type="file" class="form-control-file" />
                                </div>
                                <div class="col">
                                    <input id="txtNombreVisible" type="text" class="form-control" placeholder="Nombre visible (opcional)" />
                                </div>
                                <div class="col-auto">
                                    <button id="btnUploadFile" class="btn btn-primary">Subir</button>
                                </div>
                            </div>
                        </form>
                    </div>

                    <table class="table table-sm table-bordered" id="tblFiles">
                        <thead class="thead-light">
                            <tr>
                                <th>Nombre</th>
                                <th>Tamaño (bytes)</th>
                                <th>Fecha</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!-- llenado por JS -->
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS (opcional) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>

    <script>

        function downloadFiles(idArchivo, fileName) {
            const url = `DownloadHandler.ashx?id=${idArchivo}&file=${encodeURIComponent(fileName)}`;
            window.location.href = url;
        }

        $(function () {
            // Forzar envío de cookies/credenciales (ayuda si hay problemas con SameSite / credenciales)
            $.ajaxSetup({ xhrFields: { withCredentials: true } });

            // referencias DOM (scope del ready)
            const $tbl = $("#tblProducts tbody");
            const $filter = $("#txtFilter");
            const $modal = $("#productModal");
            const $frm = $("#frmProduct");
            const $hfId = $("#hfIdProducto");

            // Helpers
            function escapeHtml(text) { if (text == null) return ""; return $('<div />').text(text).html(); }
            function showAlert(msg, type) {
                $("#alertPlaceholder").html(`<div class="alert ${type}">${msg}</div>`);
                setTimeout(() => $("#alertPlaceholder").html(""), 5000);
            }

            // Carga productos
            function loadProducts() {
                const filtro = $filter.val();
                $.ajax({
                    url: "products.aspx/GetProducts",
                    method: "POST",
                    contentType: "application/json; charset=utf-8",
                    data: JSON.stringify({ filtro: filtro }),
                    success: function (res) {
                        // ASP.NET returns wrapper in res.d
                        const payload = (res && res.d) ? res.d : (res || {});
                        if (!payload.success) {
                            showAlert("No se pudieron cargar productos: " + (payload.message || ''), "alert-danger");
                            renderTable([]);
                            return;
                        }
                        renderTable(payload.data || []);
                    },
                    error: function (xhr, status, err) {
                        console.error("GetProducts ERROR", xhr.status, xhr.responseText);
                        showAlert("Error al cargar productos (" + xhr.status + ")", "alert-danger");
                        renderTable([]);
                    }
                });
            }

            function renderTable(items) {
                $tbl.empty();
                if (!items || items.length === 0) {
                    $tbl.append(`<tr><td colspan="6" class="text-center">No hay productos</td></tr>`);
                    return;
                }
                items.forEach(i => {
                    const tr = $("<tr>");
                    tr.append(`<td>${escapeHtml(i.Codigo)}</td>`);
                    tr.append(`<td>${escapeHtml(i.Descripcion)}</td>`);
                    tr.append(`<td class="text-right">${(i.Precio || 0).toFixed(2)}</td>`);
                    tr.append(`<td class="text-right">${i.Stock}</td>`);
                    tr.append(`<td>${i.Activo ? "Sí" : "No"}</td>`);
                    const actions = $(`
                <td>
                    <button class="btn btn-sm btn-secondary btn-files mr-1" data-id="${i.IdProducto}" data-nombre="${escapeHtml(i.Descripcion)}">Archivos</button>
                    <button class="btn btn-sm btn-info btn-edit mr-1" data-id="${i.IdProducto}">Editar</button>
                    <button class="btn btn-sm btn-danger btn-delete" data-id="${i.IdProducto}">Eliminar</button>
                </td>
                `);
                    tr.append(actions);
                    $tbl.append(tr);
                });
            }

            // Eventos UI: buscar / limpiar
            $("#btnSearch").on('click', loadProducts);
            $("#btnClear").on('click', function () { $filter.val(''); loadProducts(); });

            // Nuevo producto
            $("#btnAddProduct").on('click', function () {
                $hfId.val(0);
                $("#txtCodigo").val('');
                $("#txtDescripcion").val('');
                $("#txtPrecio").val('0.00');
                $("#txtStock").val('0');
                $("#modalTitle").text("Nuevo producto");
                $("#modalMsg").html('');
                $modal.modal('show');
            });

            // Guardar producto (crear o actualizar)
            $("#btnSaveProduct").on('click', function () {
                const id = parseInt($hfId.val() || "0", 10);
                const codigo = $("#txtCodigo").val().trim();
                const descripcion = $("#txtDescripcion").val().trim();
                const precio = parseFloat($("#txtPrecio").val() || 0);
                const stock = parseInt($("#txtStock").val() || 0, 10);

                if (!codigo || !descripcion) {
                    $("#modalMsg").html(`<div class="alert alert-warning">Código y descripción son obligatorios.</div>`);
                    return;
                }

                if (id === 0) {
                    $.ajax({
                        url: "products.aspx/CreateProduct",
                        method: "POST",
                        contentType: "application/json; charset=utf-8",
                        data: JSON.stringify({ codigo: codigo, descripcion: descripcion, precio: precio, stock: stock }),
                        success: function (res) {
                            const r = res && res.d ? res.d : res;
                            if (r.success) {
                                $modal.modal('hide');
                                showAlert("Producto creado.", "alert-success");
                                loadProducts();
                            } else {
                                $("#modalMsg").html(`<div class="alert alert-danger">${r.message || 'Error'}</div>`);
                            }
                        },
                        error: function (xhr) {
                            $("#modalMsg").html(`<div class="alert alert-danger">Error al crear producto (${xhr.status})</div>`);
                        }
                    });
                } else {
                    $.ajax({
                        url: "products.aspx/UpdateProduct",
                        method: "POST",
                        contentType: "application/json; charset=utf-8",
                        data: JSON.stringify({ idProducto: id, codigo: codigo, descripcion: descripcion, precio: precio, stock: stock }),
                        success: function (res) {
                            const r = res && res.d ? res.d : res;
                            if (r.success) {
                                $modal.modal('hide');
                                showAlert("Producto actualizado.", "alert-success");
                                loadProducts();
                            } else {
                                $("#modalMsg").html(`<div class="alert alert-danger">${r.message || 'Error'}</div>`);
                            }
                        },
                        error: function (xhr) {
                            $("#modalMsg").html(`<div class="alert alert-danger">Error al actualizar producto (${xhr.status})</div>`);
                        }
                    });
                }
            });

            // Delegación: editar / eliminar / archivos
            $tbl.on('click', '.btn-edit', function () {
                const id = $(this).data('id');
                $.ajax({
                    url: 'products.aspx/GetProductById',
                    method: 'POST',
                    contentType: 'application/json; charset=utf-8',
                    data: JSON.stringify({ idProducto: id }),
                    success: function (res) {
                        const r = res && res.d ? res.d : res;
                        if (!r.success) { showAlert("No se pudo obtener producto.", "alert-danger"); return; }
                        const p = r.data;
                        $hfId.val(p.IdProducto);
                        $("#txtCodigo").val(p.Codigo);
                        $("#txtDescripcion").val(p.Descripcion);
                        $("#txtPrecio").val((p.Precio || 0).toFixed(2));
                        $("#txtStock").val(p.Stock || 0);
                        $("#modalTitle").text("Editar producto");
                        $("#modalMsg").html('');
                        $modal.modal('show');
                    },
                    error: function (xhr) { showAlert("Error al obtener producto (" + xhr.status + ")", "alert-danger"); }
                });
            });

            $tbl.on('click', '.btn-delete', function () {
                const id = $(this).data('id');
                if (!confirm("¿Eliminar este producto? Esta acción no se puede deshacer.")) return;
                $.ajax({
                    url: 'products.aspx/DeleteProduct',
                    method: 'POST',
                    contentType: 'application/json; charset=utf-8',
                    data: JSON.stringify({ idProducto: id }),
                    success: function (res) {
                        const r = res && res.d ? res.d : res;
                        if (r.success) {
                            showAlert("Producto eliminado.", "alert-success");
                            loadProducts();
                        } else {
                            showAlert("No se pudo eliminar: " + (r.message || ''), "alert-danger");
                        }
                    },
                    error: function (xhr) { showAlert("Error al eliminar producto (" + xhr.status + ")", "alert-danger"); }
                });
            });

            $tbl.on('click', '.btn-files', function () {
                const id = $(this).data('id');
                const nombre = $(this).data('nombre') || '';
                openFilesModal(id, nombre);
            });

            /* ================= Gestión de archivos ================= */

            // funciones que deben estar disponibles globalmente (porque se usan en onclick generados en HTML)
            // downloadFile robusto usando fetch
            window.downloadFile = function (idArchivo) {
                if (!idArchivo) { alert('IdArchivo inválido'); return; }

                const url = '/DownloadHandler.ashx';

                // Post con FormData (como UploadHandler)
                const fd = new FormData();
                fd.append('idArchivo', idArchivo);

                fetch(url, {
                    method: 'POST',
                    body: fd,
                    credentials: 'same-origin' // enviar cookies de sesión
                })
                    .then(async response => {
                        // Si falla, tratar de parsear JSON con mensaje
                        if (!response.ok) {
                            const txt = await response.text();
                            try {
                                const parsed = JSON.parse(txt);
                                alert('Error: ' + (parsed.message || txt));
                                console.error('Download error (json):', parsed);
                            } catch (e) {
                                alert('Error al descargar (HTTP ' + response.status + ')');
                                console.error('Download error (text):', txt);
                            }
                            return;
                        }

                        // Si el handler devolvió JSON (por ejemplo debug o error), mostrarlo
                        const ct = response.headers.get('Content-Type') || '';
                        if (ct.indexOf('application/json') !== -1) {
                            const data = await response.json();
                            alert('Respuesta: ' + (data.message || JSON.stringify(data)));
                            console.log('Download JSON response:', data);
                            return;
                        }

                        // Es binario: construir blob y forzar descarga
                        const blob = await response.blob();
                        const disposition = response.headers.get('Content-Disposition') || '';
                        let filename = 'archivo';

                        // Extraer filename del header si viene
                        const match = /filename\*?=(?:UTF-8'')?["']?([^;"']+)/i.exec(disposition);
                        if (match && match[1]) {
                            try { filename = decodeURIComponent(match[1]); } catch (e) { filename = match[1]; }
                        } else {
                            filename = 'archivo_' + idArchivo;
                        }

                        const link = document.createElement('a');
                        const blobUrl = window.URL.createObjectURL(blob);
                        link.href = blobUrl;
                        link.download = filename;
                        document.body.appendChild(link);
                        link.click();
                        link.remove();
                        window.URL.revokeObjectURL(blobUrl);
                    })
                    .catch(err => {
                        console.error('Fetch download failed', err);
                        alert('Error al descargar el archivo. Revisa la consola.');
                    });
            };


            window.deleteFile = function (idArchivo) {
                if (!confirm('¿Eliminar archivo?')) return;
                fetch('DeleteHandler.ashx?idArchivo=' + encodeURIComponent(idArchivo), { method: 'POST', credentials: 'same-origin' })
                    .then(r => r.json())
                    .then(res => {
                        if (res && res.success) {
                            alert(res.message || 'Eliminado');
                            const idProducto = $("#hfFileProductoId").val();
                            loadFilesByProduct(idProducto);
                        } else {
                            alert('Error: ' + (res && res.message ? res.message : 'Error'));
                        }
                    })
                    .catch(err => { alert('Error al eliminar'); console.error(err); });
            };

            // Abrir modal de archivos
            function openFilesModal(idProducto, nombreProducto) {
                $("#filesModalLabel").text("Archivos de: " + (nombreProducto || ("#" + idProducto)));
                $("#hfFileProductoId").val(idProducto);
                $("#fileInput").val('');
                $("#txtNombreVisible").val('');
                loadFilesByProduct(idProducto);
                $("#filesModal").modal('show');
            }

            // Cargar lista de archivos
            function loadFilesByProduct(idProducto) {
                const tbody = $("#tblFiles tbody");
                tbody.html('<tr><td colspan="4" class="text-center">Cargando...</td></tr>');
                fetch('ListFiles.ashx?IdProducto=' + encodeURIComponent(idProducto), { credentials: 'same-origin' })
                    .then(r => {
                        if (!r.ok) throw new Error('HTTP ' + r.status);
                        return r.json();
                    })
                    .then(data => {
                        tbody.empty();
                        if (!data || data.length === 0) {
                            tbody.html('<tr><td colspan="4" class="text-center">No hay archivos.</td></tr>');
                            return;
                        }
                        data.forEach(f => {
                            const tr = $('<tr>');
                            tr.append(`<td>${escapeHtml(f.NombreVisible)}</td>`);
                            tr.append(`<td>${f.TamanoBytes || 0}</td>`);
                            tr.append(`<td>${f.FechaSubida || ''}</td>`);
                            const actions = $('<td>');
                            // usamos funciones globales window.downloadFile / window.deleteFile
                            actions.append(`
   <button class="btn btn-sm btn-outline-primary mr-1"
           onclick="downloadFiles(${idProducto}, '${f.NombreFisico}')">
       Descargar
   </button>
`);
                            console.log(`ID:${idProducto} ${f.NombreFisico}`);
                            actions.append(`<button class="btn btn-sm btn-outline-danger" onclick="deleteFile(${f.IdArchivo})">Eliminar</button>`);
                            tr.append(actions);
                            tbody.append(tr);
                        });
                    })
                    .catch(err => {
                        tbody.html('<tr><td colspan="4" class="text-center text-danger">Error al cargar archivos.</td></tr>');
                        console.error(err);
                    });
            }

            // Upload via FormData
            $("#btnUploadFile").on('click', function (e) {
                e.preventDefault();
                const input = document.getElementById('fileInput');
                if (!input.files || input.files.length === 0) { alert('Selecciona un archivo.'); return; }
                const idProducto = $("#hfFileProductoId").val();
                const fd = new FormData();
                fd.append('IdProducto', idProducto);
                fd.append('NombreVisible', $("#txtNombreVisible").val() || input.files[0].name);
                fd.append('file', input.files[0]);

                fetch('UploadHandler.ashx', { method: 'POST', body: fd, credentials: 'same-origin' })
                    .then(r => {
                        if (!r.ok) throw new Error('HTTP ' + r.status);
                        return r.json();
                    })
                    .then(res => {
                        if (res && res.success) {
                            alert(res.message || 'Subido');
                            input.value = '';
                            loadFilesByProduct(idProducto);
                        } else {
                            alert('Error al subir: ' + (res && res.message ? res.message : 'Error'));
                        }
                    })
                    .catch(err => {
                        alert('Error al subir archivo');
                        console.error(err);
                    });
            });

            // Inicializar carga
            loadProducts();
        }); // end $(function)

        $("#btnLogout").on("click", function () {
            if (!confirm('¿Cerrar sesión y volver al login?')) return;

            fetch('products.aspx/Logout', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/json' },
                body: '{}'
            })
                .then(async res => {
                    if (!res.ok) {
                        const t = await res.text();
                        console.error('Logout HTTP error', res.status, t);
                        alert('Error al cerrar sesión (HTTP ' + res.status + '). Revisa la consola.');
                        return;
                    }
                    const payload = await res.json();
                    const result = payload && payload.d ? payload.d : payload;
                    if (!result || !result.success) {
                        alert('No se pudo cerrar sesión: ' + (result && result.message ? result.message : 'Error desconocido'));
                        return;
                    }
                    try {
                        document.cookie.split(";").forEach(function (c) {
                            if (!c) return;
                            var parts = c.split("=");
                            var name = parts.shift().trim();
                            if (!name) return;
                            document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/;";
                            document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; domain=" + location.hostname + ";";
                        });
                    } catch (e) {
                        console.warn('No se pudieron borrar cookies desde JS (esto puede ser normal si son HttpOnly):', e);
                    }
                    window.location.href = 'login.aspx';
                })
                .catch(err => {
                    console.error('Logout failed', err);
                    alert('Error al cerrar sesión. Revisa la consola.');
                });
        });


    </script>





</body>
</html>

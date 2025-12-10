<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="user_products.aspx.cs" Inherits="Proyecto.user_products" %>

<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <title>Productos — Usuario</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <style>
        body { padding: 24px; }
        .card-columns { column-count: 2; }
        .product-card { margin-bottom: 18px; }
        .product-meta { font-size: 0.95rem; color: #555; }
        .card-actions { margin-top: 8px; }
        .modal-lg { max-width: 900px; }
    </style>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <div class="container">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>Productos</h2>
            <div>
                <button id="btnLogout" class="btn btn-danger">Cerrar sesión</button>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-md-6">
                <input id="txtFilter" class="form-control" placeholder="Buscar por código o descripción..." />
            </div>
            <div class="col-auto">
                <button id="btnSearch" class="btn btn-secondary">Buscar</button>
                <button id="btnClear" class="btn btn-light">Limpiar</button>
            </div>
        </div>

        <div id="alertPlaceholder"></div>

        <!-- Aquí se renderizan las tarjetas -->
        <div id="cardsContainer" class="card-columns"></div>
    </div>

    <!-- Modal Archivos (reutilizable) -->
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

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script>

    <script>

        function downloadFiles(idArchivo, fileName) {
            const url = `DownloadHandler.ashx?id=${idArchivo}&file=${encodeURIComponent(fileName)}`;
            window.location.href = url;
        }

        $(function () {
            // Forzar envío de cookies/credenciales para AJAX/fetch
            $.ajaxSetup({ xhrFields: { withCredentials: true } });

            const $cards = $("#cardsContainer");
            const $filter = $("#txtFilter");

            function escapeHtml(text) { if (text == null) return ""; return $('<div/>').text(text).html(); }
            function showAlert(msg, type) {
                $("#alertPlaceholder").html(`<div class="alert ${type}">${msg}</div>`);
                setTimeout(() => $("#alertPlaceholder").html(""), 4500);
            }

            // Cargar productos (reusa WebMethod GetProducts)
            function loadProducts() {
                const filtro = $filter.val();
                $.ajax({
                    url: "products.aspx/GetProducts",
                    method: "POST",
                    contentType: "application/json; charset=utf-8",
                    data: JSON.stringify({ filtro: filtro }),
                    success: function (res) {
                        const payload = res && res.d ? res.d : res;
                        if (!payload || !payload.success) {
                            showAlert("No se pudieron cargar productos: " + (payload && payload.message ? payload.message : ''), "alert-danger");
                            renderCards([]);
                            return;
                        }
                        renderCards(payload.data || []);
                    },
                    error: function (xhr) {
                        console.error("GetProducts ERROR", xhr.status, xhr.responseText);
                        showAlert("Error al cargar productos (" + xhr.status + ")", "alert-danger");
                        renderCards([]);
                    }
                });
            }

            // Render tarjetas (cards)
            function renderCards(items) {
                $cards.empty();
                if (!items || items.length === 0) {
                    $cards.append(`<div class="text-muted">No hay productos</div>`);
                    return;
                }

                items.forEach(i => {
                    const card = $(`
                    <div class="card product-card">
                      <div class="card-body">
                        <h5 class="card-title">${escapeHtml(i.Codigo)} — ${escapeHtml(i.Descripcion)}</h5>
                        <p class="product-meta">
                          <strong>Precio:</strong> ${(i.Precio || 0).toFixed(2)} &nbsp; | &nbsp;
                          <strong>Stock:</strong> ${i.Stock || 0}
                        </p>
                        <div class="card-actions">
                          <button class="btn btn-sm btn-outline-primary btn-files" data-id="${i.IdProducto}" data-nombre="${escapeHtml(i.Descripcion)}">Archivos</button>
                        </div>
                      </div>
                    </div>`);
                    $cards.append(card);
                });
            }

            // eventos UI
            $("#btnSearch").on('click', loadProducts);
            $("#btnClear").on('click', function () { $filter.val(''); loadProducts(); });

            // Archivos modal
            window.openFilesModal = function (idProducto, nombreProducto) {
                $("#filesModalLabel").text("Archivos de: " + (nombreProducto || ("#" + idProducto)));
                $("#hfFileProductoId").val(idProducto);
                $("#fileInput").val('');
                $("#txtNombreVisible").val('');
                loadFilesByProduct(idProducto);
                $("#filesModal").modal('show');
            };

            // Delegación: botón archivos en tarjetas
            $cards.on('click', '.btn-files', function () {
                const id = $(this).data('id');
                const nombre = $(this).data('nombre') || '';
                openFilesModal(id, nombre);
            });

            // Cargar archivos por producto (ListFiles.ashx -> JSON)
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
                            actions.append(` <button class="btn btn-sm btn-outline-primary mr-1"
         onclick="downloadFiles(${idProducto}, '${f.NombreFisico}')">
     Descargar
 </button>`)
                            tr.append(actions);
                            tbody.append(tr);
                        });
                    })
                    .catch(err => {
                        tbody.html('<tr><td colspan="4" class="text-center text-danger">Error al cargar archivos.</td></tr>');
                        console.error(err);
                    });
            }

            // Download file (POST -> handler) - si falla intenta GET (compatibilidad)
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

            // Upload via FormData (si quieres permitir que usuarios suban archivos, dejamos la misma lógica)
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

            // Logout (AJAX -> webmethod logout on products.aspx)
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

            // Inicializar
            loadProducts();
        });
    </script>
</body>
</html>

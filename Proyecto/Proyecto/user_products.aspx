<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="user_products.aspx.cs" Inherits="Proyecto.user_products" %>

<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Portal Inventario — Productos (Usuario)</title>

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" />

    <style>
        
        body {
            padding-top: 65px; 
            background: #f8f9fa;
        }

       
        .product-card {
            cursor: pointer;
            transition: transform .08s ease;
        }
        .product-card:hover {
            transform: translateY(-3px);
        }

        
        .thumb {
            max-height: 140px;
            object-fit: cover;
            border-radius: 4px;
        }

        
        .no-ops {
            pointer-events: none;
            opacity: 0.95;
        }
    </style>
</head>

<body>

    <!-- Barra de navegación -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">Portal Inventario</a>

            <!-- Nombre del usuario + botón salir -->
            <div class="d-flex">
                <span class="navbar-text me-3">Usuario: <strong id="navUser">Invitado</strong></span>
                <button class="btn btn-sm btn-light" id="btnLogout">Cerrar sesión</button>
            </div>
        </div>
    </nav>

    <div class="container my-4">

        <!-- Título -->
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h4 class="mb-0">Productos</h4>
        </div>

        <!-- Buscador -->
        <div class="row mb-3">
            <div class="col-md-6">
                <div class="input-group">
                    <input id="txtSearch" class="form-control" placeholder="Buscar por código o descripción">
                    <button class="btn btn-outline-secondary" id="btnSearch">Buscar</button>
                </div>
            </div>
        </div>

        <!-- Grid de productos -->
        <div id="productsGrid" class="row g-3"></div>

        <div id="productsMsg" class="mt-3 small text-muted"></div>
    </div>


    <!-- Modal para archivos -->
    <div class="modal fade" id="modalFiles" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-scrollable">
            <div class="modal-content">

                <div class="modal-header">
                    <h5 class="modal-title">Archivos — <span id="filesTitle"></span></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>

                <div class="modal-body">
                    <!-- Aquí se cargan los archivos del producto -->
                    <div id="filesContainer" class="row gy-3"></div>
                </div>

                <div class="modal-footer">
                    <button class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                </div>

            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"></script>

    <script>

        // URL base para descargar archivos
        const DOWNLOAD_URL = '/DownloadFile.ashx?id=';

        // API (en demo no se usa porque todo es local)
        const LIST_FILES_API = '/FilesHandler.ashx?action=list&idProduct=';

        // Lista DEMO de productos (en producción esto vendría desde SQL Server)
        let products = [
            { IdProducto: 1, Codigo: 'P001', Descripcion: 'Cafetera Eléctrica', Precio: 49.99, Stock: 15 },
            { IdProducto: 2, Codigo: 'P002', Descripcion: 'Taladro Inalámbrico', Precio: 89.50, Stock: 8 },
            { IdProducto: 3, Codigo: 'P003', Descripcion: 'Juego de Destornilladores', Precio: 19.90, Stock: 40 }
        ];

        // Archivos DEMO por producto
        const demoFiles = {
            1: [
                {
                    IdArchivo: 101, NombreVisible: 'Manual - Cafetera.pdf', NombreFisico: 'caf_manual.pdf',
                    TipoArchivo: 'application/pdf', TamanoBytes: 245123, FechaSubida: '2025-11-20',
                    UrlPreview: 'https://via.placeholder.com/400x250?text=Cafetera'
                },
                {
                    IdArchivo: 102, NombreVisible: 'Imagen frontal.jpg', NombreFisico: 'caf_front.jpg',
                    TipoArchivo: 'image/jpeg', TamanoBytes: 152342, FechaSubida: '2025-11-20',
                    UrlPreview: 'https://via.placeholder.com/400x250?text=Imagen+1'
                }
            ],
            2: [
                {
                    IdArchivo: 201, NombreVisible: 'Ficha tecnica.pdf', NombreFisico: 'taladro_ficha.pdf',
                    TipoArchivo: 'application/pdf', TamanoBytes: 512000, FechaSubida: '2025-11-18',
                    UrlPreview: 'https://via.placeholder.com/400x250?text=Ficha'
                },
                {
                    IdArchivo: 202, NombreVisible: 'Imagen.jpg', NombreFisico: 'taladro_img.jpg',
                    TipoArchivo: 'image/jpeg', TamanoBytes: 204800, FechaSubida: '2025-11-18',
                    UrlPreview: 'https://via.placeholder.com/400x250?text=Imagen+Taladro'
                }
            ],
            3: [] // Producto sin archivos
        };

        // Referencias a elementos del DOM
        const productsGrid = document.getElementById('productsGrid');
        const modalFilesEl = document.getElementById('modalFiles');
        const bsModalFiles = new bootstrap.Modal(modalFilesEl);

        /* -----------------------------------------------
           RENDERIZAR PRODUCTOS EN PANTALLA
        -------------------------------------------------*/
        function renderProducts(list) {
            productsGrid.innerHTML = '';

            // Si no hay productos
            if (!list || !list.length) {
                productsGrid.innerHTML = `<div class="col-12"><div class="alert alert-light small mb-0">No hay productos disponibles.</div></div>`;
                return;
            }

            // Recorrer lista de productos
            for (const p of list) {

                // Contenedor de producto
                const col = document.createElement('div');
                col.className = 'col-12 col-md-6 col-lg-4';

                // Tarjeta del producto
                col.innerHTML = `
        <div class="card product-card shadow-sm">
          <div class="row g-0">

            <!-- Imagen (placeholder) -->
            <div class="col-4 d-flex align-items-center justify-content-center p-2">
              <img src="https://via.placeholder.com/220x140?text=${encodeURIComponent(p.Codigo)}"
                   alt="${escapeHtml(p.Descripcion)}"
                   class="img-fluid thumb" />
            </div>

            <div class="col-8">
              <div class="card-body py-2">

                <!-- Descripción -->
                <h6 class="card-title mb-1">${escapeHtml(p.Descripcion)}</h6>

                <!-- Código -->
                <div class="small text-muted">Código: ${escapeHtml(p.Codigo)}</div>

                <!-- Precio + botones -->
                <div class="mt-2 d-flex justify-content-between align-items-center">
                  <div><strong>L. ${Number(p.Precio).toFixed(2)}</strong></div>

                  <div>
                    <!-- Botón abrir archivos -->
                    <button class="btn btn-sm btn-outline-primary"
                            onclick="openFiles(${p.IdProducto}, '${escapeJs(p.Descripcion)}')">
                      Ver archivos
                    </button>

                    <!-- Botón descargar todos -->
                    <button class="btn btn-sm btn-outline-secondary"
                            onclick="downloadAll(${p.IdProducto})"
                            ${hasFiles(p.IdProducto) ? '' : 'disabled'}>
                      Descargar
                    </button>
                  </div>
                </div>

                <!-- Stock -->
                <div class="small text-muted mt-2">Stock: ${p.Stock}</div>

              </div>
            </div>
          </div>
        </div>
      `;

                productsGrid.appendChild(col);
            }
        }


        /* Funciones auxiliares */
        function escapeHtml(str = '') {
            return String(str)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
        }

        function escapeJs(str = '') {
            return String(str).replace(/'/g, "\\'").replace(/"/g, '\\"');
        }

        // Saber si un producto tiene archivos
        function hasFiles(productId) {
            const arr = demoFiles[productId] || [];
            return arr.length > 0;
        }


        /* -------------------------------------------------
           ABRIR MODAL DE ARCHIVOS POR PRODUCTO
        ---------------------------------------------------*/
        function openFiles(productId, productName) {

            document.getElementById('filesTitle').innerText = productName + ` (ID ${productId})`;
            const container = document.getElementById('filesContainer');
            container.innerHTML = '';

            const files = demoFiles[productId] || [];

            // Si NO tiene archivos
            if (!files.length) {
                container.innerHTML = `<div class="col-12"><div class="alert alert-info small mb-0">No hay archivos disponibles para este producto.</div></div>`;
                bsModalFiles.show();
                return;
            }

            // Recorrer archivos y mostrarlos
            for (const f of files) {

                const isImage = f.TipoArchivo?.startsWith('image/');

                const col = document.createElement('div');
                col.className = 'col-12 col-md-6';

                col.innerHTML = `
        <div class="d-flex bg-white p-3 rounded shadow-sm align-items-center">

          <!-- Vista previa -->
          <div class="me-3" style="width:150px; flex:0 0 150px;">
            ${isImage
                        ? `<img src="${f.UrlPreview}" class="img-fluid rounded thumb" />`
                        : `<div class="d-flex align-items-center justify-content-center bg-light rounded" style="height:110px;">
                   <svg width="48" height="48" fill="none" stroke="currentColor">
                     <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                     <path d="M14 2v6h6"></path>
                   </svg>
                 </div>`
                    }
          </div>

          <!-- Info del archivo -->
          <div class="flex-grow-1">
            <div class="fw-semibold">${escapeHtml(f.NombreVisible)}</div>

            <div class="small text-muted">
              Tipo: ${escapeHtml(f.TipoArchivo)} — ${formatSize(f.TamanoBytes)} — Subido: ${f.FechaSubida}
            </div>

            <div class="mt-2">
              <!-- Descargar archivo -->
              <a class="btn btn-sm btn-outline-primary"
                 href="${DOWNLOAD_URL}${f.IdArchivo}"
                 target="_blank">Descargar</a>

              <!-- Abrir imagen -->
              ${isImage ? `<button class="btn btn-sm btn-outline-secondary ms-2"
                                   onclick="window.open('${f.UrlPreview}','_blank')">Abrir imagen</button>` : ''}
            </div>
          </div>

        </div>
      `;

                container.appendChild(col);
            }

            bsModalFiles.show();
        }


        /* --------------------------------------------------
           DESCARGAR TODOS LOS ARCHIVOS DEL PRODUCTO
        -----------------------------------------------------*/
        function downloadAll(productId) {
            const files = demoFiles[productId] || [];
            if (!files.length) return alert('No hay archivos para descargar.');

            // Abrir todos los links en nuevas pestañas
            for (const f of files) {
                window.open(DOWNLOAD_URL + f.IdArchivo, '_blank');
            }
        }


        /* Formato tamaño de archivo */
        function formatSize(bytes) {
            if (!bytes) return '-';
            const kb = bytes / 1024;
            if (kb < 1024) return `${kb.toFixed(1)} KB`;
            return `${(kb / 1024).toFixed(2)} MB`;
        }


        /* --------------------------------------
           EVENTO DEL BUSCADOR
        -----------------------------------------*/
        document.getElementById('btnSearch').addEventListener('click', () => {
            const q = document.getElementById('txtSearch').value.trim().toLowerCase();

            // Si la búsqueda está vacía, Mostrar todo
            if (!q) { renderProducts(products); return; }

            // Filtrar por código o descripción
            renderProducts(products.filter(p =>
                (p.Codigo + ' ' + p.Descripcion).toLowerCase().includes(q)
            ));
        });


        /* --------------------------------------
           EVENTO CERRAR SESIÓN
        -----------------------------------------*/
        document.getElementById('btnLogout').addEventListener('click', () => {
            window.location.href = 'login.aspx';
        });


        /* Render inicial */
        renderProducts(products);

    </script>
</body>
</html>
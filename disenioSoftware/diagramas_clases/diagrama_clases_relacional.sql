-- =====================================================
-- TRANSFORMACIÓN DEL DIAGRAMA DE CLASES AL RELACIONAL
-- Sistema de Gestión de Listas de Regalos
-- =====================================================

-- ===== TABLA PRINCIPAL DE USUARIOS (Clase abstracta) =====
-- Herencia: Se usa estrategia de tabla por jerarquía (Single Table Inheritance)
-- con campo discriminador 'tipoUsuario'

CREATE TABLE Usuario (
    idUsuario INT PRIMARY KEY AUTO_INCREMENT,
    tipoUsuario VARCHAR(20) NOT NULL, -- 'INVITADO', 'PERSONA_PAREJA', 'ADMINISTRADOR'
    dni VARCHAR(20) UNIQUE NOT NULL,
    nombreUsuario VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    contraseña VARCHAR(255) NOT NULL, -- encrypted
    fechaRegistro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verificado BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Atributos específicos de Invitado
    telefono VARCHAR(20),
    preferencias VARCHAR(255),
    
    -- Atributos específicos de PersonaPareja
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    esNovio BOOLEAN,
    fechaVinculacion DATETIME,
    idPareja INT, -- FK a Pareja (agregada después)
    
    -- Atributos específicos de Administrador
    nivelAcceso INT,
    
    INDEX idx_dni (dni),
    INDEX idx_email (email),
    INDEX idx_nombreUsuario (nombreUsuario),
    INDEX idx_tipoUsuario (tipoUsuario)
);

-- ===== TABLA PAREJA (Composición con PersonaPareja) =====
-- Una Pareja está compuesta por exactamente 2 PersonasPareja

CREATE TABLE Pareja (
    idPareja INT PRIMARY KEY AUTO_INCREMENT,
    codigoVinculacion VARCHAR(50) UNIQUE NOT NULL,
    fechaCasamiento DATE NOT NULL,
    fechaVinculacion DATETIME NOT NULL,
    estado ENUM('PENDIENTE_VINCULACION', 'VINCULADO', 'ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'PENDIENTE_VINCULACION',
    
    INDEX idx_codigoVinculacion (codigoVinculacion),
    INDEX idx_estado (estado)
);

-- Agregar FK de Usuario a Pareja (relación de composición)
ALTER TABLE Usuario
ADD CONSTRAINT fk_usuario_pareja 
FOREIGN KEY (idPareja) REFERENCES Pareja(idPareja) ON DELETE CASCADE;

-- ===== TABLA CATEGORÍA =====

CREATE TABLE Categoria (
    idCategoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    
    INDEX idx_nombre (nombre)
);

-- ===== TABLA PRODUCTO =====

CREATE TABLE Producto (
    idProducto INT PRIMARY KEY AUTO_INCREMENT,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stockActual INT NOT NULL DEFAULT 0,
    imagen VARCHAR(255),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fechaRegistro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    idCategoria INT NOT NULL,
    
    FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria) ON DELETE RESTRICT,
    INDEX idx_codigo (codigo),
    INDEX idx_nombre (nombre),
    INDEX idx_categoria (idCategoria),
    INDEX idx_activo (activo)
);

-- ===== TABLA ADMINISTRADOR_PRODUCTO (Relación N:M) =====
-- Relación "Administrador gestiona Productos"

CREATE TABLE Administrador_Producto (
    idAdministrador INT NOT NULL,
    idProducto INT NOT NULL,
    fechaAsignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (idAdministrador, idProducto),
    FOREIGN KEY (idAdministrador) REFERENCES Usuario(idUsuario) ON DELETE CASCADE,
    FOREIGN KEY (idProducto) REFERENCES Producto(idProducto) ON DELETE CASCADE
);

-- ===== TABLA LISTA =====

CREATE TABLE Lista (
    idLista INT PRIMARY KEY AUTO_INCREMENT,
    numeroLista VARCHAR(50) UNIQUE NOT NULL,
    fechaCasamiento DATE NOT NULL,
    fechaFinalizacion DATE NOT NULL,
    mensajeBienvenida TEXT,
    fechaCreacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    estado ENUM('BORRADOR', 'ACTIVA', 'FINALIZADA', 'CERRADA') NOT NULL DEFAULT 'BORRADOR',
    idPareja INT NOT NULL,
    
    FOREIGN KEY (idPareja) REFERENCES Pareja(idPareja) ON DELETE CASCADE,
    INDEX idx_numeroLista (numeroLista),
    INDEX idx_pareja (idPareja),
    INDEX idx_estado (estado),
    INDEX idx_activa (activa)
);

-- ===== TABLA ITEM_LISTA (Composición: Lista contiene Items) =====

CREATE TABLE ItemLista (
    idItem INT PRIMARY KEY AUTO_INCREMENT,
    cantidad INT NOT NULL DEFAULT 1,
    estadoItem ENUM('DISPONIBLE', 'PARCIALMENTE_COMPRADO', 'COMPRADO') NOT NULL DEFAULT 'DISPONIBLE',
    fechaAgregado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    idLista INT NOT NULL,
    idProducto INT NOT NULL,
    
    FOREIGN KEY (idLista) REFERENCES Lista(idLista) ON DELETE CASCADE,
    FOREIGN KEY (idProducto) REFERENCES Producto(idProducto) ON DELETE RESTRICT,
    INDEX idx_lista (idLista),
    INDEX idx_producto (idProducto),
    INDEX idx_estadoItem (estadoItem)
);

-- ===== TABLA COMPRA =====

CREATE TABLE Compra (
    idCompra INT PRIMARY KEY AUTO_INCREMENT,
    fechaCompra DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    montoTotal DECIMAL(10,2) NOT NULL,
    estadoPago ENUM('PENDIENTE', 'PROCESANDO', 'APROBADO', 'RECHAZADO', 'CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
    codigoTransaccion VARCHAR(100) UNIQUE,
    idInvitado INT NOT NULL,
    idLista INT NOT NULL,
    
    FOREIGN KEY (idInvitado) REFERENCES Usuario(idUsuario) ON DELETE RESTRICT,
    FOREIGN KEY (idLista) REFERENCES Lista(idLista) ON DELETE RESTRICT,
    INDEX idx_invitado (idInvitado),
    INDEX idx_lista (idLista),
    INDEX idx_estadoPago (estadoPago),
    INDEX idx_fechaCompra (fechaCompra)
);

-- ===== TABLA DETALLE_COMPRA (Composición: Compra contiene Detalles) =====

CREATE TABLE DetalleCompra (
    idDetalle INT PRIMARY KEY AUTO_INCREMENT,
    cantidad INT NOT NULL,
    precioUnitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    mensajePersonalizado TEXT,
    idCompra INT NOT NULL,
    idProducto INT NOT NULL,
    
    FOREIGN KEY (idCompra) REFERENCES Compra(idCompra) ON DELETE CASCADE,
    FOREIGN KEY (idProducto) REFERENCES Producto(idProducto) ON DELETE RESTRICT,
    INDEX idx_compra (idCompra),
    INDEX idx_producto (idProducto)
);

-- ===== TABLA PAGO (Relación 1:1 con Compra) =====

CREATE TABLE Pago (
    idPago INT PRIMARY KEY AUTO_INCREMENT,
    monto DECIMAL(10,2) NOT NULL,
    metodoPago VARCHAR(50) NOT NULL,
    fechaPago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    codigoAutorizacion VARCHAR(100),
    idCompra INT UNIQUE NOT NULL, -- UNIQUE garantiza relación 1:1
    
    FOREIGN KEY (idCompra) REFERENCES Compra(idCompra) ON DELETE CASCADE,
    INDEX idx_compra (idCompra),
    INDEX idx_fechaPago (fechaPago)
);

-- ===== TABLA NOTIFICACION (Herencia con tabla por jerarquía) =====

CREATE TABLE Notificacion (
    idNotificacion INT PRIMARY KEY AUTO_INCREMENT,
    tipoNotificacion ENUM('CONFIRMACION_REGISTRO', 'RECUPERACION_CONTRASEÑA', 
                          'VINCULACION_PAREJA', 'CONFIRMACION_COMPRA', 
                          'NOTIFICACION_REGALO') NOT NULL,
    tipoClase VARCHAR(30) NOT NULL, -- 'NOTIFICACION_INVITADO', 'NOTIFICACION_PAREJA'
    asunto VARCHAR(200) NOT NULL,
    cuerpo TEXT NOT NULL,
    fechaEnvio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviado BOOLEAN NOT NULL DEFAULT FALSE,
    idUsuario INT NOT NULL,
    
    -- Atributos específicos de NotificacionInvitado
    detalleCompra TEXT,
    informacionPago TEXT,
    
    -- Atributos específicos de NotificacionPareja
    productoComprado VARCHAR(200),
    mensajeInvitado TEXT,
    
    FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario) ON DELETE CASCADE,
    INDEX idx_usuario (idUsuario),
    INDEX idx_tipoNotificacion (tipoNotificacion),
    INDEX idx_enviado (enviado),
    INDEX idx_fechaEnvio (fechaEnvio)
);

-- ===== TABLA NOTIFICACION_COMPRA (Relación N:M) =====
-- Una Compra puede generar múltiples Notificaciones

CREATE TABLE Notificacion_Compra (
    idNotificacion INT NOT NULL,
    idCompra INT NOT NULL,
    
    PRIMARY KEY (idNotificacion, idCompra),
    FOREIGN KEY (idNotificacion) REFERENCES Notificacion(idNotificacion) ON DELETE CASCADE,
    FOREIGN KEY (idCompra) REFERENCES Compra(idCompra) ON DELETE CASCADE
);

-- ===== TABLA REPORTE (Herencia con tabla por jerarquía) =====

CREATE TABLE Reporte (
    idReporte INT PRIMARY KEY AUTO_INCREMENT,
    tipoReporte VARCHAR(50) NOT NULL, -- 'PRODUCTOS_MAS_ELEGIDOS', 'INVITADOS_COMPRADORES', 'STOCK'
    fechaGeneracion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    titulo VARCHAR(200) NOT NULL,
    formatoExportacion ENUM('PDF', 'EXCEL', 'CSV') NOT NULL,
    
    -- Atributos específicos de ReporteProductosMasElegidos
    fechaInicio DATE,
    fechaFin DATE,
    idCategoria INT,
    
    -- Atributos específicos de ReporteStock
    stockMinimo INT,
    
    FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria) ON DELETE SET NULL,
    INDEX idx_tipoReporte (tipoReporte),
    INDEX idx_fechaGeneracion (fechaGeneracion)
);

-- ===== TABLA REPORTE_PAREJA (Relación N:M) =====
-- Parejas consultan Reportes

CREATE TABLE Reporte_Pareja (
    idReporte INT NOT NULL,
    idPareja INT NOT NULL,
    fechaConsulta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (idReporte, idPareja),
    FOREIGN KEY (idReporte) REFERENCES Reporte(idReporte) ON DELETE CASCADE,
    FOREIGN KEY (idPareja) REFERENCES Pareja(idPareja) ON DELETE CASCADE
);

-- ===== TABLA REPORTE_ADMINISTRADOR (Relación N:M) =====
-- Administradores generan Reportes

CREATE TABLE Reporte_Administrador (
    idReporte INT NOT NULL,
    idAdministrador INT NOT NULL,
    fechaGeneracion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (idReporte, idAdministrador),
    FOREIGN KEY (idReporte) REFERENCES Reporte(idReporte) ON DELETE CASCADE,
    FOREIGN KEY (idAdministrador) REFERENCES Usuario(idUsuario) ON DELETE CASCADE
);

-- =====================================================
-- NOTAS DE TRANSFORMACIÓN:
-- =====================================================
-- 
-- 1. HERENCIA (Usuario, Notificacion, Reporte):
--    Se utilizó estrategia "Single Table Inheritance" con campo discriminador
--    para simplificar las consultas y mantener integridad referencial.
--
-- 2. COMPOSICIÓN (Pareja-PersonaPareja, Lista-ItemLista, Compra-DetalleCompra):
--    Se implementó con ON DELETE CASCADE para garantizar que al eliminar
--    el todo, se eliminan las partes.
--
-- 3. AGREGACIÓN (Pareja-Lista):
--    Se implementó con FK simple, ya que la Lista puede existir
--    temporalmente sin Pareja (estado BORRADOR).
--
-- 4. RELACIONES N:M:
--    Se crearon tablas intermedias para todas las relaciones muchos a muchos.
--
-- 5. ENUMERACIONES:
--    Se transformaron en tipos ENUM de MySQL para mayor eficiencia
--    y restricción de valores válidos.
--
-- 6. INTERFACES (SistemaPagoExterno, SistemaCorreo):
--    No se representan en el modelo relacional ya que son servicios externos.
--    Se implementarían en la capa de aplicación.
--
-- 7. RESTRICCIONES ADICIONALES:
--    - UNIQUE para garantizar unicidad (dni, email, codigo, etc.)
--    - NOT NULL para campos obligatorios
--    - DEFAULT para valores por defecto
--    - CHECK constraints pueden agregarse según el motor de BD
--
-- 8. ÍNDICES:
--    Se agregaron índices en campos frecuentemente consultados
--    y claves foráneas para optimizar rendimiento.
--
-- =====================================================
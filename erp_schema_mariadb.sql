-- ============================================================
-- ERP - MODELO DE DATOS PARA MARIADB
-- Módulos: Compras, Inventario, Ventas, Facturación, Tesorería,
--          Producción, RRHH, CRM, Logística, Contabilidad
-- ============================================================

CREATE DATABASE IF NOT EXISTS erp_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE erp_db;

-- ============================================================
-- MÓDULO: MAESTROS GENERALES
-- ============================================================

CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(150) NOT NULL,
    cuit VARCHAR(20) UNIQUE,
    condicion_iva VARCHAR(50),
    direccion VARCHAR(200),
    telefono VARCHAR(50),
    email VARCHAR(100),
    condicion_pago VARCHAR(100),
    activo TINYINT(1) DEFAULT 1,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(150) NOT NULL,
    cuit_dni VARCHAR(20) UNIQUE,
    condicion_iva VARCHAR(50),
    direccion VARCHAR(200),
    telefono VARCHAR(50),
    email VARCHAR(100),
    limite_credito DECIMAL(14,2) DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categorias_producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    categoria_id INT,
    unidad_medida VARCHAR(20) DEFAULT 'UN',
    stock_minimo DECIMAL(12,2) DEFAULT 0,
    stock_maximo DECIMAL(12,2) DEFAULT 0,
    costo_promedio DECIMAL(14,4) DEFAULT 0,
    precio_venta DECIMAL(14,4) DEFAULT 0,
    es_producto_terminado TINYINT(1) DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    FOREIGN KEY (categoria_id) REFERENCES categorias_producto(id)
) ENGINE=InnoDB;

CREATE TABLE depositos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(200)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: INVENTARIO / STOCK
-- ============================================================

CREATE TABLE stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    deposito_id INT NOT NULL,
    cantidad DECIMAL(14,2) DEFAULT 0,
    cantidad_comprometida DECIMAL(14,2) DEFAULT 0,
    UNIQUE KEY uq_producto_deposito (producto_id, deposito_id),
    FOREIGN KEY (producto_id) REFERENCES productos(id),
    FOREIGN KEY (deposito_id) REFERENCES depositos(id)
) ENGINE=InnoDB;

CREATE TABLE movimientos_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    deposito_id INT NOT NULL,
    tipo_movimiento ENUM('entrada','salida','ajuste_positivo','ajuste_negativo') NOT NULL,
    cantidad DECIMAL(14,2) NOT NULL,
    motivo VARCHAR(150),
    referencia_tipo VARCHAR(50), -- 'orden_compra','orden_venta','produccion','ajuste_manual'
    referencia_id INT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id),
    FOREIGN KEY (deposito_id) REFERENCES depositos(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: COMPRAS
-- ============================================================

CREATE TABLE ordenes_compra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente','confirmada','recibida_parcial','recibida_total','cerrada','cancelada') DEFAULT 'pendiente',
    condicion_pago VARCHAR(100),
    total DECIMAL(14,2) DEFAULT 0,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
) ENGINE=InnoDB;

CREATE TABLE ordenes_compra_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_compra_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad DECIMAL(14,2) NOT NULL,
    precio_unitario DECIMAL(14,4) NOT NULL,
    subtotal DECIMAL(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    FOREIGN KEY (orden_compra_id) REFERENCES ordenes_compra(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB;

CREATE TABLE recepciones_mercaderia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_compra_id INT NOT NULL,
    numero_remito_proveedor VARCHAR(50),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente_control','conforme','con_observaciones') DEFAULT 'pendiente_control',
    FOREIGN KEY (orden_compra_id) REFERENCES ordenes_compra(id)
) ENGINE=InnoDB;

CREATE TABLE recepciones_mercaderia_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    recepcion_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad_recibida DECIMAL(14,2) NOT NULL,
    FOREIGN KEY (recepcion_id) REFERENCES recepciones_mercaderia(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB;

CREATE TABLE facturas_compra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    orden_compra_id INT,
    numero_factura VARCHAR(50) NOT NULL,
    tipo_comprobante VARCHAR(10),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(14,2) NOT NULL,
    cae VARCHAR(30),
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
    FOREIGN KEY (orden_compra_id) REFERENCES ordenes_compra(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: VENTAS
-- ============================================================

CREATE TABLE ordenes_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente','confirmado','preparando','despachado','facturado','cancelado') DEFAULT 'pendiente',
    total DECIMAL(14,2) DEFAULT 0,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB;

CREATE TABLE ordenes_venta_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad DECIMAL(14,2) NOT NULL,
    precio_unitario DECIMAL(14,4) NOT NULL,
    subtotal DECIMAL(14,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    FOREIGN KEY (orden_venta_id) REFERENCES ordenes_venta(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB;

CREATE TABLE remitos_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_venta_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    transportista VARCHAR(100),
    estado ENUM('preparado','en_transito','entregado') DEFAULT 'preparado',
    FOREIGN KEY (orden_venta_id) REFERENCES ordenes_venta(id)
) ENGINE=InnoDB;

CREATE TABLE facturas_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    orden_venta_id INT,
    numero_factura VARCHAR(50) NOT NULL,
    tipo_comprobante VARCHAR(10),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(14,2) NOT NULL,
    cae VARCHAR(30),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (orden_venta_id) REFERENCES ordenes_venta(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: CUENTAS CORRIENTES (Facturación -> Tesorería)
-- ============================================================

CREATE TABLE cuentas_por_cobrar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    factura_venta_id INT NOT NULL,
    monto DECIMAL(14,2) NOT NULL,
    saldo DECIMAL(14,2) NOT NULL,
    fecha_vencimiento DATE,
    estado ENUM('pendiente','parcial','cancelada') DEFAULT 'pendiente',
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (factura_venta_id) REFERENCES facturas_venta(id)
) ENGINE=InnoDB;

CREATE TABLE cuentas_por_pagar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    factura_compra_id INT NOT NULL,
    monto DECIMAL(14,2) NOT NULL,
    saldo DECIMAL(14,2) NOT NULL,
    fecha_vencimiento DATE,
    estado ENUM('pendiente','parcial','cancelada') DEFAULT 'pendiente',
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
    FOREIGN KEY (factura_compra_id) REFERENCES facturas_compra(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: TESORERÍA / CAJA Y BANCOS
-- ============================================================

CREATE TABLE caja_bancos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM('caja','banco') NOT NULL,
    saldo DECIMAL(14,2) DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE cobros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_por_cobrar_id INT NOT NULL,
    caja_banco_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(14,2) NOT NULL,
    medio_pago ENUM('efectivo','transferencia','cheque','tarjeta') NOT NULL,
    referencia VARCHAR(100),
    FOREIGN KEY (cuenta_por_cobrar_id) REFERENCES cuentas_por_cobrar(id),
    FOREIGN KEY (caja_banco_id) REFERENCES caja_bancos(id)
) ENGINE=InnoDB;

CREATE TABLE pagos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_por_pagar_id INT NOT NULL,
    caja_banco_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(14,2) NOT NULL,
    medio_pago ENUM('efectivo','transferencia','cheque','tarjeta') NOT NULL,
    referencia VARCHAR(100),
    FOREIGN KEY (cuenta_por_pagar_id) REFERENCES cuentas_por_pagar(id),
    FOREIGN KEY (caja_banco_id) REFERENCES caja_bancos(id)
) ENGINE=InnoDB;

CREATE TABLE movimientos_caja_bancos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caja_banco_id INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    tipo ENUM('ingreso','egreso') NOT NULL,
    monto DECIMAL(14,2) NOT NULL,
    concepto VARCHAR(150),
    referencia_tipo VARCHAR(50), -- 'cobro','pago','nomina','otro'
    referencia_id INT,
    FOREIGN KEY (caja_banco_id) REFERENCES caja_bancos(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: PRODUCCIÓN (opcional para empresas manufactureras)
-- ============================================================

CREATE TABLE bom_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL COMMENT 'Producto terminado',
    componente_id INT NOT NULL COMMENT 'Materia prima o insumo',
    cantidad_necesaria DECIMAL(14,4) NOT NULL,
    FOREIGN KEY (producto_id) REFERENCES productos(id),
    FOREIGN KEY (componente_id) REFERENCES productos(id)
) ENGINE=InnoDB;

CREATE TABLE ordenes_produccion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad_planificada DECIMAL(14,2) NOT NULL,
    cantidad_terminada DECIMAL(14,2) DEFAULT 0,
    fecha_inicio DATETIME,
    fecha_fin DATETIME,
    estado ENUM('planificada','en_proceso','control_calidad','finalizada','cancelada') DEFAULT 'planificada',
    orden_venta_id INT NULL,
    FOREIGN KEY (producto_id) REFERENCES productos(id),
    FOREIGN KEY (orden_venta_id) REFERENCES ordenes_venta(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: RRHH / NÓMINA
-- ============================================================

CREATE TABLE empleados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    legajo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE,
    puesto VARCHAR(100),
    fecha_ingreso DATE,
    salario_basico DECIMAL(14,2),
    activo TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE asistencias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_id INT NOT NULL,
    fecha DATE NOT NULL,
    horas_trabajadas DECIMAL(5,2) DEFAULT 0,
    tipo_novedad ENUM('presente','licencia','vacaciones','ausente_injustificado') DEFAULT 'presente',
    FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE liquidaciones_sueldo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_id INT NOT NULL,
    periodo VARCHAR(7) NOT NULL COMMENT 'Formato YYYY-MM',
    bruto DECIMAL(14,2) NOT NULL,
    descuentos DECIMAL(14,2) DEFAULT 0,
    neto DECIMAL(14,2) GENERATED ALWAYS AS (bruto - descuentos) STORED,
    fecha_pago DATE,
    caja_banco_id INT,
    FOREIGN KEY (empleado_id) REFERENCES empleados(id),
    FOREIGN KEY (caja_banco_id) REFERENCES caja_bancos(id)
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: CRM
-- ============================================================

CREATE TABLE crm_oportunidades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_contacto VARCHAR(150) NOT NULL,
    cliente_id INT NULL COMMENT 'Se completa al convertir el lead en cliente',
    etapa ENUM('lead','contactado','cotizado','ganado','perdido') DEFAULT 'lead',
    valor_estimado DECIMAL(14,2),
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    orden_venta_id INT NULL,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (orden_venta_id) REFERENCES ordenes_venta(id)
) ENGINE=InnoDB;

CREATE TABLE crm_interacciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    oportunidad_id INT NOT NULL,
    tipo ENUM('llamada','email','visita','reunion') NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    detalle TEXT,
    FOREIGN KEY (oportunidad_id) REFERENCES crm_oportunidades(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- MÓDULO: CONTABILIDAD
-- ============================================================

CREATE TABLE plan_cuentas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo ENUM('activo','pasivo','patrimonio_neto','ingreso','egreso') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE asientos_contables (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    descripcion VARCHAR(200),
    origen_tipo VARCHAR(50) COMMENT 'venta, compra, cobro, pago, nomina, produccion, manual',
    origen_id INT
) ENGINE=InnoDB;

CREATE TABLE asientos_contables_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asiento_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    debe DECIMAL(14,2) DEFAULT 0,
    haber DECIMAL(14,2) DEFAULT 0,
    FOREIGN KEY (asiento_id) REFERENCES asientos_contables(id) ON DELETE CASCADE,
    FOREIGN KEY (cuenta_id) REFERENCES plan_cuentas(id)
) ENGINE=InnoDB;

-- ============================================================
-- ÍNDICES ADICIONALES RECOMENDADOS
-- ============================================================

CREATE INDEX idx_mov_stock_producto ON movimientos_stock(producto_id);
CREATE INDEX idx_oc_proveedor ON ordenes_compra(proveedor_id);
CREATE INDEX idx_ov_cliente ON ordenes_venta(cliente_id);
CREATE INDEX idx_fv_cliente ON facturas_venta(cliente_id);
CREATE INDEX idx_fc_proveedor ON facturas_compra(proveedor_id);
CREATE INDEX idx_cxc_estado ON cuentas_por_cobrar(estado);
CREATE INDEX idx_cxp_estado ON cuentas_por_pagar(estado);
CREATE INDEX idx_asiento_origen ON asientos_contables(origen_tipo, origen_id);

-- ============================================================
-- DATOS BASE MÍNIMOS (opcional, para arrancar a probar)
-- ============================================================

INSERT INTO depositos (nombre, direccion) VALUES ('Depósito Central', 'Sin especificar');

INSERT INTO plan_cuentas (codigo, nombre, tipo) VALUES
('1.1.01', 'Caja', 'activo'),
('1.1.02', 'Banco Cuenta Corriente', 'activo'),
('1.1.03', 'Deudores por Ventas', 'activo'),
('1.1.04', 'Mercaderías / Inventario', 'activo'),
('2.1.01', 'Proveedores', 'pasivo'),
('2.1.02', 'Sueldos a Pagar', 'pasivo'),
('4.1.01', 'Ventas', 'ingreso'),
('5.1.01', 'Costo de Mercadería Vendida', 'egreso'),
('5.1.02', 'Sueldos y Cargas Sociales', 'egreso');

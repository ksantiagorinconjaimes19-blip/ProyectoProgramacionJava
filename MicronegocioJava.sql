-- ============================================================
--  SISTEMA DE GESTIÓN INTEGRAL Y ANALÍTICA PARA MICRONEGOCIOS
--  Base de Datos: micronegocio_db
--  Motor: MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS micronegocio_db;
CREATE DATABASE micronegocio_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_spanish_ci;

USE micronegocio_db;

-- ============================================================
-- TABLA: roles
-- Almacena los perfiles de acceso del sistema
-- ============================================================
CREATE TABLE roles (
    id_rol       INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(30)  NOT NULL UNIQUE,          
    descripcion  VARCHAR(150) NOT NULL,
    CONSTRAINT pk_roles PRIMARY KEY (id_rol)
);

-- ============================================================
-- TABLA: usuarios
-- Usuarios que pueden acceder al sistema
-- ============================================================
CREATE TABLE usuarios (
    id_usuario   INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(80)  NOT NULL,
    correo       VARCHAR(100) NOT NULL UNIQUE,
    contrasena   VARCHAR(255) NOT NULL,                  -- bcrypt hash
    telefono     VARCHAR(15)      NULL,
    activo       TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_registro DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_rol       INT          NOT NULL,
    CONSTRAINT pk_usuarios  PRIMARY KEY (id_usuario),
    CONSTRAINT fk_usr_rol   FOREIGN KEY (id_rol) REFERENCES roles (id_rol)
);

-- ============================================================
-- TABLA: categorias
-- Clasificación de los productos
-- ============================================================
CREATE TABLE categorias (
    id_categoria INT         NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(60) NOT NULL UNIQUE,
    descripcion  VARCHAR(150)    NULL,
    CONSTRAINT pk_categorias PRIMARY KEY (id_categoria)
);

-- ============================================================
-- TABLA: proveedores
-- Empresas o personas que suministran productos al negocio
-- (compatible con la clase Proveedor del proyecto Spring Boot)
-- ============================================================
CREATE TABLE proveedores (
    nit          INT         NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    ciudad       VARCHAR(60)  NOT NULL,
    direccion    VARCHAR(120)     NULL,
    telefono     VARCHAR(15)      NULL,
    correo       VARCHAR(100)     NULL,
    CONSTRAINT pk_proveedores PRIMARY KEY (nit)
);

-- ============================================================
-- TABLA: productos
-- Inventario de artículos disponibles para la venta
-- ============================================================
CREATE TABLE productos (
    codigo        INT            NOT NULL AUTO_INCREMENT,
    nombre        VARCHAR(100)   NOT NULL,
    nitproveedor  INT            NOT NULL,
    id_categoria  INT                NULL,
    precio_compra DOUBLE         NOT NULL DEFAULT 0.0,
    iva           DOUBLE         NOT NULL DEFAULT 19.0,  
    precio_venta  DOUBLE         NOT NULL DEFAULT 0.0,
    stock_actual  INT            NOT NULL DEFAULT 0,
    stock_minimo  INT            NOT NULL DEFAULT 5,
    unidad_medida VARCHAR(20)        NULL DEFAULT 'UNIDAD',
    activo        TINYINT(1)     NOT NULL DEFAULT 1,
    CONSTRAINT pk_productos   PRIMARY KEY (codigo),
    CONSTRAINT fk_prod_prov   FOREIGN KEY (nitproveedor)  REFERENCES proveedores (nit),
    CONSTRAINT fk_prod_cat    FOREIGN KEY (id_categoria)  REFERENCES categorias  (id_categoria)
);

-- ============================================================
-- TABLA: clientes
-- Personas que realizan compras en el negocio
-- ============================================================
CREATE TABLE clientes (
    id_cliente   INT          NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(100) NOT NULL,
    documento    VARCHAR(20)  NOT NULL UNIQUE,
    telefono     VARCHAR(15)      NULL,
    direccion    VARCHAR(150)     NULL,
    correo       VARCHAR(100)     NULL,
    fecha_registro DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_clientes PRIMARY KEY (id_cliente)
);

-- ============================================================
-- TABLA: ventas
-- Encabezado de cada transacción de venta
-- ============================================================
CREATE TABLE ventas (
    id_venta     INT          NOT NULL AUTO_INCREMENT,
    fecha        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_cliente   INT              NULL,                 
    id_usuario   INT          NOT NULL,                 
    subtotal     DOUBLE       NOT NULL DEFAULT 0.0,
    total_iva    DOUBLE       NOT NULL DEFAULT 0.0,
    total        DOUBLE       NOT NULL DEFAULT 0.0,
    tipo_pago    ENUM('CONTADO','CREDITO') NOT NULL DEFAULT 'CONTADO',
    estado       ENUM('ACTIVA','ANULADA')  NOT NULL DEFAULT 'ACTIVA',
    observacion  VARCHAR(200)     NULL,
    CONSTRAINT pk_ventas      PRIMARY KEY (id_venta),
    CONSTRAINT fk_vta_cliente FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente),
    CONSTRAINT fk_vta_usr     FOREIGN KEY (id_usuario) REFERENCES usuarios  (id_usuario)
);

-- ============================================================
-- TABLA: detalle_ventas
-- Líneas de cada venta (qué productos y en qué cantidad)
-- ============================================================
CREATE TABLE detalle_ventas (
    id_detalle   INT    NOT NULL AUTO_INCREMENT,
    id_venta     INT    NOT NULL,
    codigo_prod  INT    NOT NULL,
    cantidad     INT    NOT NULL DEFAULT 1,
    precio_unit  DOUBLE NOT NULL,                       
    iva_unit     DOUBLE NOT NULL DEFAULT 0.0,
    subtotal     DOUBLE NOT NULL DEFAULT 0.0,
    CONSTRAINT pk_detalle_venta  PRIMARY KEY (id_detalle),
    CONSTRAINT fk_dv_venta       FOREIGN KEY (id_venta)    REFERENCES ventas   (id_venta),
    CONSTRAINT fk_dv_producto    FOREIGN KEY (codigo_prod) REFERENCES productos (codigo)
);

-- ============================================================
-- TABLA: cartera
-- Módulo de Gestión de Créditos ("fiao")
-- Un registro por venta a crédito
-- ============================================================
CREATE TABLE cartera (
    id_cartera   INT          NOT NULL AUTO_INCREMENT,
    id_venta     INT          NOT NULL UNIQUE,         
    id_cliente   INT          NOT NULL,
    monto_total  DOUBLE       NOT NULL,                  
    saldo_actual DOUBLE       NOT NULL,                  
    fecha_inicio DATE         NOT NULL,
    fecha_limite DATE             NULL,                  
    estado       ENUM('PENDIENTE','ABONADA','PAGADA','VENCIDA') NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT pk_cartera     PRIMARY KEY (id_cartera),
    CONSTRAINT fk_cart_venta  FOREIGN KEY (id_venta)   REFERENCES ventas   (id_venta),
    CONSTRAINT fk_cart_client FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
);

-- ============================================================
-- TABLA: abonos
-- Pagos parciales realizados sobre una deuda de cartera
-- ============================================================
CREATE TABLE abonos (
    id_abono     INT          NOT NULL AUTO_INCREMENT,
    id_cartera   INT          NOT NULL,
    fecha        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor        DOUBLE       NOT NULL,
    id_usuario   INT          NOT NULL,                 
    observacion  VARCHAR(200)     NULL,
    CONSTRAINT pk_abonos      PRIMARY KEY (id_abono),
    CONSTRAINT fk_abo_cartera FOREIGN KEY (id_cartera) REFERENCES cartera  (id_cartera),
    CONSTRAINT fk_abo_usr     FOREIGN KEY (id_usuario) REFERENCES usuarios  (id_usuario)
);

-- ============================================================
-- TABLA: repartidores
-- Datos adicionales de los usuarios con rol REPARTIDOR
-- ============================================================
CREATE TABLE repartidores (
    id_repartidor  INT         NOT NULL AUTO_INCREMENT,
    id_usuario     INT         NOT NULL UNIQUE,
    vehiculo       VARCHAR(50)     NULL,
    placa          VARCHAR(10)     NULL,
    disponible     TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT pk_repartidores   PRIMARY KEY (id_repartidor),
    CONSTRAINT fk_rep_usuario    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
);

-- ============================================================
-- TABLA: pedidos
-- Módulo de Logística y Domicilios
-- ============================================================
CREATE TABLE pedidos (
    id_pedido      INT          NOT NULL AUTO_INCREMENT,
    id_venta       INT          NOT NULL,
    id_cliente     INT          NOT NULL,
    id_repartidor  INT              NULL,                
    direccion_entrega VARCHAR(200) NOT NULL,
    fecha_solicitud   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega     DATETIME     NULL,
    estado         ENUM('EN_PREPARACION','EN_CAMINO','ENTREGADO','CANCELADO')
                                 NOT NULL DEFAULT 'EN_PREPARACION',
    observacion    VARCHAR(200)     NULL,
    CONSTRAINT pk_pedidos        PRIMARY KEY (id_pedido),
    CONSTRAINT fk_ped_venta      FOREIGN KEY (id_venta)      REFERENCES ventas       (id_venta),
    CONSTRAINT fk_ped_cliente    FOREIGN KEY (id_cliente)    REFERENCES clientes     (id_cliente),
    CONSTRAINT fk_ped_repartidor FOREIGN KEY (id_repartidor) REFERENCES repartidores (id_repartidor)
);

-- ============================================================
-- TABLA: cierres_caja
-- Registro del cierre diario con totales del día
-- ============================================================
CREATE TABLE cierres_caja (
    id_cierre      INT      NOT NULL AUTO_INCREMENT,
    fecha          DATE     NOT NULL UNIQUE,
    total_ventas   DOUBLE   NOT NULL DEFAULT 0.0,
    total_contado  DOUBLE   NOT NULL DEFAULT 0.0,
    total_credito  DOUBLE   NOT NULL DEFAULT 0.0,
    num_ventas     INT      NOT NULL DEFAULT 0,
    id_usuario     INT      NOT NULL,                   
    observacion    VARCHAR(200) NULL,
    CONSTRAINT pk_cierres    PRIMARY KEY (id_cierre),
    CONSTRAINT fk_cierre_usr FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
);

-- ============================================================
--  D A T O S   I N I C I A L E S
-- ============================================================

-- Roles del sistema
INSERT INTO roles (nombre, descripcion) VALUES
    ('ADMINISTRADOR', 'Acceso total al sistema: usuarios, inventario, reportes y configuracion'),
    ('CAJERO',        'Acceso al punto de venta, inventario, clientes y cartera'),
    ('REPARTIDOR',    'Acceso unicamente a sus pedidos asignados y actualizacion de estados');

-- Usuarios de prueba (contraseñas: Admin123, Caja123, Repa123 — hasheadas con bcrypt)
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol) VALUES
    ('Carlos Administrador', 'admin@micronegocio.co',   '$2a$10$wXkd8jq9.HtKL1m5s7gXCe9pU1Jf2dQrZ.AAoEy1n3GbMUvWtDIbS', '3201112233', 1),
    ('Ana Cajero',           'cajero@micronegocio.co',  '$2a$10$3R5hP2.NzYQ0cEkW7OuIvuB1tGLeMPtFQFBjlVjb8sLaFo9XjX3cS', '3119988776', 2),
    ('Luis Repartidor',      'reparto@micronegocio.co', '$2a$10$mK9QfUvHJTy3dC2Xw8lDpOSNIFvEaR1BZ7kZh0nqcGLV6sPmZkT6O', '3154433221', 3);

-- Repartidor vinculado al usuario Luis
INSERT INTO repartidores (id_usuario, vehiculo, placa, disponible) VALUES
    (3, 'Moto Honda CB 125', 'ABC-12D', 1);

-- Categorías de productos
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Frutas y Verduras',  'Productos frescos del campo'),
    ('Lacteos',            'Leche, queso, mantequilla y derivados'),
    ('Aseo',               'Productos de limpieza del hogar'),
    ('Bebidas',            'Gaseosas, jugos, aguas y similares'),
    ('Granos y Legumbres', 'Arroz, lentejas, frijoles y cereales'),
    ('Snacks y Dulces',    'Mecatos, chocolates y golosinas');

-- Proveedores
INSERT INTO proveedores (nit, nombre, ciudad, direccion, telefono, correo) VALUES
    (1, 'La Surtidora',          'Bucaramanga', 'Cra 27 #45-12 Centro',          '6076121234', 'surtidora@email.com'),
    (2, 'Fresca La Verdura',     'Bogota',      'Av. Boyaca #80-05 Fontibon',     '6011234567', 'frescalaverdura@email.com'),
    (3, 'Lacteos del Norte',     'Medellin',    'Cll 80 #32-18 Laureles',         '6044321234', 'lacteosn@email.com'),
    (4, 'Distribuidora Aseo Max','Bucaramanga', 'Cll 36 #18-90 San Francisco',    '6076987654', 'aseomax@email.com'),
    (5, 'Bebidas Refrescantes',  'Cali',        'Av. 3N #24-50 Centenario',       '6022334455', 'bebidas@email.com');

-- Productos (inventario inicial)
INSERT INTO productos (nombre, nitproveedor, id_categoria, precio_compra, iva, precio_venta, stock_actual, stock_minimo, unidad_medida) VALUES
    ('Manzanas Rojas x kg',          2, 1,  2800.0, 0.0,  4500.0,  80,  10, 'KG'),
    ('Platanos x Racimo',            2, 1,  1500.0, 0.0,  2800.0,  60,   8, 'RACIMO'),
    ('Tomate Chonto x kg',           2, 1,  2200.0, 0.0,  3500.0,  50,  10, 'KG'),
    ('Leche Entera Alpina 1L',       3, 2,  2800.0, 0.0,  3800.0, 120,  20, 'UNIDAD'),
    ('Queso Campesino x 250g',       3, 2,  4500.0, 0.0,  6200.0,  40,   8, 'UNIDAD'),
    ('Detergente Ariel 1kg',         4, 3,  7800.0,19.0, 12500.0,  35,   5, 'UNIDAD'),
    ('Jabon Palmolive x 3 und',      4, 3,  3500.0,19.0,  5800.0,  50,   5, 'PAQUETE'),
    ('Gaseosa Colombiana 1.5L',      5, 4,  3200.0,19.0,  5000.0,  90,  15, 'UNIDAD'),
    ('Agua Cristal 600ml',           5, 4,  1200.0, 0.0,  2000.0, 200,  30, 'UNIDAD'),
    ('Arroz Diana x 3kg',            1, 5,  7500.0, 0.0, 11000.0,  70,  10, 'PAQUETE'),
    ('Frijol Bolo Rojo x 500g',      1, 5,  4200.0, 0.0,  6500.0,  45,   8, 'PAQUETE'),
    ('Papas Margarita Clasicas 100g',1, 6,  1800.0,19.0,  2800.0, 100,  20, 'UNIDAD');

-- Clientes
INSERT INTO clientes (nombre, documento, telefono, direccion, correo) VALUES
    ('Maria Fernanda Lopez',  '37894521', '3112233445', 'Cll 45 #23-10 Barrio Centro',  'mflopez@gmail.com'),
    ('Juan Carlos Perez',     '91234567', '3209988776', 'Cra 18 #67-05 Barrio Sur',     NULL),
    ('Rosa Elena Gutierrez',  '52345678', '3154433221', 'Cll 12 #8-90 El Refugio',      'rosita@hotmail.com'),
    ('Pedro Hernandez Ruiz',  '80112233', '3016677889', 'Diagonal 15 #20-34',           NULL),
    ('Claudia Patricia Vega', '41223344', '3183344556', 'Cra 5 #9-12 Barrio Norte',     'claudiavega@email.com');

-- Venta 1: contado (cliente 1)
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago) VALUES
    ('2024-10-01 09:15:00', 1, 2, 14200.0, 0.0, 14200.0, 'CONTADO');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (1, 1, 2, 4500.0, 0.0,  9000.0),
    (1, 9, 2, 2000.0, 0.0,  4000.0),
    (1,12, 1, 2800.0, 532.0, 2800.0);
-- Ajuste stock
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 1;
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 9;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 12;

-- Venta 2: crédito (cliente 2) → genera deuda en cartera
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago) VALUES
    ('2024-10-02 11:30:00', 2, 2, 33600.0, 4788.0, 33600.0, 'CREDITO');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (2,  6, 1, 12500.0, 2375.0, 12500.0),
    (2,  7, 2,  5800.0, 1102.0, 11600.0),
    (2, 10, 1, 11000.0,    0.0, 11000.0);
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 6;
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 7;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 10;

-- Deuda generada por la venta 2
INSERT INTO cartera (id_venta, id_cliente, monto_total, saldo_actual, fecha_inicio, fecha_limite, estado) VALUES
    (2, 2, 33600.0, 33600.0, '2024-10-02', '2024-10-30', 'PENDIENTE');

-- Venta 3: contado (cliente 3) → con domicilio
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago) VALUES
    ('2024-10-03 14:00:00', 3, 2, 19300.0, 0.0, 19300.0, 'CONTADO');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (3,  4, 3, 3800.0, 0.0, 11400.0),
    (3,  5, 1, 6200.0, 0.0,  6200.0),
    (3,  2, 1, 2800.0, 0.0,  2800.0);
UPDATE productos SET stock_actual = stock_actual - 3 WHERE codigo = 4;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 5;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 2;

-- Pedido de domicilio para la venta 3
INSERT INTO pedidos (id_venta, id_cliente, id_repartidor, direccion_entrega, estado) VALUES
    (3, 3, 1, 'Cll 12 #8-90 El Refugio - llamar al llegar', 'EN_CAMINO');

-- Venta 4: crédito (cliente 4)
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago) VALUES
    ('2024-10-05 10:00:00', 4, 2, 18500.0, 0.0, 18500.0, 'CREDITO');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (4,  3, 2, 3500.0, 0.0,  7000.0),
    (4, 10, 1,11000.0, 0.0, 11000.0),
    (4,  9, 1, 2000.0, 0.0,  2000.0);
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 3;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 10;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 9;

INSERT INTO cartera (id_venta, id_cliente, monto_total, saldo_actual, fecha_inicio, fecha_limite, estado) VALUES
    (4, 4, 18500.0, 18500.0, '2024-10-05', '2024-11-05', 'PENDIENTE');

-- Abono parcial del cliente 4
INSERT INTO abonos (id_cartera, valor, id_usuario, observacion) VALUES
    (2, 10000.0, 2, 'Abono en efectivo - cliente llego al local');
UPDATE cartera SET saldo_actual = saldo_actual - 10000.0, estado = 'ABONADA'
    WHERE id_cartera = 2;

-- Venta 5: contado (cliente 5) - semana siguiente
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago) VALUES
    ('2024-10-08 08:45:00', 5, 2, 13300.0, 0.0, 13300.0, 'CONTADO');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (5,  8, 2, 5000.0, 950.0, 10000.0),
    (5, 11, 1, 6500.0,   0.0,  6500.0);
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 8;
UPDATE productos SET stock_actual = stock_actual - 1 WHERE codigo = 11;

-- Cierre de caja primer semana (01 al 07 oct 2024)
INSERT INTO cierres_caja (fecha, total_ventas, total_contado, total_credito, num_ventas, id_usuario, observacion) VALUES
    ('2024-10-07', 85400.0, 33500.0, 52100.0, 4, 1, 'Cierre semanal primera semana de octubre');

-- Pedido adicional pendiente (sin venta asociada aún, como pre-pedido)
INSERT INTO ventas (fecha, id_cliente, id_usuario, subtotal, total_iva, total, tipo_pago, observacion) VALUES
    ('2024-10-09 16:00:00', 1, 2, 9000.0, 0.0, 9000.0, 'CONTADO', 'Pedido telefónico');
INSERT INTO detalle_ventas (id_venta, codigo_prod, cantidad, precio_unit, iva_unit, subtotal) VALUES
    (6, 1, 2, 4500.0, 0.0, 9000.0);
UPDATE productos SET stock_actual = stock_actual - 2 WHERE codigo = 1;

INSERT INTO pedidos (id_venta, id_cliente, id_repartidor, direccion_entrega, estado) VALUES
    (6, 1, 1, 'Cll 45 #23-10 Barrio Centro - Apto 302', 'EN_PREPARACION');

-- ============================================================
--  VISTAS ÚTILES PARA LOS REPORTES
-- ============================================================

-- Vista: estado de cuenta de cartera por cliente
CREATE OR REPLACE VIEW v_estado_cartera AS
SELECT
    cl.id_cliente,
    cl.nombre                AS cliente,
    cl.telefono,
    ca.id_cartera,
    ca.monto_total,
    ca.saldo_actual,
    ca.fecha_inicio,
    ca.fecha_limite,
    ca.estado,
    v.total                  AS valor_venta
FROM cartera ca
JOIN clientes cl ON ca.id_cliente = cl.id_cliente
JOIN ventas   v  ON ca.id_venta   = v.id_venta;

-- Vista: resumen de ventas por día
CREATE OR REPLACE VIEW v_ventas_por_dia AS
SELECT
    DATE(fecha)              AS dia,
    COUNT(*)                 AS num_ventas,
    SUM(subtotal)            AS total_subtotal,
    SUM(total_iva)           AS total_iva,
    SUM(total)               AS total_general,
    SUM(IF(tipo_pago = 'CONTADO', total, 0)) AS contado,
    SUM(IF(tipo_pago = 'CREDITO', total, 0)) AS credito
FROM ventas
WHERE estado = 'ACTIVA'
GROUP BY DATE(fecha);

-- Vista: productos más vendidos
CREATE OR REPLACE VIEW v_productos_mas_vendidos AS
SELECT
    p.codigo,
    p.nombre                 AS producto,
    c.nombre                 AS categoria,
    SUM(dv.cantidad)         AS unidades_vendidas,
    SUM(dv.subtotal)         AS ingresos_totales
FROM detalle_ventas dv
JOIN productos   p  ON dv.codigo_prod = p.codigo
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
GROUP BY p.codigo, p.nombre, c.nombre
ORDER BY unidades_vendidas DESC;

-- Vista: pedidos pendientes con datos de repartidor
CREATE OR REPLACE VIEW v_pedidos_activos AS
SELECT
    pe.id_pedido,
    pe.estado,
    pe.fecha_solicitud,
    pe.direccion_entrega,
    cl.nombre                AS cliente,
    cl.telefono              AS tel_cliente,
    u.nombre                 AS repartidor,
    r.vehiculo
FROM pedidos pe
JOIN clientes    cl ON pe.id_cliente    = cl.id_cliente
LEFT JOIN repartidores r  ON pe.id_repartidor = r.id_repartidor
LEFT JOIN usuarios     u  ON r.id_usuario     = u.id_usuario
WHERE pe.estado NOT IN ('ENTREGADO','CANCELADO');

-- ============================================================
--  CONSULTAS DE VERIFICACIÓN
-- ============================================================
-- Ejecutar individualmente para revisar los datos:

-- SELECT * FROM v_estado_cartera;
-- SELECT * FROM v_ventas_por_dia;
-- SELECT * FROM v_productos_mas_vendidos LIMIT 5;
-- SELECT * FROM v_pedidos_activos;

-- SELECT p.nombre, p.stock_actual, p.stock_minimo,
--        IF(p.stock_actual <= p.stock_minimo, 'ALERTA STOCK BAJO', 'OK') AS estado_stock
-- FROM productos p ORDER BY estado_stock DESC;

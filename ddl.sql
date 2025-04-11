-- Database: proyecto2
-- DROP DATABASE IF EXISTS proyecto2;

CREATE DATABASE proyecto2
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Guatemala.1252'
    LC_CTYPE = 'Spanish_Guatemala.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TYPE estado_evento AS ENUM ('activo', 'cancelado', 'completado');
CREATE TYPE tipo_asiento AS ENUM ('general', 'vip', 'discapacitados');
CREATE TYPE estado_asiento AS ENUM ('disponible', 'reservado', 'ocupado');
CREATE TYPE tipo_usuario AS ENUM ('regular', 'vip', 'admin');
CREATE TYPE estado_reserva AS ENUM ('activa', 'cancelada', 'finalizada');
CREATE TYPE tipo_transaccion AS ENUM ('reserva', 'cancelacion', 'modificacion');

CREATE TABLE Eventos (
    evento_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha TIMESTAMP NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    capacidad_total INT NOT NULL,
    descripcion TEXT,
    estado estado_evento DEFAULT 'activo'
);

CREATE TABLE Asientos (
    asiento_id SERIAL PRIMARY KEY,
    evento_id INT NOT NULL,
    fila VARCHAR(10) NOT NULL,
    numero INT NOT NULL,
    zona VARCHAR(50) NOT NULL,
    tipo tipo_asiento DEFAULT 'general',
    estado estado_asiento DEFAULT 'disponible',
    precio DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (evento_id) REFERENCES Eventos(evento_id),
    UNIQUE (evento_id, fila, numero)
);

CREATE TABLE Usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    tipo tipo_usuario DEFAULT 'regular'
);

CREATE TABLE Reservas (
    reserva_id SERIAL PRIMARY KEY,
    asiento_id INT NOT NULL,
    usuario_id INT NOT NULL,
    evento_id INT NOT NULL,
    fecha_reserva TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado estado_reserva DEFAULT 'activa',
    codigo_reserva VARCHAR(20) UNIQUE NOT NULL,
    FOREIGN KEY (asiento_id) REFERENCES Asientos(asiento_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id),
    FOREIGN KEY (evento_id) REFERENCES Eventos(evento_id)
);

CREATE TABLE Transacciones (
    transaccion_id SERIAL PRIMARY KEY,
    reserva_id INT,
    usuario_id INT NOT NULL,
    tipo tipo_transaccion NOT NULL,
    fecha_transaccion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detalles TEXT,
    FOREIGN KEY (reserva_id) REFERENCES Reservas(reserva_id),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
);


CREATE INDEX idx_asientos_evento ON Asientos(evento_id);
CREATE INDEX idx_reservas_asiento ON Reservas(asiento_id);
CREATE INDEX idx_reservas_usuario ON Reservas(usuario_id);
CREATE INDEX idx_reservas_evento ON Reservas(evento_id);
CREATE INDEX idx_transacciones_usuario ON Transacciones(usuario_id);
CREATE INDEX idx_transacciones_reserva ON Transacciones(reserva_id);

SELECT * FROM Eventos;
SELECT * FROM Asientos;
SELECT * FROM Usuarios;
SELECT * FROM Reservas;
SELECT * FROM Transacciones;
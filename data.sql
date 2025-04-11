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
	
-- 1. Datos tabla Eventos
INSERT INTO Eventos (nombre, fecha, ubicacion, capacidad_total, descripcion, estado)
VALUES 
('Concierto de Rock Nacional', '2023-12-15 20:00:00', 'Estadio Nacional', 5000, 'Concierto de las mejores bandas de rock nacional', 'activo'),
('Obra de Teatro: Hamlet', '2023-11-20 19:30:00', 'Teatro Municipal', 300, 'Clásico de Shakespeare con actores locales', 'activo'),
('Conferencia de Tecnología', '2023-10-10 09:00:00', 'Centro de Convenciones', 800, 'Evento anual de innovación tecnológica', 'activo'),
('Partido de Fútbol: Local vs Visitante', '2023-11-05 15:00:00', 'Estadio Olímpico', 15000, 'Partido de liga nacional', 'activo'),
('Festival de Cine', '2023-12-01 10:00:00', 'Complejo Cinematográfico', 1200, 'Proyección de películas independientes', 'cancelado');

-- 2. Usuarios de prueba
INSERT INTO Usuarios (nombre, email, telefono, tipo)
VALUES
('Juan Pérez', 'juan.perez@email.com', '12345678', 'regular'),
('María González', 'maria.gonzalez@email.com', '87654321', 'vip'),
('Carlos López', 'carlos.lopez@email.com', '55555555', 'regular'),
('Ana Martínez', 'ana.martinez@email.com', '44444444', 'regular'),
('Pedro Sánchez', 'pedro.sanchez@email.com', '33333333', 'admin'),
('Luisa Ramírez', 'luisa.ramirez@email.com', '22222222', 'vip'),
('Roberto Jiménez', 'roberto.jimenez@email.com', '11111111', 'regular'),
('Sofía Hernández', 'sofia.hernandez@email.com', '99999999', 'regular'),
('Miguel Díaz', 'miguel.diaz@email.com', '88888888', 'regular'),
('Laura Castro', 'laura.castro@email.com', '77777777', 'vip');

-- 3. Asientos para el concierto (evento_id = 1)
-- Zona General
INSERT INTO Asientos (evento_id, fila, numero, zona, tipo, precio)
SELECT 1, chr(65 + (i/50)), (i%50)+1, 'General', 'general', 150.00
FROM generate_series(0, 249) AS i;

-- Zona VIP
INSERT INTO Asientos (evento_id, fila, numero, zona, tipo, precio)
SELECT 1, chr(75 + (i/20)), (i%20)+1, 'VIP', 'vip', 350.00
FROM generate_series(0, 99) AS i;

-- 4. Insertar asientos para la obra de teatro (evento_id = 2)
-- Platea
INSERT INTO Asientos (evento_id, fila, numero, zona, tipo, precio)
SELECT 2, chr(65 + (i/15)), (i%15)+1, 'Platea', 'general', 200.00
FROM generate_series(0, 149) AS i;

-- Balcón
INSERT INTO Asientos (evento_id, fila, numero, zona, tipo, precio)
SELECT 2, 'B' || (i/10 + 1), (i%10)+1, 'Balcón', 'vip', 300.00
FROM generate_series(0, 49) AS i;

-- 5. Reservas de prueba
-- Reservas para el concierto
INSERT INTO Reservas (asiento_id, usuario_id, evento_id, estado, codigo_reserva)
VALUES
(5, 1, 1, 'activa', 'RES-' || floor(random() * 1000000)::text || '-1'),
(25, 2, 1, 'activa', 'RES-' || floor(random() * 1000000)::text || '-2'),
(45, 3, 1, 'cancelada', 'RES-' || floor(random() * 1000000)::text || '-3'),
(65, 4, 1, 'activa', 'RES-' || floor(random() * 1000000)::text || '-4'),
(85, 5, 1, 'finalizada', 'RES-' || floor(random() * 1000000)::text || '-5');

-- Reservas para la obra de teatro
INSERT INTO Reservas (asiento_id, usuario_id, evento_id, estado, codigo_reserva)
VALUES
(301, 6, 2, 'activa', 'RES-' || floor(random() * 1000000)::text || '-6'),
(315, 7, 2, 'activa', 'RES-' || floor(random() * 1000000)::text || '-7'),
(325, 8, 2, 'cancelada', 'RES-' || floor(random() * 1000000)::text || '-8'),
(335, 9, 2, 'activa', 'RES-' || floor(random() * 1000000)::text || '-9'),
(345, 10, 2, 'finalizada', 'RES-' || floor(random() * 1000000)::text || '-10');

-- 6. Actualizar estado de los asientos reservados
UPDATE Asientos SET estado = 'reservado' 
WHERE asiento_id IN (SELECT asiento_id FROM Reservas WHERE estado = 'activa');

UPDATE Asientos SET estado = 'ocupado' 
WHERE asiento_id IN (SELECT asiento_id FROM Reservas WHERE estado = 'finalizada');

-- 7. Insertar transacciones de prueba
INSERT INTO Transacciones (reserva_id, usuario_id, tipo, detalles)
SELECT reserva_id, usuario_id, 'reserva', 'Reserva inicial para el evento'
FROM Reservas;

-- Transacciones adicionales para cancelaciones
INSERT INTO Transacciones (reserva_id, usuario_id, tipo, detalles)
SELECT reserva_id, usuario_id, 'cancelacion', 'Cancelación de reserva'
FROM Reservas 
WHERE estado = 'cancelada';

-- Mostrar resumen de datos insertados
SELECT 'Eventos' AS tabla, COUNT(*) AS registros FROM Eventos
UNION ALL
SELECT 'Usuarios', COUNT(*) FROM Usuarios
UNION ALL
SELECT 'Asientos', COUNT(*) FROM Asientos
UNION ALL
SELECT 'Reservas', COUNT(*) FROM Reservas
UNION ALL
SELECT 'Transacciones', COUNT(*) FROM Transacciones;
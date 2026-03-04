-- ==========================================================
-- SCHEMA: Help Desk — Jefatura de Informática
-- Base de datos: helpdesk_db
-- ==========================================================

-- ----------------------------------------------------------
-- 1. TÉCNICOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tecnicos (
    id_tecnico    SERIAL        PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    correo        VARCHAR(150)  NOT NULL UNIQUE,
    especialidad  VARCHAR(100),
    -- Valores: 'Disponible', 'Ocupado', 'Inactivo'
    estado        VARCHAR(20)   NOT NULL DEFAULT 'Disponible',
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- 2. TICKETS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tickets (
    id_ticket            SERIAL        PRIMARY KEY,
    nombre_solicitante   VARCHAR(100)  NOT NULL,
    correo_solicitante   VARCHAR(150)  NOT NULL,
    departamento         VARCHAR(100)  NOT NULL,
    -- Valores: 'Hardware', 'Software', 'Red', 'Otro'
    categoria            VARCHAR(50)   NOT NULL,
    -- Valores: 'Baja', 'Normal', 'Alta', 'Urgente'
    prioridad            VARCHAR(20)   NOT NULL DEFAULT 'Normal',
    descripcion          TEXT          NOT NULL,
    -- Valores: 'Pendiente', 'Asignado', 'En Progreso', 'En Espera', 'Cerrado'
    estado               VARCHAR(30)   NOT NULL DEFAULT 'Pendiente',
    id_tecnico           INTEGER       REFERENCES tecnicos(id_tecnico) ON DELETE SET NULL,
    fecha_creacion       TIMESTAMP     NOT NULL DEFAULT NOW(),
    fecha_asignacion     TIMESTAMP,
    fecha_inicio         TIMESTAMP,
    fecha_cierre         TIMESTAMP,
    observaciones        TEXT
);

-- ----------------------------------------------------------
-- 3. HISTORIAL DE TICKETS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS historial_tickets (
    id_historial     SERIAL        PRIMARY KEY,
    id_ticket        INTEGER       NOT NULL REFERENCES tickets(id_ticket) ON DELETE CASCADE,
    estado_anterior  VARCHAR(30),
    estado_nuevo     VARCHAR(30)   NOT NULL,
    comentario       TEXT,
    -- 'Sistema' o nombre del técnico
    modificado_por   VARCHAR(100)  NOT NULL,
    fecha_cambio     TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- 4. LOGS DE ERRORES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS logs_errores (
    id_error       SERIAL        PRIMARY KEY,
    workflow_name  VARCHAR(100)  NOT NULL,
    nodo           VARCHAR(100),
    mensaje_error  TEXT          NOT NULL,
    datos_entrada  JSONB,
    fecha_error    TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- DATOS INICIALES: Técnicos de ejemplo
-- ----------------------------------------------------------
INSERT INTO tecnicos (nombre, correo, especialidad, estado) VALUES
    ('Carlos Mendoza',  'c.mendoza@informatica.gob',  'Hardware',  'Disponible'),
    ('Ana López',       'a.lopez@informatica.gob',    'Software',  'Disponible'),
    ('Marcos Rivera',   'm.rivera@informatica.gob',   'Redes',     'Disponible')
ON CONFLICT (correo) DO NOTHING;

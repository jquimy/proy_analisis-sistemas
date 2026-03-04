# 🎫 Plan del Proyecto: Help Desk — Soporte de Tickets para la Jefatura de Informática

## 1. Descripción del Problema

La Jefatura de Informática de una institución recibe solicitudes de soporte técnico de los usuarios de las distintas oficinas. Actualmente, estas solicitudes se gestionan de forma desorganizada (llamadas, correos sueltos, mensajes informales), lo que provoca:

- Pérdida de solicitudes y falta de seguimiento.
- Desconocimiento de la disponibilidad de los técnicos.
- Ausencia de reportes históricos y bitácoras de atención.

### Solución Propuesta

Implementar un **sistema de Help Desk automatizado** utilizando **n8n** como motor de workflows, **PostgreSQL** como base de datos local y **Docker** como entorno de ejecución, logrando:

- Recepción estructurada de solicitudes vía formulario web.
- Asignación automática o manual de técnicos según disponibilidad.
- Notificaciones automáticas por correo electrónico al usuario en cada etapa.
- Cierre formal del ticket con bitácora y auditoría.

---

## 2. Stack Tecnológico

| Componente       | Tecnología           | Propósito                                    |
|------------------|----------------------|----------------------------------------------|
| Motor de flujos  | **n8n**              | Orquestación y automatización de los workflows |
| Base de datos    | **PostgreSQL**       | Persistencia local de tickets, técnicos, logs |
| Contenedores     | **Docker Compose**   | Entorno local reproducible                   |
| Admin DB (Opc.)  | **pgAdmin / Adminer**| Visualizar y administrar la base de datos    |
| Correo           | **SMTP local o Gmail**| Envío de notificaciones automáticas          |

---

## 3. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                     DOCKER COMPOSE                      │
│                                                         │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────┐  │
│  │   n8n        │   │ PostgreSQL   │   │  pgAdmin    │  │
│  │  (Puerto     │──▶│  (Puerto     │◀──│  (Puerto    │  │
│  │   5678)      │   │   5432)      │   │   8080)     │  │
│  └──────┬───────┘   └──────────────┘   └─────────────┘  │
│         │                                               │
│         ▼                                               │
│  ┌─────────────────────────────┐                        │
│  │  Carpeta compartida         │                        │
│  │  ./data/files/              │                        │
│  │  (archivos de entrada/salida│                        │
│  │   reportes, logs)           │                        │
│  └─────────────────────────────┘                        │
└─────────────────────────────────────────────────────────┘
         │
         ▼
   ┌───────────┐
   │ Usuario   │  Accede al formulario web en
   │ de Oficina│  http://localhost:5678/form/...
   └───────────┘
```

---

## 4. Estructura de la Base de Datos (PostgreSQL)

### 4.1 Tabla `tecnicos`
Almacena la información de los técnicos de soporte.

```sql
CREATE TABLE tecnicos (
    id_tecnico    SERIAL PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    correo        VARCHAR(150)  NOT NULL UNIQUE,
    especialidad  VARCHAR(100),           -- Ej: "Redes", "Hardware", "Software"
    estado        VARCHAR(20)   NOT NULL DEFAULT 'Disponible',
                                          -- Valores: 'Disponible', 'Ocupado', 'Inactivo'
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW()
);
```

### 4.2 Tabla `tickets`
Registro principal de todas las solicitudes de soporte.

```sql
CREATE TABLE tickets (
    id_ticket         SERIAL PRIMARY KEY,
    nombre_solicitante VARCHAR(100)  NOT NULL,
    correo_solicitante VARCHAR(150)  NOT NULL,
    departamento       VARCHAR(100)  NOT NULL,   -- Ej: "Contabilidad", "RRHH", "Dirección"
    categoria          VARCHAR(50)   NOT NULL,    -- Ej: "Hardware", "Software", "Red", "Otro"
    prioridad          VARCHAR(20)   NOT NULL DEFAULT 'Normal',
                                                  -- Valores: 'Baja', 'Normal', 'Alta', 'Urgente'
    descripcion        TEXT          NOT NULL,
    estado             VARCHAR(30)   NOT NULL DEFAULT 'Pendiente',
                                                  -- Valores: 'Pendiente', 'Asignado',
                                                  -- 'En Progreso', 'En Espera', 'Cerrado'
    id_tecnico         INTEGER       REFERENCES tecnicos(id_tecnico),
    fecha_creacion     TIMESTAMP     NOT NULL DEFAULT NOW(),
    fecha_asignacion   TIMESTAMP,
    fecha_cierre       TIMESTAMP,
    observaciones      TEXT                       -- Notas del técnico al cerrar
);
```

### 4.3 Tabla `historial_tickets`
Bitácora de auditoría que registra cada cambio de estado de un ticket.

```sql
CREATE TABLE historial_tickets (
    id_historial   SERIAL PRIMARY KEY,
    id_ticket      INTEGER       NOT NULL REFERENCES tickets(id_ticket),
    estado_anterior VARCHAR(30),
    estado_nuevo    VARCHAR(30)  NOT NULL,
    comentario      TEXT,
    modificado_por  VARCHAR(100) NOT NULL,  -- 'Sistema' o nombre del técnico
    fecha_cambio    TIMESTAMP    NOT NULL DEFAULT NOW()
);
```

### 4.4 Tabla `logs_errores`
Registro de errores que ocurran en los workflows de n8n (requisito obligatorio del proyecto).

```sql
CREATE TABLE logs_errores (
    id_error       SERIAL PRIMARY KEY,
    workflow_name  VARCHAR(100)  NOT NULL,    -- Nombre del workflow que falló
    nodo           VARCHAR(100),              -- Nodo específico donde ocurrió el error
    mensaje_error  TEXT          NOT NULL,
    datos_entrada  JSONB,                     -- Datos que causaron el error
    fecha_error    TIMESTAMP     NOT NULL DEFAULT NOW()
);
```

### 4.5 Diagrama Entidad-Relación

```
┌──────────────┐       ┌─────────────────────┐
│   tecnicos   │       │      tickets        │
├──────────────┤       ├─────────────────────┤
│ id_tecnico PK│◄──────│ id_tecnico FK       │
│ nombre       │       │ id_ticket PK        │
│ correo       │       │ nombre_solicitante  │
│ especialidad │       │ correo_solicitante  │
│ estado       │       │ departamento        │
│ created_at   │       │ categoria           │
└──────────────┘       │ prioridad           │
                       │ descripcion         │
                       │ estado              │
                       │ fecha_creacion      │
                       │ fecha_asignacion    │
                       │ fecha_cierre        │
                       │ observaciones       │
                       └──────────┬──────────┘
                                  │
                       ┌──────────▼──────────┐
                       │ historial_tickets   │
                       ├─────────────────────┤
                       │ id_historial PK     │
                       │ id_ticket FK        │
                       │ estado_anterior     │
                       │ estado_nuevo        │
                       │ comentario          │
                       │ modificado_por      │
                       │ fecha_cambio        │
                       └─────────────────────┘

┌─────────────────────┐
│   logs_errores      │
├─────────────────────┤
│ id_error PK         │
│ workflow_name       │
│ nodo                │
│ mensaje_error       │
│ datos_entrada       │
│ fecha_error         │
└─────────────────────┘
```

---

## 5. Diseño de Workflows en n8n

### Workflow 1: 📥 Ingesta — Creación de Ticket

**Trigger:** Nodo `n8n Form Trigger` (formulario web accesible en `http://localhost:5678/form/...`)

**Flujo:**
1. **n8n Form Trigger** → El usuario llena: nombre, correo, departamento, categoría, prioridad y descripción del problema.
2. **Nodo Set** → Se formatea la fecha, se establece el estado como `"Pendiente"` y se genera un número de referencia.
3. **Nodo PostgreSQL** → Se inserta el nuevo ticket en la tabla `tickets`.
4. **Nodo PostgreSQL** → Se inserta un registro en `historial_tickets` (estado_nuevo: `"Pendiente"`, modificado_por: `"Sistema"`).
5. **Nodo Send Email** → Se envía un correo al solicitante confirmando la recepción:
   > *"Hemos recibido tu solicitud. Tu número de ticket es #XXX. Te notificaremos cuando un técnico sea asignado."*
6. **Error Trigger** → Si algo falla, se registra en la tabla `logs_errores`.

**Nodos utilizados:** `n8n Form Trigger`, `Set`, `PostgreSQL`, `Send Email`, `Error Trigger`

---

### Workflow 2: ⚙️ Procesamiento — Asignación de Técnico

**Trigger:** Nodo `Cron` (se ejecuta cada 5 minutos) o inmediatamente después de la ingesta.

**Flujo:**
1. **Nodo Cron / Webhook** → Se activa periódicamente.
2. **Nodo PostgreSQL** → Lee todos los tickets con estado `"Pendiente"`.
3. **Nodo IF** → ¿Hay tickets pendientes? Si no hay, el flujo termina.
4. **Nodo PostgreSQL** → Busca técnicos con estado `"Disponible"`.
5. **Nodo IF / Switch** → ¿Hay técnicos disponibles?
   - **SÍ:** Se actualiza el ticket a estado `"Asignado"` con el `id_tecnico` correspondiente, se actualiza la `fecha_asignacion` y se cambia el estado del técnico a `"Ocupado"`. Se registra en `historial_tickets`.
   - **NO:** Se actualiza el ticket a `"En Espera"` y se registra en `historial_tickets`.
6. **Nodo Send Email** → Se envía correo al solicitante:
   - Asignado: *"El técnico [Nombre] ha sido asignado a tu solicitud #XXX y se presentará en tu oficina."*
   - En espera: *"Actualmente todos los técnicos están ocupados. Tu solicitud #XXX está en espera."*
7. **Error Trigger** → Si algo falla, se registra en `logs_errores`.

**Nodos utilizados:** `Cron`, `PostgreSQL`, `IF`, `Switch`, `Set`, `Send Email`, `Error Trigger`

---

### Workflow 3: ✅ Salida — Cierre del Ticket

**Trigger:** Nodo `Webhook` (el técnico accede a una URL especial para cerrar el ticket).

**Flujo:**
1. **Nodo Webhook** → Recibe el `id_ticket` y las `observaciones` del técnico (qué se hizo para resolver).
2. **Nodo PostgreSQL** → Lee el ticket actual para confirmar que existe y su estado.
3. **Nodo IF** → ¿El ticket existe y está en estado `"Asignado"` o `"En Progreso"`?
   - **SÍ:** Continúa al cierre.
   - **NO:** Responde con error (ticket no encontrado o no se puede cerrar).
4. **Nodo PostgreSQL** → Actualiza el ticket: estado → `"Cerrado"`, `fecha_cierre` → ahora, `observaciones` → lo que escribió el técnico.
5. **Nodo PostgreSQL** → Actualiza el técnico: estado → `"Disponible"`.
6. **Nodo PostgreSQL** → Inserta registro en `historial_tickets` (estado_nuevo: `"Cerrado"`, modificado_por: nombre del técnico).
7. **Nodo Send Email** → Se envía correo al solicitante:
   > *"Tu solicitud #XXX ha sido resuelta. Observaciones del técnico: [descripción]. ¡Gracias!"*
8. **Error Trigger** → Si algo falla, se registra en `logs_errores`.

**Nodos utilizados:** `Webhook`, `PostgreSQL`, `IF`, `Set`, `Send Email`, `Error Trigger`

---

## 6. Nodos de n8n Utilizados (Mínimo 6 Requeridos)

| #  | Nodo                 | Uso en el proyecto                              |
|----|----------------------|-------------------------------------------------|
| 1  | `n8n Form Trigger`   | Formulario web para crear tickets               |
| 2  | `Webhook`            | Endpoint para cerrar tickets                    |
| 3  | `Cron / Schedule`    | Ejecución periódica del workflow de asignación   |
| 4  | `PostgreSQL`         | Lectura/escritura en la base de datos           |
| 5  | `IF`                 | Condiciones (¿hay técnico disponible?, etc.)    |
| 6  | `Switch`             | Enrutamiento por categoría o prioridad          |
| 7  | `Set`                | Formateo de datos y variables                   |
| 8  | `Send Email`         | Notificaciones al solicitante                   |
| 9  | `Error Trigger`      | Captura de errores (Try/Catch)                  |

> ✅ **Total: 9 nodos distintos** (supera el mínimo de 6 requeridos).

---

## 7. Manejo de Errores

Cada workflow tiene un flujo alterno de error:

1. Se utiliza el nodo **Error Trigger** como "catch" global de cada workflow.
2. Cuando un error ocurre, el flujo alterno:
   - Captura el nombre del workflow, el nodo que falló y el mensaje de error.
   - Inserta un registro en la tabla **`logs_errores`** de PostgreSQL.
   - (Opcional) Envía un correo de alerta al administrador del sistema.

---

## 8. Seguridad

- **Variables de entorno:** Todas las credenciales (contraseña de PostgreSQL, credenciales SMTP) se configuran como variables de entorno en el archivo `docker-compose.yml` o en un archivo `.env`. **Nunca se hardcodean contraseñas en los workflows.**
- **Credenciales de n8n:** Se configuran mediante el sistema de credenciales integrado de n8n (encriptado).
- **Archivo `.env`** para almacenar:
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
  - `POSTGRES_DB`
  - `N8N_BASIC_AUTH_USER`
  - `N8N_BASIC_AUTH_PASSWORD`
  - `SMTP_USER`
  - `SMTP_PASSWORD`

---

## 9. Estructura del Repositorio

```
PROYECTO-HELP-DESK/
├── docker-compose.yml          # Levanta n8n + PostgreSQL + pgAdmin
├── .env                        # Variables de entorno (NO subir a Git)
├── .gitignore                  # Ignorar .env, node_modules, etc.
├── README.md                   # Instrucciones de instalación y uso
├── init-db/
│   └── 01-schema.sql           # Script SQL para crear las tablas
├── workflows/
│   ├── 01-ingesta-ticket.json  # Exportación del Workflow 1
│   ├── 02-asignacion.json      # Exportación del Workflow 2
│   └── 03-cierre-ticket.json   # Exportación del Workflow 3
├── data/
│   └── files/                  # Carpeta compartida para archivos
├── docs/
│   ├── documentacion-tecnica.pdf
│   ├── diagrama-arquitectura.png
│   └── diagrama-workflow.png
└── video/
    └── README.md               # Enlace al video demo en Google Drive
```

---

## 10. Docker Compose (Estructura Base)

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./data/files:/files
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d

  pgadmin:
    image: dpage/pgadmin4:latest
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@helpdesk.local
      - PGADMIN_DEFAULT_PASSWORD=admin123

volumes:
  n8n_data:
  postgres_data:
```

---

## 11. Plan de Verificación y Pruebas

### Caso 1: Caso Normal (Happy Path)
1. Un usuario llena el formulario → se crea el ticket en PostgreSQL → se recibe correo de confirmación.
2. El workflow de asignación detecta el ticket pendiente → asigna un técnico disponible → se recibe correo de asignación.
3. El técnico cierra el ticket vía webhook → el ticket cambia a "Cerrado" → el usuario recibe correo de cierre.

### Caso 2: Caso con Error
1. Se envía un formulario con datos inválidos o incompletos → el Error Trigger captura el fallo → se registra en `logs_errores`.
2. Se intenta cerrar un ticket que no existe → el nodo IF detecta la inconsistencia → se responde con un mensaje de error.

### Caso 3: Sin Técnicos Disponibles
1. Se crean más tickets que técnicos disponibles → el nodo IF detecta que no hay técnicos → el ticket queda en estado "En Espera" → el usuario recibe correo indicando la espera.

---

## 12. Cronograma Sugerido

| Semana   | Actividad                                                    |
|----------|--------------------------------------------------------------|
| 1–2      | Montaje del entorno Docker, creación de tablas en PostgreSQL |
| 3–5      | Workflow 1 (Ingesta) y Workflow 2 (Asignación) funcionando   |
| 6–8      | Workflow 3 (Cierre), manejo de errores, +6 nodos integrados  |
| 9–11     | Pruebas completas, seguridad con `.env`, documentación       |
| 12–14    | Video demo, README final, refinamiento del repositorio       |

# Help Desk — Sistema Automatizado de Soporte Técnico
### Jefatura de Informática · Municipalidad de San Juan Chamelco, Alta Verapaz

Sistema automatizado de gestión de tickets de soporte técnico construido con **n8n**, **PostgreSQL** y **Docker**.

---

## Tabla de Contenidos

1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Arquitectura](#-arquitectura)
3. [Estructura del Repositorio](#-estructura-del-repositorio)
4. [Requisitos Previos](#-requisitos-previos)
5. [Instalación y Puesta en Marcha](#-instalación-y-puesta-en-marcha)
6. [Workflows](#-workflows)
7. [Notificaciones por Correo](#-notificaciones-por-correo)
8. [Casos de Prueba](#-casos-de-prueba)
9. [Seguridad](#-seguridad)
10. [Referencias](#-referencias)
11. [Subir el Proyecto a Git](#-subir-el-proyecto-a-git)

---

## Descripción del Proyecto

La Jefatura de Informática recibía solicitudes de soporte técnico a través de canales informales (llamadas y mensajes), lo que provocaba pérdida de solicitudes, falta de seguimiento y ausencia de bitácoras.

Este proyecto implementa un **Help Desk Automatizado** que cubre el ciclo de vida completo de un ticket:

- Recepción estructurada vía formulario web
- Asignación automática de técnicos según disponibilidad (Cron cada 5 min)
- Notificaciones por correo al solicitante y al técnico en cada etapa
- Cierre formal del ticket con registro de observaciones
- Encuesta de satisfacción post-cierre
- Bitácora de historial de cambios y registro de errores del sistema

---

## Arquitectura

```
┌────────────────────────────────────────────────────┐
│                 Host Windows (Local)                │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │         Docker (Motor de Contenedores)       │   │
│  │                                             │   │
│  │  ┌──────────────────────────────────────┐   │   │
│  │  │  helpdesk_n8n  (n8nio/n8n:latest)    │   │   │
│  │  │  Puerto expuesto: 5678               │   │   │
│  │  │  Volumen: n8n_data                   │   │   │
│  │  └──────────┬────────────────────────────┘  │   │
│  │             │ host.docker.internal:5432      │   │
│  └─────────────┼───────────────────────────────┘   │
│                │                                    │
│  ┌─────────────▼────────────────────────────────┐  │
│  │  PostgreSQL (instalado en el host)            │  │
│  │  Base de datos: helpdesk_db                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  Gmail SMTP → Notificaciones automáticas        │
└────────────────────────────────────────────────────┘
```

---

## Estructura del Repositorio

```
n8npro/
├── docker-compose.yml          # Orquestación del contenedor n8n
├── .env                        # Variables de entorno (NO subir a Git)
├── .gitignore                  # Exclusiones del repositorio
├── README.md                   # Este archivo
├── init-db/
│   └── 01-schema.sql           # Creación de tablas y datos iniciales
├── workflows/
│   ├── 01-ingesta-ticket.json  # WF1: Formulario de recepción de tickets
│   ├── 02-asignacion.json      # WF2: Asignación automática por Cron
│   ├── 03-cierre-ticket.json   # WF3: Cierre de ticket por técnico
│   ├── 04a-encuesta-form.json  # WF4a: Servir formulario de encuesta
│   └── 04b-encuesta-proceso.json # WF4b: Procesar respuesta de encuesta
├── docs/
│   ├── documentacion-tecnica.md  # Documentación técnica completa
│   ├── diagrama-arquitectura.md  # Diagrama de arquitectura del sistema
│   └── casos_prueba.md           # Casos de prueba ejecutados
├── data/
│   └── files/                  # Carpeta compartida n8n ↔ host
└── video/
    └── README.md               # Enlace al video demo
```

---

## Requisitos Previos

| Componente | Versión recomendada | Notas |
|-----------|--------------------|----|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Última estable | Debe estar corriendo antes de ejecutar el proyecto |
| [PostgreSQL](https://www.postgresql.org/download/windows/) | 14 o superior | Instalado en el host (no en Docker) |
| Cuenta Gmail con [Contraseña de Aplicación](https://myaccount.google.com/apppasswords) | — | Para el envío de correos SMTP |

---

## Instalación y Puesta en Marcha

### Paso 1 — Clonar el repositorio

```bash
git clone <url-del-repo>
cd n8npro
```

### Paso 2 — Crear la base de datos en PostgreSQL

Conéctate a tu instancia local de PostgreSQL y ejecuta:

```sql
CREATE DATABASE helpdesk_db;
```

Luego, aplica el schema:

```bash
psql -U <tu_usuario> -d helpdesk_db -f init-db/01-schema.sql
```

### Paso 3 — Configurar las variables de entorno

Crea el archivo ".env" en la raíz del proyecto (copia el ejemplo y completa con tus datos):

```env
# Conexión a PostgreSQL (instalado en el host)
POSTGRES_DB=helpdesk_db
POSTGRES_USER=<tu_usuario_postgres>
POSTGRES_PASSWORD=<tu_contraseña_postgres>

# Autenticación básica de n8n
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<tu_contraseña_n8n>
```

### Paso 4 — Levantar el contenedor

```bash
docker compose up -d
```

### Paso 5 — Verificar que el contenedor esté corriendo

```bash
docker compose ps
```

### Paso 6 — Acceder a los servicios

| Servicio | URL | Credenciales |
|----------|-----|-------------|
| n8n | http://localhost:5678 | Las definidas en ".env" ("N8N_BASIC_AUTH_USER / PASSWORD") |

### Paso 7 — Configurar credenciales en n8n

Dentro de n8n, antes de importar los workflows, crea las credenciales:

1. **PostgreSQL:** Ve a *Settings → Credentials → New → PostgreSQL*
   - Host: "host.docker.internal"
   - Port: "5432"
   - Database: "helpdesk_db"
   - User / Password: los de tu ".env"

2. **SMTP (Gmail):** Ve a *Settings → Credentials → New → SMTP*
   - Host: "smtp.gmail.com"
   - Port: "465"
   - User: tu correo Gmail
   - Password: tu Contraseña de Aplicación de Google

### Paso 8 — Importar los workflows

- Abre n8n → Menú (☰) → **Import from File**
- Importa en orden los archivos de la carpeta "workflows/":
  1. "01-ingesta-ticket.json"
  2. "02-asignacion.json"
  3. "03-cierre-ticket.json"
  4. "04a-encuesta-form.json"
  5. "04b-encuesta-proceso.json"
- Asigna las credenciales creadas a los nodos de PostgreSQL y Email de cada workflow
- **Activa** cada workflow con el toggle de la esquina superior derecha

---

## Detener el Entorno

```bash
# Solo detiene el contenedor (los datos se conservan)
docker compose down

# Detiene y elimina también los volúmenes (borra los datos de n8n)
docker compose down -v
```

---

## Workflows

| # | Nombre | Archivo | Trigger | Descripción |
|---|--------|---------|---------|-------------|
| WF1 | Ingesta de Ticket | "01-ingesta-ticket.json" | Form n8n | El usuario crea un ticket vía formulario web |
| WF2 | Asignación de Técnico | "02-asignacion.json" | Cron (cada 5 min) | Asigna automáticamente un técnico disponible |
| WF3 | Cierre de Ticket | "03-cierre-ticket.json" | Form n8n | El técnico registra la solución y cierra el ticket |
| WF4a | Encuesta: Formulario | "04a-encuesta-form.json" | Webhook GET | Sirve el formulario HTML de satisfacción |
| WF4b | Encuesta: Proceso | "04b-encuesta-proceso.json" | Webhook POST | Guarda la respuesta y notifica al técnico |

---

## Notificaciones por Correo

Se envían correos automáticos al solicitante en 3 momentos clave:

1. **Ticket creado** — Confirmación de recepción con número de ticket
2. **Técnico asignado** — Nombre del técnico asignado (o aviso de espera si no hay disponibles)
3. **Ticket cerrado** — Observaciones de la solución + enlace a encuesta de satisfacción

El técnico también recibe correo al ser asignado y al recibir la calificación de la encuesta.

---

## Casos de Prueba

Ver el archivo ["docs/casos_prueba.md"](docs/casos_prueba.md) para el detalle completo.

| ID | Escenario | Estado |
|----|-----------|--------|
| CP-01 | Ingesta de ticket válida (Happy Path) | Exitoso |
| CP-02 | Asignación automática con técnico disponible | Exitoso |
| CP-03 | Cierre de ticket con observaciones | Exitoso |
| CE-01 | Intentar cerrar ticket inexistente o ya cerrado | Protegido |
| CE-02 | Más tickets que técnicos disponibles | Flujo alterno validado |
| CE-03 | Fallo del servicio SMTP | Persistencia consistente |

---

## Seguridad

- Todas las credenciales están en ".env" (excluido de Git mediante ".gitignore")
- Las credenciales de PostgreSQL y SMTP se configuran en el sistema de credenciales **encriptado** de n8n
- **Nunca se hardcodean** contraseñas en los workflows
- El acceso a n8n está protegido con autenticación básica HTTP
- La red Docker "helpdesk_net" aísla el contenedor del resto del sistema

---

## Referencias

1. [Documentación Oficial de n8n](https://docs.n8n.io/)
2. [n8n con Docker Compose](https://docs.n8n.io/hosting/installation/docker/)
3. [PostgreSQL: CREATE TABLE](https://www.postgresql.org/docs/current/sql-createtable.html)
4. [Google: Contraseñas de Aplicación Gmail](https://support.google.com/accounts/answer/185833)
5. [The Twelve-Factor App — Config](https://12factor.net/config)

---

## Subir el Proyecto a Git

Sigue estos pasos para publicar tu proyecto en GitHub desde cero:

### Paso 1 — Verifica que ".env" esté en ".gitignore"

```bash
# Comprueba que el .env no será subido
cat .gitignore
# Debe aparecer la línea: .env
```

### Paso 2 — Inicializa Git (si aún no lo has hecho)

```bash
git init
```

### Paso 3 — Conecta tu repositorio remoto

Primero crea un repositorio **vacío** en [github.com](https://github.com) (sin README, sin .gitignore). Luego:

```bash
git remote add origin https://github.com/<tu-usuario>/<nombre-del-repo>.git
```

### Paso 4 — Agrega todos los archivos al staging

```bash
git add .
```

### Paso 5 — Verifica qué archivos se van a subir

```bash
git status
```

> Asegúrate de que ".env" **NO** aparezca en la lista de archivos a subir.

### Paso 6 — Crea el primer commit

```bash
git commit -m "feat: proyecto completo Help Desk n8n - Municipalidad San Juan Chamelco"
```

### Paso 7 — Sube al repositorio remoto

```bash
git push -u origin main
```

> Si tu rama principal se llama "master", usa "git push -u origin master"

### Paso 8 — Verifica en GitHub

Abre tu repositorio en el navegador y confirma que todos los archivos subieron correctamente:
- "docker-compose.yml"
- "README.md"
- "init-db/01-schesma.sql"
- "workflows/*.json" (los 5 workflows)
- "docs/" (documentación)
- ".env" **NO debe aparecer**
- "data/" **NO debe aparecer**

### Comandos para actualizaciones futuras

```bash
# Después de hacer cambios:
git add .
git commit -m "descripción de los cambios"
git push
```

---

*Municipalidad de San Juan Chamelco, Alta Verapaz — Jefatura de Informática*

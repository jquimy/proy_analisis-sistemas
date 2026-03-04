# 🎫 Help Desk — Soporte de Tickets para la Jefatura de Informática

Sistema automatizado de gestión de tickets de soporte técnico usando **n8n**, **PostgreSQL** y **Docker**.

---

## 🗂️ Estructura del Proyecto

```
SERVIDOR_NUNCA/
├── docker-compose.yml        # Orquestación de contenedores
├── .env                      # Variables de entorno (NO subir a Git)
├── .gitignore
├── README.md
├── init-db/
│   └── 01-schema.sql         # Creación de tablas y datos iniciales
├── workflows/
│   ├── 01-ingesta-ticket.json
│   ├── 02-asignacion.json
│   └── 03-cierre-ticket.json
├── data/
│   └── files/                # Carpeta compartida n8n ↔ host
├── docs/                     # Documentación técnica y diagramas
└── video/
    └── README.md             # Enlace al video demo
```

---

## 🚀 Instalación y Puesta en Marcha

### Requisitos previos
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo

### Pasos

1. **Clona el repositorio**
   ```bash
   git clone <url-del-repo>
   cd SERVIDOR_NUNCA
   ```

2. **Configura las variables de entorno**
   ```bash
   # Edita el archivo .env con tus credenciales reales
   notepad .env
   ```

3. **Levanta los contenedores**
   ```bash
   docker compose up -d
   ```

4. **Verifica que todo esté corriendo**
   ```bash
   docker compose ps
   ```

5. **Accede a los servicios**

   | Servicio   | URL                     | Credenciales (ver .env)        |
   |------------|-------------------------|--------------------------------|
   | n8n        | http://localhost:5678   | N8N_BASIC_AUTH_USER/PASSWORD   |
   | pgAdmin    | http://localhost:8080   | PGADMIN_EMAIL/PASSWORD         |

6. **Importa los workflows en n8n**
   - Abre n8n → Menú → Import from File
   - Importa los archivos de la carpeta `workflows/`

---

## 🛑 Detener el entorno

```bash
docker compose down
```

Para eliminar también los volúmenes (borra todos los datos):
```bash
docker compose down -v
```

---

## 🏗️ Workflows

| # | Nombre | Trigger | Descripción |
|---|--------|---------|-------------|
| 1 | Ingesta de Ticket | Form n8n | El usuario crea un ticket vía formulario web |
| 2 | Asignación de Técnico | Webhook / Cron | Asigna automáticamente un técnico disponible |
| 3 | Cierre de Ticket | Webhook | El técnico registra la solución y cierra el ticket |

---

## 📧 Notificaciones por Correo

Se envían correos automáticos al solicitante en 3 momentos:
1. ✅ Ticket creado (confirmación de recepción)
2. 👨‍🔧 Técnico asignado (o en espera)
3. 🎉 Ticket cerrado (con observaciones del técnico)

---

## 🔒 Seguridad

- Todas las credenciales están en `.env` (excluido de Git).
- Las credenciales de n8n y SMTP se configuran en el sistema de credenciales encriptado de n8n.
- **Nunca hardcodear contraseñas en los workflows.**

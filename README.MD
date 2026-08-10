# Sistema Automatizado de Copias de Seguridad - Shell Scripting

## 📌 Descripción

Proyecto final desarrollado para la asignatura **Shell Scripting** del Instituto Tecnológico IDAT.

El proyecto consiste en un sistema automatizado de copias de seguridad desarrollado en **Bash sobre Ubuntu Linux**. La solución permite realizar respaldos de directorios importantes, generar archivos comprimidos, crear huellas SHA-256, registrar las operaciones realizadas y generar reportes de auditoría.

Además, el sistema incorpora un menú interactivo para facilitar su utilización y permite programar las tareas automáticamente mediante **Cron**.

---

## 🎯 Objetivo

Desarrollar una solución en Shell Script que permita automatizar el proceso de copias de seguridad de directorios importantes, reduciendo la intervención manual y proporcionando mecanismos de validación, registro, control de errores y auditoría.

### Objetivos específicos

- Automatizar la creación de copias de seguridad.
- Validar las rutas antes de realizar el respaldo.
- Comprimir los respaldos utilizando `tar`.
- Generar huellas SHA-256.
- Registrar las operaciones mediante archivos de log.
- Generar reportes de auditoría.
- Permitir la interacción mediante un menú.
- Automatizar las tareas mediante Cron.
- Evitar la duplicación de tareas Cron.
- Aplicar una política de retención de backups antiguos.

---

# 🖥️ Entorno utilizado

- **Sistema operativo:** Ubuntu Linux
- **Lenguaje:** Bash / Shell Script
- **Editor:** Nano
- **Control de versiones:** Git
- **Repositorio:** GitHub
- **Automatización:** Cron

---

# 📂 Estructura del proyecto

```text
ExamenFinal/
│
├── backups/
│   └── Copias de seguridad generadas
│
├── config/
│   └── rutas.conf
│
├── datos/
│   ├── clientes.txt
│   └── operaciones.txt
│
├── documentos_clave/
│   ├── finanzas.txt
│   └── documentacion.txt
│
├── logs/
│   ├── backup.log
│   └── cron.log
│
├── reportes/
│   └── Reportes de auditoría
│
└── scripts/
    ├── 01_respaldo_seguro.sh
    ├── 02_reporte_auditoria.sh
    └── 03_control_respaldo.sh

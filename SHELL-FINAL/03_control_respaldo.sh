#!/bin/bash

# Este script funciona como centro de control del proyecto.
#
# Permite:
# 1. Ejecutar un backup.
# 2. Generar un reporte.
# 3. Ejecutar backup y reporte juntos.
# 4. Consultar el último reporte.
# 5. Consultar los últimos eventos.
# 6. Activar el backup diario.
# 7. Desactivar el backup diario.
# 8. Consultar el estado de Cron.

# Obtenemos la carpeta principal del proyecto.
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Definimos las rutas de los scripts.
BACKUP_SCRIPT="$BASE_DIR/scripts/01_respaldo_seguro.sh"
REPORT_SCRIPT="$BASE_DIR/scripts/02_reporte_auditoria.sh"

# Identificador utilizado para reconocer nuestras tareas Cron.
CRON_TAG="SHELL_BACKUP_FINAL"

# Verificamos que los scripts existan.
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "[ERROR] No existe el script de backup."
    exit 1
fi

if [ ! -f "$REPORT_SCRIPT" ]; then
    echo "[ERROR] No existe el script de reporte."
    exit 1
fi

# Ejecuta el proceso de backup.
ejecutar_backup() {

    echo
    echo "[INFO] Ejecutando backup..."
    echo

    if "$BACKUP_SCRIPT"; then
        echo
        echo "[OK] Backup terminado correctamente."
    else
        echo
        echo "[ADVERTENCIA] El backup terminó con errores."
    fi
}

# Ejecuta la generación del reporte.
generar_reporte() {

    echo
    echo "[INFO] Generando reporte..."

    if "$REPORT_SCRIPT"; then
        echo "[OK] Reporte generado correctamente."
    else
        echo "[ERROR] No se pudo generar el reporte."
    fi
}

# Ejecuta backup y reporte consecutivamente.
ejecutar_completo() {

    echo
    echo "============================================="
    echo "       EJECUCIÓN COMPLETA DEL SISTEMA"
    echo "============================================="

    ejecutar_backup
    generar_reporte

    echo
    echo "[OK] Proceso completo finalizado."
}

# Activa las tareas automáticas de Cron.
activar_cron() {

    # Evitamos crear tareas duplicadas.
    if crontab -l 2>/dev/null | grep -Fq "$CRON_TAG"; then
        echo "[INFO] La automatización ya está activa."
        return
    fi

    # Backup diario a las 02:00.
    # Reporte diario a las 02:05.
    (
        crontab -l 2>/dev/null
        echo "0 2 * * * $BACKUP_SCRIPT >> $BASE_DIR/logs/cron.log 2>&1 # $CRON_TAG"
        echo "5 2 * * * $REPORT_SCRIPT >> $BASE_DIR/logs/cron.log 2>&1 # $CRON_TAG"
    ) | crontab -

    echo "[OK] Automatización activada."
    echo
    echo "Backup : todos los días a las 02:00"
    echo "Reporte: todos los días a las 02:05"
}

# Desactiva únicamente las tareas creadas por este proyecto.
desactivar_cron() {

    if ! crontab -l 2>/dev/null | grep -Fq "$CRON_TAG"; then
        echo "[INFO] La automatización ya está desactivada."
        return
    fi

    crontab -l 2>/dev/null |
        grep -vF "$CRON_TAG" |
        crontab -

    echo "[OK] Automatización desactivada."
}

# Muestra el estado actual de Cron.
mostrar_estado_cron() {

    echo
    echo "============================================="
    echo "        ESTADO DE AUTOMATIZACIÓN"
    echo "============================================="

    if crontab -l 2>/dev/null | grep -Fq "$CRON_TAG"; then

        echo "[ACTIVO] Backup automático configurado."
        echo

        crontab -l 2>/dev/null |
            grep -F "$CRON_TAG"

    else

        echo "[INACTIVO] No existe automatización configurada."

    fi
}

# Muestra el último reporte generado.
mostrar_ultimo_reporte() {

    ULTIMO="$(
        find "$BASE_DIR/reportes" \
            -type f \
            -name 'reporte_backup_*.txt' \
            -printf '%T@ %p\n' 2>/dev/null |
            sort -nr |
            head -n 1 |
            cut -d' ' -f2-
    )"

    if [ -n "$ULTIMO" ]; then
        cat "$ULTIMO"
    else
        echo "[INFO] No existe ningún reporte."
    fi
}

# Muestra los últimos eventos registrados.
mostrar_log() {

    if [ -f "$BASE_DIR/logs/backup.log" ]; then
        tail -n 20 "$BASE_DIR/logs/backup.log"
    else
        echo "[INFO] Todavía no existe ningún log."
    fi
}

# Menú principal.
while true; do

    clear

    echo "============================================="
    echo "       SISTEMA DE RESPALDO AUTOMATIZADO"
    echo "============================================="
    echo
    echo "1. Ejecutar backup ahora"
    echo "2. Generar reporte"
    echo "3. Ejecutar backup + reporte"
    echo "4. Ver último reporte"
    echo "5. Ver últimos eventos"
    echo "6. Activar backup diario"
    echo "7. Desactivar backup diario"
    echo "8. Ver estado de automatización"
    echo "0. Salir"
    echo
    echo "---------------------------------------------"

    read -rp "Seleccione una opción: " OPCION

    case "$OPCION" in

        1)
            ejecutar_backup
            ;;

        2)
            generar_reporte
            ;;

        3)
            ejecutar_completo
            ;;

        4)
            echo
            echo "========== ÚLTIMO REPORTE =========="
            mostrar_ultimo_reporte
            ;;

        5)
            echo
            echo "========== ÚLTIMOS EVENTOS =========="
            mostrar_log
            ;;

        6)
            activar_cron
            ;;

        7)
            desactivar_cron
            ;;

        8)
            mostrar_estado_cron
            ;;

        0)
            echo
            echo "Saliendo del sistema..."
            exit 0
            ;;

        *)
            echo
            echo "[ERROR] Opción inválida."
            ;;

    esac

    echo
    read -rp "Presione ENTER para continuar..."

done
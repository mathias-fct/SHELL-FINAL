#!/bin/bash

# Este script genera un reporte de auditoría utilizando
# la información registrada por el sistema de backups.
#
# El reporte se guarda en la carpeta reportes/.
#
# El reporte muestra:
# - Estado general.
# - Backups exitosos.
# - Errores.
# - Cantidad de backups disponibles.
# - Último backup.
# - Últimos eventos registrados.

# Obtenemos la carpeta principal del proyecto.
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Definimos las rutas que utilizaremos.
LOG_FILE="$BASE_DIR/logs/backup.log"
BACKUP_DIR="$BASE_DIR/backups"
REPORT_DIR="$BASE_DIR/reportes"

# Creamos la carpeta de reportes si no existe.
mkdir -p "$REPORT_DIR"

# Verificamos que exista el log.
if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] No existe el archivo de log."
    echo "Primero ejecute el script de backup."
    exit 1
fi

# Generamos una fecha para identificar el reporte.
FECHA="$(date '+%Y%m%d_%H%M%S')"

REPORT_FILE="$REPORT_DIR/reporte_backup_$FECHA.txt"

# Contamos los backups exitosos registrados.
BACKUPS_OK="$(
    grep -c '\[OK\] Backup creado:' "$LOG_FILE" 2>/dev/null || true
)"

# Contamos los errores registrados.
ERRORES="$(
    grep -c '\[ERROR\]' "$LOG_FILE" 2>/dev/null || true
)"

# Contamos los archivos de backup disponibles.
TOTAL_BACKUPS="$(
    find "$BACKUP_DIR" \
        -type f \
        -name 'backup_*.tar.gz' |
        wc -l
)"

# Buscamos el backup más reciente.
ULTIMO_BACKUP="$(
    find "$BACKUP_DIR" \
        -type f \
        -name 'backup_*.tar.gz' \
        -printf '%T@ %p\n' 2>/dev/null |
        sort -nr |
        head -n 1 |
        cut -d' ' -f2-
)"

# Si no existe ningún backup mostramos un mensaje.
if [ -z "$ULTIMO_BACKUP" ]; then
    ULTIMO_BACKUP="No existen backups disponibles."
fi

# Determinamos el estado general del sistema.
if [ "$BACKUPS_OK" -gt 0 ] && [ "$ERRORES" -eq 0 ]; then
    ESTADO="CORRECTO"
elif [ "$BACKUPS_OK" -gt 0 ] && [ "$ERRORES" -gt 0 ]; then
    ESTADO="CORRECTO CON ADVERTENCIAS"
else
    ESTADO="CON ERRORES"
fi

# Creamos el reporte.
cat > "$REPORT_FILE" <<EOF
=============================================
       REPORTE DE AUDITORÍA DE BACKUPS
=============================================

Fecha:
$(date '+%d/%m/%Y %H:%M:%S')

ESTADO GENERAL
---------------------------------------------
$ESTADO

RESUMEN
---------------------------------------------
Backups exitosos : $BACKUPS_OK
Errores          : $ERRORES
Backups actuales : $TOTAL_BACKUPS

ÚLTIMO BACKUP
---------------------------------------------
$ULTIMO_BACKUP

ARCHIVOS DE BACKUP
---------------------------------------------
EOF

# Añadimos los backups disponibles al reporte.
find "$BACKUP_DIR" \
    -type f \
    -name 'backup_*.tar.gz' \
    -printf '%TY-%Tm-%Td %TH:%TM:%TS | %f | %s bytes\n' |
    sort -r >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

ÚLTIMOS EVENTOS
---------------------------------------------
EOF

# Añadimos los últimos 15 eventos del log.
tail -n 15 "$LOG_FILE" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

=============================================
FIN DEL REPORTE
=============================================
EOF

echo "[OK] Reporte generado correctamente."
echo
echo "Reporte:"
echo "$REPORT_FILE"
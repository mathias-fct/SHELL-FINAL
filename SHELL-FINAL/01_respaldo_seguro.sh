#!/bin/bash

# Este script realiza copias de seguridad de las rutas
# definidas en config/rutas.conf.
#
# El proceso:
# - Valida la configuración.
# - Comprueba que las rutas existan.
# - Crea backups comprimidos.
# - Genera una huella SHA-256.
# - Registra cada operación en un log.
# - Elimina backups antiguos según la política de retención.

# Obtenemos la carpeta principal del proyecto.
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Definimos las carpetas y archivos que utilizaremos.
CONFIG_FILE="$BASE_DIR/config/rutas.conf"
BACKUP_DIR="$BASE_DIR/backups"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"

# Cantidad máxima de backups que se conservarán.
RETENCION=7

# Creamos las carpetas necesarias si no existen.
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Función utilizada para guardar información en el log.
registrar_log() {
    local nivel="$1"
    local mensaje="$2"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$nivel] $mensaje" >> "$LOG_FILE"
}

# Verificamos que las herramientas necesarias estén instaladas.
for comando in tar sha256sum find grep sed awk; do
    if ! command -v "$comando" >/dev/null 2>&1; then
        echo "[ERROR] No se encontró la herramienta: $comando"
        registrar_log "ERROR" "Herramienta no encontrada: $comando"
        exit 1
    fi
done

# Verificamos que exista el archivo de configuración.
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] No existe: $CONFIG_FILE"
    registrar_log "ERROR" "No existe el archivo de configuración."
    exit 1
fi

# Verificamos que la configuración tenga al menos una ruta.
if ! grep -q '[^[:space:]#]' "$CONFIG_FILE"; then
    echo "[ERROR] No hay rutas configuradas."
    registrar_log "ERROR" "El archivo de configuración está vacío."
    exit 1
fi

# Leemos las rutas ignorando comentarios y líneas vacías.
mapfile -t RUTAS < <(
    grep -vE '^[[:space:]]*(#|$)' "$CONFIG_FILE"
)

# Contadores para el resumen final.
TOTAL=0
EXITOSOS=0
ERRORES=0

echo "=============================================="
echo "       SISTEMA DE RESPALDO AUTOMATIZADO"
echo "=============================================="
echo "Inicio: $(date '+%Y-%m-%d %H:%M:%S')"
echo

registrar_log "INFO" "Inicio del proceso de respaldo."

# Procesamos cada ruta configurada.
for RUTA in "${RUTAS[@]}"; do

    # Eliminamos espacios innecesarios.
    RUTA="$(echo "$RUTA" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    ((TOTAL++))

    echo "----------------------------------------------"
    echo "Ruta: $RUTA"

    # Verificamos que la ruta exista y sea un directorio.
    if [ ! -d "$RUTA" ]; then
        echo "[ERROR] El directorio no existe."
        registrar_log "ERROR" "Directorio inexistente: $RUTA"
        ((ERRORES++))
        continue
    fi

    # Verificamos que tengamos permiso de lectura.
    if [ ! -r "$RUTA" ]; then
        echo "[ERROR] No tenemos permisos de lectura."
        registrar_log "ERROR" "Sin permisos de lectura: $RUTA"
        ((ERRORES++))
        continue
    fi

    # Obtenemos el nombre del directorio.
    NOMBRE="$(basename "$RUTA")"

    # Generamos una fecha para identificar el backup.
    FECHA="$(date '+%Y%m%d_%H%M%S')"

    # Definimos el nombre del archivo de backup.
    ARCHIVO_BACKUP="$BACKUP_DIR/backup_${NOMBRE}_${FECHA}.tar.gz"

    echo "[INFO] Creando respaldo..."

    # Creamos el archivo comprimido.
    #
    # -c = crear
    # -z = comprimir con gzip
    # -f = indicar el archivo de salida
    if tar -czf "$ARCHIVO_BACKUP" \
        -C "$(dirname "$RUTA")" "$NOMBRE" \
        2>/tmp/backup_error.tmp; then

        # Verificamos que el backup exista y tenga contenido.
        if [ -s "$ARCHIVO_BACKUP" ]; then

            echo "[OK] Backup creado:"
            echo "     $ARCHIVO_BACKUP"

            # Generamos una huella SHA-256 del backup.
            sha256sum "$ARCHIVO_BACKUP" > "$ARCHIVO_BACKUP.sha256"

            # Obtenemos el tamaño del archivo.
            TAMANO="$(du -h "$ARCHIVO_BACKUP" | awk '{print $1}')"

            echo "[OK] SHA-256 generado."
            echo "[OK] Tamaño: $TAMANO"

            registrar_log \
                "OK" \
                "Backup creado: $ARCHIVO_BACKUP | Tamaño: $TAMANO"

            ((EXITOSOS++))

        else

            echo "[ERROR] El backup está vacío."
            registrar_log "ERROR" "Backup vacío: $ARCHIVO_BACKUP"
            ((ERRORES++))

        fi

    else

        # Capturamos el mensaje generado por tar.
        MOTIVO="$(cat /tmp/backup_error.tmp 2>/dev/null)"

        echo "[ERROR] No se pudo crear el backup."
        echo "Motivo: $MOTIVO"

        registrar_log \
            "ERROR" \
            "Falló el backup de $RUTA. Motivo: $MOTIVO"

        ((ERRORES++))

    fi

done

# Eliminamos el archivo temporal utilizado para capturar errores.
rm -f /tmp/backup_error.tmp

echo
echo "=============================================="
echo "             RESUMEN DEL PROCESO"
echo "=============================================="
echo "Rutas procesadas : $TOTAL"
echo "Backups exitosos : $EXITOSOS"
echo "Errores          : $ERRORES"
echo "=============================================="

registrar_log \
    "INFO" \
    "Proceso finalizado. Exitosos: $EXITOSOS | Errores: $ERRORES"

# Aplicamos la política de retención.
#
# El sistema conserva solamente los backups
# más recientes y elimina los más antiguos.
echo
echo "[INFO] Revisando backups antiguos..."

find "$BACKUP_DIR" \
    -type f \
    -name "backup_*.tar.gz" \
    -printf '%T@ %p\n' |
    sort -nr |
    awk "NR > $RETENCION {print \$2}" |
    while read -r ARCHIVO; do

        if [ -f "$ARCHIVO" ]; then

            echo "[INFO] Eliminando backup antiguo:"
            echo "       $ARCHIVO"

            rm -f "$ARCHIVO" "$ARCHIVO.sha256"

            registrar_log \
                "INFO" \
                "Backup antiguo eliminado: $ARCHIVO"
        fi

    done

echo
echo "[OK] Proceso de respaldo terminado."

# Si hubo errores devolvemos código 1.
# Si todo salió correctamente devolvemos código 0.
if [ "$ERRORES" -gt 0 ]; then
    exit 1
else
    exit 0
fi
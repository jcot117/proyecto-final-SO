#!/bin/bash
# =============================================================================
# Herramienta de Administración de Data Center - Bash
# Universidad Icesi - Sistemas Operacionales - Proyecto Final
# =============================================================================

COLOR_TITLE='\033[1;36m'
COLOR_OPTION='\033[1;33m'
COLOR_SUCCESS='\033[1;32m'
COLOR_ERROR='\033[1;31m'
COLOR_INFO='\033[1;35m'
COLOR_RESET='\033[0m'

separador() {
    echo -e "${COLOR_INFO}$(printf '=%.0s' {1..60})${COLOR_RESET}"
}

pausa() {
    echo ""
    read -rp "Presione Enter para continuar..."
}

# ---- Opción 1: Usuarios y último login ----
usuarios_ultimo_login() {
    separador
    echo -e "${COLOR_TITLE}  USUARIOS DEL SISTEMA Y ÚLTIMO LOGIN${COLOR_RESET}"
    separador
    printf "%-25s %s\n" "USUARIO" "ÚLTIMO LOGIN"
    printf "%-25s %s\n" "-------" "------------"

    while IFS=: read -r usuario _ _ uid _ _ _; do
        if [ "$uid" -ge 0 ] 2>/dev/null; then
            ultimo_login=$(lastlog -u "$usuario" 2>/dev/null | tail -1 | awk '{
                if ($0 ~ /Never logged in/ || $0 ~ /Nunca/) 
                    print "Nunca ha ingresado"
                else {
                    for(i=4;i<=NF;i++) printf "%s ", $i
                    print ""
                }
            }')
            if [ -n "$ultimo_login" ]; then
                printf "%-25s %s\n" "$usuario" "$ultimo_login"
            fi
        fi
    done < /etc/passwd
}

# ---- Opción 2: Filesystems / discos conectados ----
filesystems_discos() {
    separador
    echo -e "${COLOR_TITLE}  FILESYSTEMS / DISCOS CONECTADOS${COLOR_RESET}"
    separador
    printf "%-25s %20s %20s\n" "FILESYSTEM" "TAMAÑO (bytes)" "LIBRE (bytes)"
    printf "%-25s %20s %20s\n" "----------" "---------------" "-------------"

    df -B1 --output=source,size,avail 2>/dev/null | tail -n +2 | while read -r fs tamano libre; do
        if [[ "$fs" == /dev/* ]] || [[ "$fs" == tmpfs ]] || [[ "$fs" == //* ]]; then
            printf "%-25s %20s %20s\n" "$fs" "$tamano" "$libre"
        fi
    done

    if [ $? -ne 0 ]; then
        df -k | tail -n +2 | while read -r fs bloques _ libre _ montaje; do
            tamano_bytes=$((bloques * 1024))
            libre_bytes=$((libre * 1024))
            printf "%-25s %20s %20s\n" "$fs" "$tamano_bytes" "$libre_bytes"
        done
    fi
}

# ---- Opción 3: 10 archivos más grandes ----
archivos_mas_grandes() {
    separador
    echo -e "${COLOR_TITLE}  10 ARCHIVOS MÁS GRANDES${COLOR_RESET}"
    separador

    echo "Filesystems disponibles:"
    df -h --output=target 2>/dev/null | tail -n +2 | grep -v "^$" | nl
    echo ""
    read -rp "Ingrese la ruta del filesystem o directorio: " directorio

    if [ ! -d "$directorio" ]; then
        echo -e "${COLOR_ERROR}Error: El directorio '$directorio' no existe.${COLOR_RESET}"
        return
    fi

    echo ""
    echo -e "${COLOR_INFO}Buscando los 10 archivos más grandes en: $directorio${COLOR_RESET}"
    echo -e "${COLOR_INFO}(Esto puede tomar unos momentos...)${COLOR_RESET}"
    echo ""
    printf "%-15s %s\n" "TAMAÑO (bytes)" "RUTA COMPLETA"
    printf "%-15s %s\n" "---------------" "-------------"

    find "$directorio" -type f -exec du -b {} + 2>/dev/null | sort -rn | head -10 | while read -r tamano archivo; do
        printf "%-15s %s\n" "$tamano" "$archivo"
    done
}

# ---- Opción 4: Memoria libre y swap ----
memoria_y_swap() {
    separador
    echo -e "${COLOR_TITLE}  MEMORIA LIBRE Y ESPACIO SWAP${COLOR_RESET}"
    separador

    mem_info=$(free -b 2>/dev/null)

    if [ -z "$mem_info" ]; then
        echo -e "${COLOR_ERROR}Error: No se pudo obtener información de memoria.${COLOR_RESET}"
        return
    fi

    mem_total=$(echo "$mem_info" | awk '/^Mem:/ {print $2}')
    mem_libre=$(echo "$mem_info" | awk '/^Mem:/ {print $4}')
    mem_disponible=$(echo "$mem_info" | awk '/^Mem:/ {print $7}')
    swap_total=$(echo "$mem_info" | awk '/^Swap:/ {print $2}')
    swap_usado=$(echo "$mem_info" | awk '/^Swap:/ {print $3}')
    swap_libre=$(echo "$mem_info" | awk '/^Swap:/ {print $4}')

    if [ "$mem_total" -gt 0 ] 2>/dev/null; then
        mem_pct=$(awk "BEGIN {printf \"%.2f\", ($mem_libre/$mem_total)*100}")
        mem_disp_pct=$(awk "BEGIN {printf \"%.2f\", ($mem_disponible/$mem_total)*100}")
    else
        mem_pct="0.00"
        mem_disp_pct="0.00"
    fi

    echo -e "${COLOR_SUCCESS}--- MEMORIA RAM ---${COLOR_RESET}"
    echo "  Total:       $mem_total bytes"
    echo "  Libre:       $mem_libre bytes ($mem_pct%)"
    echo "  Disponible:  $mem_disponible bytes ($mem_disp_pct%)"
    echo ""

    if [ "$swap_total" -gt 0 ] 2>/dev/null; then
        swap_uso_pct=$(awk "BEGIN {printf \"%.2f\", ($swap_usado/$swap_total)*100}")
        swap_libre_pct=$(awk "BEGIN {printf \"%.2f\", ($swap_libre/$swap_total)*100}")
    else
        swap_uso_pct="0.00"
        swap_libre_pct="0.00"
    fi

    echo -e "${COLOR_SUCCESS}--- ESPACIO SWAP ---${COLOR_RESET}"
    echo "  Total:       $swap_total bytes"
    echo "  En uso:      $swap_usado bytes ($swap_uso_pct%)"
    echo "  Libre:       $swap_libre bytes ($swap_libre_pct%)"
}

# ---- Opción 5: Backup a USB ----
backup_a_usb() {
    separador
    echo -e "${COLOR_TITLE}  COPIA DE SEGURIDAD A USB${COLOR_RESET}"
    separador

    echo "Dispositivos de almacenamiento extraíble detectados:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null | grep -E "disk|part" || \
        df -h | grep -iE "media|mnt|usb"
    echo ""

    read -rp "Directorio a respaldar: " dir_origen
    if [ ! -d "$dir_origen" ]; then
        echo -e "${COLOR_ERROR}Error: El directorio '$dir_origen' no existe.${COLOR_RESET}"
        return
    fi

    read -rp "Punto de montaje de la USB (ej: /media/$USER/USB, /mnt/usb): " dir_usb
    if [ ! -d "$dir_usb" ]; then
        echo -e "${COLOR_ERROR}Error: El punto de montaje '$dir_usb' no existe.${COLOR_RESET}"
        echo "Asegúrese de que la USB esté conectada y montada."
        return
    fi

    espacio_libre=$(df -B1 "$dir_usb" 2>/dev/null | tail -1 | awk '{print $4}')
    tamano_origen=$(du -sb "$dir_origen" 2>/dev/null | awk '{print $1}')

    if [ -n "$espacio_libre" ] && [ -n "$tamano_origen" ]; then
        if [ "$tamano_origen" -gt "$espacio_libre" ] 2>/dev/null; then
            echo -e "${COLOR_ERROR}Error: No hay suficiente espacio en la USB.${COLOR_RESET}"
            echo "  Espacio necesario: $tamano_origen bytes"
            echo "  Espacio disponible: $espacio_libre bytes"
            return
        fi
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)
    nombre_backup="backup_${timestamp}"
    dir_backup="${dir_usb}/${nombre_backup}"

    echo ""
    echo -e "${COLOR_INFO}Creando backup en: $dir_backup${COLOR_RESET}"
    mkdir -p "$dir_backup"

    cp -r "$dir_origen"/* "$dir_backup/" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_ERROR}Error al copiar archivos.${COLOR_RESET}"
        return
    fi

    catalogo="${dir_backup}/catalogo.txt"
    echo "=================================================================" > "$catalogo"
    echo "  CATÁLOGO DE BACKUP" >> "$catalogo"
    echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')" >> "$catalogo"
    echo "  Directorio origen: $dir_origen" >> "$catalogo"
    echo "  Directorio destino: $dir_backup" >> "$catalogo"
    echo "=================================================================" >> "$catalogo"
    echo "" >> "$catalogo"
    printf "%-30s %s\n" "ÚLTIMA MODIFICACIÓN" "NOMBRE DEL ARCHIVO" >> "$catalogo"
    printf "%-30s %s\n" "-------------------" "------------------" >> "$catalogo"

    find "$dir_backup" -type f ! -name "catalogo.txt" -printf "%T+ %p\n" 2>/dev/null | \
        sort -r | while read -r fecha archivo; do
            printf "%-30s %s\n" "$fecha" "$archivo" >> "$catalogo"
        done

    total_archivos=$(find "$dir_backup" -type f ! -name "catalogo.txt" | wc -l)
    tamano_backup=$(du -sh "$dir_backup" 2>/dev/null | awk '{print $1}')

    echo ""
    echo -e "${COLOR_SUCCESS}¡Backup completado exitosamente!${COLOR_RESET}"
    echo "  Archivos copiados: $total_archivos"
    echo "  Tamaño del backup: $tamano_backup"
    echo "  Catálogo guardado en: $catalogo"
}

# ---- Menú principal ----
while true; do
    clear
    echo -e "${COLOR_TITLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     HERRAMIENTA DE ADMINISTRACIÓN DE DATA CENTER           ║"
    echo "║     Universidad Icesi - Sistemas Operacionales             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${COLOR_RESET}"
    echo -e "  ${COLOR_OPTION}1.${COLOR_RESET} Usuarios del sistema y último login"
    echo -e "  ${COLOR_OPTION}2.${COLOR_RESET} Filesystems / discos conectados"
    echo -e "  ${COLOR_OPTION}3.${COLOR_RESET} 10 archivos más grandes de un filesystem"
    echo -e "  ${COLOR_OPTION}4.${COLOR_RESET} Memoria libre y espacio swap"
    echo -e "  ${COLOR_OPTION}5.${COLOR_RESET} Copia de seguridad (backup) a USB"
    echo -e "  ${COLOR_OPTION}6.${COLOR_RESET} Salir"
    echo ""
    separador
    read -rp "  Seleccione una opción [1-6]: " opcion

    case $opcion in
        1) usuarios_ultimo_login ;;
        2) filesystems_discos ;;
        3) archivos_mas_grandes ;;
        4) memoria_y_swap ;;
        5) backup_a_usb ;;
        6)
            echo ""
            echo -e "${COLOR_SUCCESS}¡Hasta luego!${COLOR_RESET}"
            exit 0
            ;;
        *)
            echo -e "${COLOR_ERROR}Opción inválida. Intente de nuevo.${COLOR_RESET}"
            ;;
    esac
    pausa
done

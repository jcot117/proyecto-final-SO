# Documentación Técnica

## Índice

1. [Conceptos de Sistemas Operativos](#1-conceptos-de-sistemas-operativos)
2. [Script Bash - Explicación detallada](#2-script-bash---explicación-detallada)
3. [Script PowerShell - Explicación detallada](#3-script-powershell---explicación-detallada)
4. [Comparativa Bash vs PowerShell](#4-comparativa-bash-vs-powershell)
5. [Referencias](#5-referencias)

---

## 1. Conceptos de Sistemas Operativos

### 1.1 Gestión de Usuarios

Un sistema operativo mantiene una base de datos de usuarios que pueden acceder al sistema. Cada usuario tiene un identificador único (UID), un nombre, y se registra información de sus sesiones.

- **Linux:** Los usuarios se almacenan en `/etc/passwd`. Cada línea tiene el formato:
  ```
  nombre:contraseña:UID:GID:descripción:home:shell
  ```
  El archivo `/var/log/lastlog` almacena el registro del último ingreso de cada usuario.

- **Windows:** Los usuarios locales se gestionan mediante el Security Accounts Manager (SAM). PowerShell accede a esta información a través del módulo `Microsoft.PowerShell.LocalAccounts`.

### 1.2 Filesystems y Discos

Un **filesystem** (sistema de archivos) es la estructura lógica que el SO usa para organizar datos en un dispositivo de almacenamiento.

- **Linux:** Usa una jerarquía única con raíz `/`. Los dispositivos se "montan" en directorios. El comando `df` (disk free) consulta el Virtual File System (VFS) del kernel para obtener estadísticas de cada filesystem montado.

- **Windows:** Usa letras de unidad (C:, D:, etc.). Cada partición tiene su propio filesystem (generalmente NTFS o FAT32). WMI (Windows Management Instrumentation) provee acceso programático a esta información.

### 1.3 Memoria RAM y Swap

- **Memoria RAM:** Almacenamiento volátil de acceso rápido donde se cargan los procesos en ejecución.
- **Memoria libre:** RAM que no está asignada a ningún proceso ni al caché del kernel.
- **Swap:** Espacio en disco que el SO usa como extensión de la RAM. Cuando la RAM se llena, el SO mueve páginas de memoria poco usadas al swap (paginación).

En **Linux**, `/proc/meminfo` es un archivo virtual del kernel que expone estadísticas de memoria en tiempo real. El comando `free` lo lee y lo presenta de forma legible.

En **Windows**, `Win32_OperatingSystem` (clase WMI/CIM) expone las propiedades `FreePhysicalMemory`, `TotalVisibleMemorySize`, `TotalVirtualMemorySize` y `FreeVirtualMemory`.

### 1.4 Copias de Seguridad (Backup)

Un backup es una copia de datos almacenada en un medio separado para proteger contra pérdida de información. Un **catálogo** es un índice que registra qué archivos se respaldaron y sus metadatos (fecha de modificación, tamaño, etc.), facilitando la búsqueda y restauración.

---

## 2. Script Bash - Explicación detallada

### 2.1 Estructura general

El script usa un bucle `while true` con una instrucción `case` para el menú:

```bash
while true; do
    # Mostrar menú
    read -rp "Seleccione opción: " opcion
    case $opcion in
        1) funcion_1 ;;
        2) funcion_2 ;;
        # ...
    esac
done
```

- `while true` — bucle infinito que solo se rompe con `exit`
- `read -rp` — lee input del usuario; `-r` evita interpretar backslashes, `-p` muestra un prompt
- `case ... esac` — estructura de selección múltiple (equivalente a switch)

### 2.2 Opción 1: Usuarios y último login

```bash
while IFS=: read -r usuario _ _ uid _ _ _; do
    lastlog -u "$usuario" 2>/dev/null | tail -1
done < /etc/passwd
```

**Comandos usados:**

| Comando | Descripción |
|---------|-------------|
| `/etc/passwd` | Archivo que contiene la lista de usuarios del sistema |
| `IFS=:` | Establece los dos puntos como separador de campos (Internal Field Separator) |
| `read -r` | Lee una línea y la divide en variables según IFS |
| `lastlog -u` | Muestra el último login de un usuario específico |
| `tail -1` | Toma solo la última línea de la salida |
| `2>/dev/null` | Redirige errores a /dev/null (los descarta silenciosamente) |

### 2.3 Opción 2: Filesystems

```bash
df -B1 --output=source,size,avail
```

**Flags de `df`:**

| Flag | Significado |
|------|-------------|
| `-B1` | Muestra tamaños en bloques de 1 byte (bytes exactos) |
| `--output=source,size,avail` | Selecciona columnas: dispositivo, tamaño total, espacio disponible |

### 2.4 Opción 3: Archivos más grandes

```bash
find "$dir" -type f -exec du -b {} + | sort -rn | head -10
```

**Pipeline explicado:**

1. `find "$dir" -type f` — busca solo archivos regulares (no directorios) recursivamente
2. `-exec du -b {} +` — para cada archivo encontrado, ejecuta `du -b` (tamaño en bytes). El `+` agrupa múltiples archivos en una sola ejecución de `du` (más eficiente que `\;`)
3. `sort -rn` — ordena numéricamente (`-n`) en orden inverso (`-r`), de mayor a menor
4. `head -10` — toma las primeras 10 líneas (los 10 archivos más grandes)

### 2.5 Opción 4: Memoria y swap

```bash
free -b | awk '/^Mem:/ {printf "Libre: %s bytes (%.2f%%)\n", $4, ($4/$2)*100}'
```

**Desglose:**

| Elemento | Descripción |
|----------|-------------|
| `free -b` | Muestra información de memoria en bytes |
| `awk '/^Mem:/'` | Filtra la línea que empieza con "Mem:" |
| `$2` | Segundo campo = memoria total |
| `$4` | Cuarto campo = memoria libre |
| `($4/$2)*100` | Calcula el porcentaje |
| `%.2f%%` | Formato: 2 decimales seguido de símbolo % |

**Campos de `free -b`:**

```
              total       used       free     shared  buff/cache   available
Mem:         $2          $3         $4        $5      $6           $7
Swap:        $2          $3         $4
```

### 2.6 Opción 5: Backup

```bash
cp -r "$src"/* "$dest/"
find "$dest" -type f -printf "%T+ %p\n" > catalogo.txt
```

| Comando | Descripción |
|---------|-------------|
| `cp -r` | Copia recursiva (incluye subdirectorios) |
| `mkdir -p` | Crea directorio y padres si no existen |
| `find -printf "%T+"` | Imprime la fecha de última modificación en formato ISO |
| `find -printf "%p"` | Imprime la ruta completa del archivo |
| `du -sb` | Calcula el tamaño total de un directorio en bytes |
| `df -B1` | Muestra espacio libre del filesystem en bytes |

---

## 3. Script PowerShell - Explicación detallada

### 3.1 Estructura general

PowerShell usa `do...while` y `switch`:

```powershell
do {
    # Mostrar menú
    $opcion = Read-Host "Seleccione opción"
    switch ($opcion) {
        "1" { Funcion-1 }
        "2" { Funcion-2 }
    }
} while ($opcion -ne "6")
```

- `do { } while ()` — bucle que ejecuta al menos una vez
- `Read-Host` — lee input del usuario
- `switch` — selección múltiple (más potente que `case` de Bash, soporta regex)

### 3.2 Opción 1: Usuarios y último login

```powershell
Get-LocalUser | Select-Object Name, Enabled, LastLogon
```

**Cmdlets usados:**

| Cmdlet | Descripción |
|--------|-------------|
| `Get-LocalUser` | Obtiene las cuentas de usuario locales del SAM de Windows |
| `Select-Object` | Selecciona propiedades específicas del objeto (equivalente a proyección SQL) |
| `Format-Table` | Formatea la salida como tabla |

**Propiedades de LocalUser:**
- `Name` — nombre de la cuenta
- `Enabled` — si la cuenta está activa
- `LastLogon` — objeto DateTime con la fecha del último login
- `Description` — descripción de la cuenta

### 3.3 Opción 2: Discos conectados

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk
```

**CIM/WMI explicado:**

CIM (Common Information Model) es el estándar que Windows usa para exponer información del sistema. `Get-CimInstance` consulta estas clases.

| Clase WMI | Información que provee |
|-----------|----------------------|
| `Win32_LogicalDisk` | Discos lógicos (C:, D:, etc.) con tamaño y espacio libre |
| `Win32_DiskDrive` | Discos físicos (modelo, capacidad, tipo) |

**Propiedad `DriveType` de Win32_LogicalDisk:**

| Valor | Tipo |
|-------|------|
| 2 | Disco extraíble (USB) |
| 3 | Disco local |
| 4 | Unidad de red |
| 5 | CD-ROM |

### 3.4 Opción 3: Archivos más grandes

```powershell
Get-ChildItem -Path $dir -Recurse -File |
    Sort-Object Length -Descending |
    Select-Object -First 10 FullName, Length
```

**Pipeline de PowerShell:**

1. `Get-ChildItem -Recurse -File` — lista archivos recursivamente (equivalente a `find -type f`)
2. `Sort-Object Length -Descending` — ordena por tamaño de mayor a menor
3. `Select-Object -First 10` — toma los primeros 10 resultados

**Flags importantes:**
- `-Recurse` — busca en subdirectorios
- `-File` — solo archivos (no directorios)
- `-ErrorAction SilentlyContinue` — ignora errores de permisos sin detener la ejecución

### 3.5 Opción 4: Memoria y swap

```powershell
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$memLibre = $os.FreePhysicalMemory * 1KB
```

**Propiedades de Win32_OperatingSystem:**

| Propiedad | Descripción | Unidad original |
|-----------|-------------|-----------------|
| `FreePhysicalMemory` | RAM disponible | Kilobytes |
| `TotalVisibleMemorySize` | RAM total visible al SO | Kilobytes |
| `TotalVirtualMemorySize` | Memoria virtual total (RAM + Swap) | Kilobytes |
| `FreeVirtualMemory` | Memoria virtual libre | Kilobytes |

> **Nota:** Estas propiedades están en KB, por eso se multiplican por `1KB` (1024) para convertir a bytes.

**`Win32_ComputerSystem`** tiene `TotalPhysicalMemory` directamente en bytes (más preciso para RAM total).

### 3.6 Opción 5: Backup

```powershell
Copy-Item -Path "$src\*" -Destination $dest -Recurse
Get-ChildItem -Recurse -File | Select-Object FullName, LastWriteTime | Export-Csv
```

| Cmdlet | Descripción |
|--------|-------------|
| `Copy-Item -Recurse` | Copia archivos y subdirectorios (como `cp -r`) |
| `New-Item -ItemType Directory` | Crea un directorio (como `mkdir -p`) |
| `Get-ChildItem` | Lista archivos y directorios |
| `Export-Csv` | Exporta objetos a formato CSV |
| `Out-File` | Escribe texto a un archivo |
| `Test-Path` | Verifica si una ruta existe |
| `Get-PSDrive` | Obtiene información de unidades |
| `Measure-Object -Sum` | Calcula la suma de una propiedad numérica |

---

## 4. Comparativa Bash vs PowerShell

| Aspecto | Bash | PowerShell |
|---------|------|------------|
| **SO principal** | Linux/Unix | Windows |
| **Paradigma** | Procesa texto (strings) | Procesa objetos (.NET) |
| **Pipeline** | Pasa texto entre comandos | Pasa objetos entre cmdlets |
| **Usuarios** | `/etc/passwd` + `lastlog` | `Get-LocalUser` (módulo SAM) |
| **Discos** | `df` (lee `/proc/mounts`) | `Get-CimInstance Win32_LogicalDisk` (WMI) |
| **Memoria** | `free` (lee `/proc/meminfo`) | `Get-CimInstance Win32_OperatingSystem` (WMI) |
| **Búsqueda archivos** | `find` + `du` | `Get-ChildItem -Recurse` |
| **Copiar archivos** | `cp -r` | `Copy-Item -Recurse` |
| **Variables** | `$variable` (sin tipo) | `$variable` (tipada, .NET) |
| **Condicionales** | `if [ ]; then; fi` | `if () { }` |
| **Bucles** | `while; do; done` | `while () { }` o `do { } while ()` |

---

## 5. Referencias

### Bash / Linux
- [GNU Bash Manual](https://www.gnu.org/software/bash/manual/bash.html) — Referencia oficial del intérprete Bash
- [Linux man pages](https://man7.org/linux/man-pages/) — Documentación de comandos Linux
  - `man df` — Comando de disk free
  - `man free` — Comando de información de memoria
  - `man find` — Comando de búsqueda de archivos
  - `man lastlog` — Registro de último login
  - `man awk` — Procesamiento de texto
- [The Linux Documentation Project](https://tldp.org/) — Guías y HOWTOs de Linux
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/) — Guía avanzada de scripting en Bash

### PowerShell / Windows
- [Microsoft Learn - PowerShell](https://learn.microsoft.com/es-es/powershell/) — Documentación oficial
- [Get-LocalUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser) — Referencia del cmdlet
- [Get-CimInstance](https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance) — Consultas WMI/CIM
- [Win32_LogicalDisk](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-logicaldisk) — Clase WMI de discos
- [Win32_OperatingSystem](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingystem) — Clase WMI del SO

### Conceptos de Sistemas Operativos
- Silberschatz, Galvin & Gagne — *Operating System Concepts* (10th Ed.)
- Tanenbaum & Bos — *Modern Operating Systems* (4th Ed.)

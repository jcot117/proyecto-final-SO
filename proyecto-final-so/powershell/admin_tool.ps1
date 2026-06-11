# =============================================================================
# Herramienta de Administracion de Data Center - PowerShell
# Universidad Icesi - Sistemas Operacionales - Proyecto Final
# =============================================================================

function Show-Separador {
    Write-Host ("=" * 60) -ForegroundColor Magenta
}

function Show-Pausa {
    Write-Host ""
    Read-Host "Presione Enter para continuar"
}

# ---- Opcion 1: Usuarios y ultimo login ----
function Get-UsuariosUltimoLogin {
    Show-Separador
    Write-Host "  USUARIOS DEL SISTEMA Y ULTIMO LOGIN" -ForegroundColor Cyan
    Show-Separador

    try {
        $usuarios = Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description

        Write-Host ""
        Write-Host ("{0,-25} {1,-10} {2,-25} {3}" -f "USUARIO", "ACTIVO", "ULTIMO LOGIN", "DESCRIPCION") -ForegroundColor Yellow
        Write-Host ("{0,-25} {1,-10} {2,-25} {3}" -f "-------", "------", "------------", "-----------")

        foreach ($u in $usuarios) {
            $estado = if ($u.Enabled) { "Si" } else { "No" }
            $login = if ($u.LastLogon) {
                $u.LastLogon.ToString("yyyy-MM-dd HH:mm:ss")
            } else {
                "Nunca ha ingresado"
            }
            $desc = if ($u.Description) { $u.Description } else { "-" }
            Write-Host ("{0,-25} {1,-10} {2,-25} {3}" -f $u.Name, $estado, $login, $desc)
        }
    }
    catch {
        Write-Host "Error al obtener usuarios: $_" -ForegroundColor Red
        Write-Host "Intentando metodo alternativo con WMI..." -ForegroundColor Yellow

        Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" |
            Select-Object Name, Disabled, Status | Format-Table -AutoSize
    }
}

# ---- Opcion 2: Discos conectados ----
function Get-DiscosConectados {
    Show-Separador
    Write-Host "  DISCOS / FILESYSTEMS CONECTADOS" -ForegroundColor Cyan
    Show-Separador

    Write-Host ""
    Write-Host "--- Discos Logicos ---" -ForegroundColor Green
    Write-Host ""
    Write-Host ("{0,-8} {1,-15} {2,20} {3,20} {4,10}" -f `
        "UNIDAD", "TIPO", "TAMANO (bytes)", "LIBRE (bytes)", "PCT LIBRE") -ForegroundColor Yellow
    Write-Host ("{0,-8} {1,-15} {2,20} {3,20} {4,10}" -f `
        "------", "----", "---------------", "-------------", "---------")

    $discos = Get-CimInstance -ClassName Win32_LogicalDisk
    foreach ($d in $discos) {
        $tipo = switch ($d.DriveType) {
            2 { "Extraible" }
            3 { "Disco local" }
            4 { "Red" }
            5 { "CD-ROM" }
            default { "Otro" }
        }

        if ($d.Size -gt 0) {
            $pctLibre = [math]::Round(($d.FreeSpace / $d.Size) * 100, 2)
            $pctTexto = "$pctLibre%"
            Write-Host ("{0,-8} {1,-15} {2,20} {3,20} {4,10}" -f `
                $d.DeviceID, $tipo, $d.Size, $d.FreeSpace, $pctTexto)
        } else {
            Write-Host ("{0,-8} {1,-15} {2,20} {3,20} {4,10}" -f `
                $d.DeviceID, $tipo, "N/A", "N/A", "N/A")
        }
    }

    Write-Host ""
    Write-Host "--- Discos Fisicos ---" -ForegroundColor Green
    Write-Host ""
    Get-CimInstance -ClassName Win32_DiskDrive |
        Select-Object @{N='Dispositivo';E={$_.DeviceID}},
                      @{N='Modelo';E={$_.Model}},
                      @{N='Tamano (bytes)';E={$_.Size}},
                      @{N='Tipo';E={$_.MediaType}} |
        Format-Table -AutoSize
}

# ---- Opcion 3: 10 archivos mas grandes ----
function Get-ArchivosMasGrandes {
    Show-Separador
    Write-Host "  10 ARCHIVOS MAS GRANDES" -ForegroundColor Cyan
    Show-Separador

    Write-Host ""
    Write-Host "Unidades disponibles:" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem |
        Select-Object Name, @{N='Libre (GB)';E={[math]::Round($_.Free/1GB,2)}} |
        Format-Table -AutoSize

    $directorio = Read-Host "Ingrese la ruta del disco o directorio (ej: C:\)"

    if (-not (Test-Path $directorio)) {
        Write-Host "Error: La ruta '$directorio' no existe." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Buscando los 10 archivos mas grandes en: $directorio" -ForegroundColor Magenta
    Write-Host "(Esto puede tomar unos momentos...)" -ForegroundColor Magenta
    Write-Host ""

    $archivos = Get-ChildItem -Path $directorio -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First 10

    if ($archivos.Count -eq 0) {
        Write-Host "No se encontraron archivos en '$directorio'." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,3} {1,18} {2}" -f "#", "TAMANO (bytes)", "RUTA COMPLETA") -ForegroundColor Yellow
    Write-Host ("{0,3} {1,18} {2}" -f "---", "--------------", "-------------")

    $i = 1
    foreach ($a in $archivos) {
        Write-Host ("{0,3} {1,18} {2}" -f $i, $a.Length, $a.FullName)
        $i++
    }
}

# ---- Opcion 4: Memoria libre y swap ----
function Get-MemoriaYSwap {
    Show-Separador
    Write-Host "  MEMORIA LIBRE Y ESPACIO SWAP" -ForegroundColor Cyan
    Show-Separador

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem

    $memTotalBytes = [math]::Round($cs.TotalPhysicalMemory)
    $memLibreBytes = $os.FreePhysicalMemory * 1KB
    $memUsadaBytes = $memTotalBytes - $memLibreBytes
    $memLibrePct = [math]::Round(($memLibreBytes / $memTotalBytes) * 100, 2)
    $memUsadaPct = [math]::Round(($memUsadaBytes / $memTotalBytes) * 100, 2)
    $memTotalGB = [math]::Round($memTotalBytes / 1GB, 2)

    Write-Host ""
    Write-Host "--- MEMORIA RAM ---" -ForegroundColor Green
    Write-Host ("  Total:       {0} bytes ({1} GB)" -f $memTotalBytes, $memTotalGB)
    Write-Host ("  Libre:       {0} bytes ({1}%)" -f $memLibreBytes, $memLibrePct)
    Write-Host ("  En uso:      {0} bytes ({1}%)" -f $memUsadaBytes, $memUsadaPct)

    $swapTotalBytes = $os.TotalVirtualMemorySize * 1KB
    $swapLibreBytes = $os.FreeVirtualMemory * 1KB
    $swapUsadoBytes = $swapTotalBytes - $swapLibreBytes
    $swapTotalGB = [math]::Round($swapTotalBytes / 1GB, 2)

    if ($swapTotalBytes -gt 0) {
        $swapUsadoPct = [math]::Round(($swapUsadoBytes / $swapTotalBytes) * 100, 2)
        $swapLibrePct = [math]::Round(($swapLibreBytes / $swapTotalBytes) * 100, 2)
    } else {
        $swapUsadoPct = 0
        $swapLibrePct = 0
    }

    Write-Host ""
    Write-Host "--- ESPACIO SWAP (Memoria Virtual) ---" -ForegroundColor Green
    Write-Host ("  Total:       {0} bytes ({1} GB)" -f $swapTotalBytes, $swapTotalGB)
    Write-Host ("  En uso:      {0} bytes ({1}%)" -f $swapUsadoBytes, $swapUsadoPct)
    Write-Host ("  Libre:       {0} bytes ({1}%)" -f $swapLibreBytes, $swapLibrePct)

    Write-Host ""
    Write-Host "--- ARCHIVO DE PAGINACION ---" -ForegroundColor Green
    Get-CimInstance -ClassName Win32_PageFileUsage | ForEach-Object {
        Write-Host "  Archivo:     $($_.Name)"
        Write-Host "  Tamano:      $($_.AllocatedBaseSize) MB"
        Write-Host "  En uso:      $($_.CurrentUsage) MB"
        Write-Host "  Pico de uso: $($_.PeakUsage) MB"
    }
}

# ---- Opcion 5: Backup a USB ----
function Invoke-BackupUSB {
    Show-Separador
    Write-Host "  COPIA DE SEGURIDAD A USB" -ForegroundColor Cyan
    Show-Separador

    Write-Host ""
    Write-Host "Unidades extraibles detectadas:" -ForegroundColor Yellow
    $usbDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=2"

    if ($usbDrives) {
        $usbDrives | ForEach-Object {
            $libre = if ($_.FreeSpace) { "$([math]::Round($_.FreeSpace/1GB, 2)) GB libres" } else { "N/A" }
            Write-Host "  $($_.DeviceID)\ - $($_.VolumeName) ($libre)"
        }
    } else {
        Write-Host "  No se detectaron unidades extraibles." -ForegroundColor Yellow
        Write-Host "  Puede ingresar manualmente la letra de cualquier unidad." -ForegroundColor Yellow
    }

    Write-Host ""
    $dirOrigen = Read-Host "Directorio a respaldar"

    if (-not (Test-Path $dirOrigen)) {
        Write-Host "Error: El directorio '$dirOrigen' no existe." -ForegroundColor Red
        return
    }

    $dirUSB = Read-Host "Letra de unidad destino (ej: E:\, F:\)"

    if (-not (Test-Path $dirUSB)) {
        Write-Host "Error: La unidad '$dirUSB' no esta disponible." -ForegroundColor Red
        Write-Host "Asegurese de que la USB este conectada." -ForegroundColor Yellow
        return
    }

    $tamanoOrigen = (Get-ChildItem -Path $dirOrigen -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    $espacioLibre = (Get-PSDrive -Name $dirUSB.Substring(0,1) -ErrorAction SilentlyContinue).Free

    if ($espacioLibre -and $tamanoOrigen -gt $espacioLibre) {
        Write-Host "Error: No hay suficiente espacio en la unidad destino." -ForegroundColor Red
        Write-Host "  Espacio necesario:  $tamanoOrigen bytes"
        Write-Host "  Espacio disponible: $espacioLibre bytes"
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $nombreBackup = "backup_$timestamp"
    $dirBackup = Join-Path $dirUSB $nombreBackup

    Write-Host ""
    Write-Host "Creando backup en: $dirBackup" -ForegroundColor Magenta

    New-Item -ItemType Directory -Path $dirBackup -Force | Out-Null

    try {
        Copy-Item -Path "$dirOrigen\*" -Destination $dirBackup -Recurse -Force -ErrorAction Stop
    }
    catch {
        Write-Host "Error al copiar archivos: $_" -ForegroundColor Red
        return
    }

    $catalogo = Join-Path $dirBackup "catalogo.csv"
    $catalogoTxt = Join-Path $dirBackup "catalogo.txt"

    $archivosBackup = Get-ChildItem -Path $dirBackup -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "catalogo.csv" -and $_.Name -ne "catalogo.txt" } |
        Select-Object FullName, LastWriteTime, Length |
        Sort-Object LastWriteTime -Descending

    $archivosBackup | Export-Csv -Path $catalogo -NoTypeInformation -Encoding UTF8

    $header = @"
=================================================================
  CATALOGO DE BACKUP
  Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  Directorio origen: $dirOrigen
  Directorio destino: $dirBackup
=================================================================

"@
    $header | Out-File -FilePath $catalogoTxt -Encoding UTF8

    Add-Content -Path $catalogoTxt -Value ("{0,-30} {1,15} {2}" -f "ULTIMA MODIFICACION", "TAMANO", "ARCHIVO")
    Add-Content -Path $catalogoTxt -Value ("{0,-30} {1,15} {2}" -f "-------------------", "------", "-------")

    foreach ($a in $archivosBackup) {
        $linea = "{0,-30} {1,15} {2}" -f $a.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), $a.Length, $a.FullName
        Add-Content -Path $catalogoTxt -Value $linea
    }

    $totalArchivos = ($archivosBackup | Measure-Object).Count
    $tamanoBackup = (Get-ChildItem -Path $dirBackup -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $tamanoHumano = if ($tamanoBackup -gt 1GB) { "$([math]::Round($tamanoBackup/1GB, 2)) GB" }
                    elseif ($tamanoBackup -gt 1MB) { "$([math]::Round($tamanoBackup/1MB, 2)) MB" }
                    else { "$([math]::Round($tamanoBackup/1KB, 2)) KB" }

    Write-Host ""
    Write-Host "Backup completado exitosamente!" -ForegroundColor Green
    Write-Host "  Archivos copiados: $totalArchivos"
    Write-Host "  Tamano del backup: $tamanoHumano"
    Write-Host "  Catalogo (TXT):    $catalogoTxt"
    Write-Host "  Catalogo (CSV):    $catalogo"
}

# ---- Menu principal ----
do {
    Clear-Host
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host "     HERRAMIENTA DE ADMINISTRACION DE DATA CENTER           " -ForegroundColor Cyan
    Write-Host "     Universidad Icesi - Sistemas Operacionales             " -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1." -ForegroundColor Yellow -NoNewline; Write-Host " Usuarios del sistema y ultimo login"
    Write-Host "  2." -ForegroundColor Yellow -NoNewline; Write-Host " Discos / filesystems conectados"
    Write-Host "  3." -ForegroundColor Yellow -NoNewline; Write-Host " 10 archivos mas grandes de un filesystem"
    Write-Host "  4." -ForegroundColor Yellow -NoNewline; Write-Host " Memoria libre y espacio swap"
    Write-Host "  5." -ForegroundColor Yellow -NoNewline; Write-Host " Copia de seguridad (backup) a USB"
    Write-Host "  6." -ForegroundColor Yellow -NoNewline; Write-Host " Salir"
    Write-Host ""
    Show-Separador
    $opcion = Read-Host "  Seleccione una opcion [1-6]"

    switch ($opcion) {
        "1" { Get-UsuariosUltimoLogin }
        "2" { Get-DiscosConectados }
        "3" { Get-ArchivosMasGrandes }
        "4" { Get-MemoriaYSwap }
        "5" { Invoke-BackupUSB }
        "6" {
            Write-Host ""
            Write-Host "Hasta luego!" -ForegroundColor Green
        }
        default { Write-Host "Opcion invalida. Intente de nuevo." -ForegroundColor Red }
    }

    if ($opcion -ne "6") {
        Show-Pausa
    }
} while ($opcion -ne "6")

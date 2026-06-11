# Herramienta de Administración de Data Center

**Universidad Icesi** - Facultad de Ingeniería, Diseño y Ciencias Aplicadas  
**Materia:** Sistemas Operacionales  
**Proyecto Final de Curso**

---

## Descripción

Este proyecto contiene dos herramientas de administración para data center, implementadas en **Bash** (Linux) y **PowerShell** (Windows). Ambas ofrecen un menú interactivo con cinco funcionalidades clave para la gestión de servidores.

## Funcionalidades

| # | Funcionalidad | Descripción |
|---|---------------|-------------|
| 1 | **Usuarios y último login** | Lista todos los usuarios del sistema con la fecha y hora de su último ingreso |
| 2 | **Filesystems / discos** | Muestra los discos conectados con su tamaño total y espacio libre en bytes |
| 3 | **10 archivos más grandes** | Encuentra los 10 archivos más grandes de un filesystem especificado, con ruta completa |
| 4 | **Memoria y swap** | Muestra la cantidad de memoria libre y swap en uso (en bytes y porcentaje) |
| 5 | **Backup a USB** | Realiza copia de seguridad a USB incluyendo un catálogo con nombres y fechas de modificación |

## Estructura del Proyecto

```
proyecto-final-so/
├── README.md                  # Este archivo
├── bash/
│   └── admin_tool.sh          # Herramienta en Bash (Linux)
├── powershell/
│   └── admin_tool.ps1         # Herramienta en PowerShell (Windows)
└── docs/
    └── documentacion.md       # Documentación técnica detallada
```

## Requisitos

### Bash (Linux)
- Sistema operativo Linux (Ubuntu, Debian, CentOS, etc.)
- Bash 4.0 o superior
- Comandos del sistema: `lastlog`, `df`, `find`, `free`, `du`, `cp`, `lsblk`

### PowerShell (Windows)
- Windows 10 / Windows Server 2016 o superior
- PowerShell 5.1 o superior
- Permisos de administrador (recomendado para acceso completo a info del sistema)

## Ejecución

### Script Bash

```bash
# Dar permisos de ejecución
chmod +x bash/admin_tool.sh

# Ejecutar
./bash/admin_tool.sh

# O con bash directamente
bash bash/admin_tool.sh
```

### Script PowerShell

```powershell
# Si la política de ejecución no permite scripts, ejecutar primero:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ejecutar el script
.\powershell\admin_tool.ps1
```

## Notas Importantes

- **Opción 3 (archivos más grandes):** En filesystems grandes, la búsqueda puede tomar varios minutos. Se recomienda especificar subdirectorios para resultados más rápidos.
- **Opción 5 (backup):** Asegúrese de que la USB esté montada/conectada antes de ejecutar. El script verifica que haya espacio suficiente antes de copiar.
- **Permisos:** Algunas opciones pueden requerir permisos de administrador/root para acceder a toda la información del sistema.

## Autores

- [Nombre del integrante 1]
- [Nombre del integrante 2]
- [Nombre del integrante 3]

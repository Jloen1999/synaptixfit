# Despliega una etiqueta de imagen de SynaptixFit en produccion desde Windows: copia de la BD, despliegue,
# filtro de salida del backend y verificacion. Lee los Google Client IDs de backend/.env sin mostrarlos.
# Usa el ssh de Windows (con el agente de claves); el de Git Bash no ve la clave.
#
#   powershell -ExecutionPolicy Bypass -File infra\desplegar.ps1 -Tag <commit de master>
param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [string]$BackupPrefix = 'pre-deploy'
)
$ErrorActionPreference = 'Stop'
$ssh = 'C:\WINDOWS\System32\OpenSSH\ssh.exe'
$scp = 'C:\WINDOWS\System32\OpenSSH\scp.exe'
Set-Location (Split-Path $PSScriptRoot -Parent)
$ids = ((Get-Content backend\.env | Where-Object { $_ -like 'GOOGLE_CLIENT_IDS=*' }) -split '=', 2)[1].Trim()
if (-not $ids) { throw 'GOOGLE_CLIENT_IDS no encontrado en backend/.env' }

Write-Host '1/5 Subiendo los scripts...'
& $scp docker-compose.prod.yml infra\scripts\00-copia-bd-synaptixfit.sh infra\scripts\07-desplegar-synaptixfit.sh `
    infra\scripts\08-verificar-synaptixfit.sh infra\scripts\11-filtrar-salida-backend.sh infra-ovh:/tmp/
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron subir los scripts' }
& $ssh infra-ovh 'sed -i ''s/\r$//'' /tmp/0*.sh /tmp/1*.sh'

Write-Host '2/5 Copia de la base de datos...'
& $ssh infra-ovh "sudo bash /tmp/00-copia-bd-synaptixfit.sh $BackupPrefix"
if ($LASTEXITCODE -ne 0) { throw 'La copia de la BD fallo: no se despliega' }

Write-Host "3/5 Desplegando $Tag..."
& $ssh infra-ovh "sudo bash /tmp/07-desplegar-synaptixfit.sh $Tag '$ids' /tmp/docker-compose.prod.yml"
if ($LASTEXITCODE -ne 0) { throw "El despliegue fallo con codigo $LASTEXITCODE" }

Write-Host '4/5 Esperando a que arranquen los contenedores...'
Start-Sleep -Seconds 75
Write-Host '    Filtro de salida del backend (se pierde al recrear el contenedor)...'
& $ssh infra-ovh 'sudo bash /tmp/11-filtrar-salida-backend.sh --aplicar'
if ($LASTEXITCODE -ne 0) { Write-Warning 'El filtro de salida no se aplico: revisa la salida de arriba' }

Write-Host '5/5 Verificando (si falla justo ahora, repite 08 en un minuto)...'
& $ssh infra-ovh 'sudo bash /tmp/08-verificar-synaptixfit.sh'

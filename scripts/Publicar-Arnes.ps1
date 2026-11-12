[CmdletBinding()]
param(
    [string]$Aprobador,
    [string]$Cuenta,
    [string]$Email,
    # Nombre del repo nuevo del arnés en la cuenta.
    [string]$Arnes,
    # Repo privado de coordinación (owner/repo). Por defecto, <cuenta>/SharedCord.
    [string]$Coordinacion,
    # Carpeta donde se arma el repo nuevo. Por defecto, junto a este repo y con el nombre del arnés.
    [string]$Destino,
    # Acepta los datos sin preguntar. Si falta alguno, falla en vez de pedirlo.
    [switch]$Si,
    # Arma el repo local, pero no lo crea en GitHub ni hace push.
    [switch]$SinPublicar,
    # No verificar ni crear el repo de coordinación.
    [switch]$SinCoordinacion
)

# Dos modos:
# - Publicar: desde un clon de LesslieLoop (sin instalacion.json). Copia la revisión actual a una
#   carpeta nueva, la configura, crea un repo con un único commit y lo sube a la cuenta indicada.
# - Reconfigurar: desde el repo ya publicado (con instalacion.json). Cambia los datos en el lugar y
#   commitea; la publicación del commit sigue el flujo habitual del repo.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$raiz = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$claves = @('aprobador', 'cuenta_github', 'email', 'arnes', 'coordinacion')
$marcadores = @{
    aprobador = '{{APROBADOR}}'; cuenta_github = '{{CUENTA_GITHUB}}'; email = '{{EMAIL}}'
    arnes = '{{ARNES}}'; coordinacion = '{{COORDINACION}}'
}
$etiquetas = @{
    aprobador = 'Nombre de quien aprueba'; cuenta_github = 'Cuenta u organización de GitHub'; email = 'Email de commits'
    arnes = 'Nombre del repo del arnés'; coordinacion = 'Repo de coordinación (owner/repo)'
}
# Archivos de autoría y scripts de configuración: nunca se reescriben.
$protegidos = @('LICENSE', 'NOTICE', 'PROVENANCE.md', 'instalacion.json',
                'scripts/Publicar-Arnes.ps1', 'scripts/Instalar-Arnes.ps1')

function Invoke-Git {
    param([string]$Repo)
    $salida = & git -C $Repo @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') falló en $Repo." }
    return $salida
}

function Invoke-Tolerante {
    # Windows PowerShell 5.1 corta la ejecución si un comando externo escribe en stderr con Stop.
    param([scriptblock]$Bloque)
    $previo = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $salida = & $Bloque 2>$null } finally { $ErrorActionPreference = $previo }
    return $salida
}

function Test-Afirmativo {
    param([string]$Respuesta)
    return $Respuesta -match '^\s*(s|si|sí|y|yes)\s*$'
}

function Read-Valor {
    param([string]$Clave, [string]$Actual)
    if ($Si) {
        if ([string]::IsNullOrWhiteSpace($Actual)) { throw "Falta $($etiquetas[$Clave]); indicarlo como parámetro." }
        return $Actual
    }
    $sugerido = ''
    if ($Actual) { $sugerido = " [$Actual]" }
    $respuesta = Read-Host "$($etiquetas[$Clave])$sugerido"
    if ([string]::IsNullOrWhiteSpace($respuesta)) { return $Actual }
    return $respuesta.Trim()
}

function Assert-SinCambios {
    param([string]$Repo)
    $pendientes = @(Invoke-Git $Repo status --porcelain --untracked-files=no)
    if ($pendientes.Count -gt 0 -and $pendientes[0]) {
        throw "El repo $Repo tiene cambios sin commit. Commitearlos o descartarlos antes de continuar."
    }
}

function Update-Marcadores {
    # Reescribe los archivos versionados de $Repo; devuelve las rutas modificadas.
    param([string]$Repo, [hashtable]$Reemplazos)
    $buscados = @($Reemplazos.Keys | Sort-Object { $_.Length } -Descending)
    $patron = '(?<![\w-])(' + (($buscados | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?![\w-])'
    $evaluador = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $Reemplazos[$m.Value] }
    $argumentos = @('-c', 'core.quotepath=false', 'grep', '-I', '-l', '-F')
    foreach ($buscado in $buscados) { $argumentos += @('-e', $buscado) }
    $argumentos += @('--', '.')
    foreach ($protegido in $protegidos) { $argumentos += ":!$protegido" }
    $candidatos = @(& git -C $Repo @argumentos)
    if ($LASTEXITCODE -gt 1) { throw 'No se pudieron buscar los archivos a reescribir.' }
    $modificados = @()
    foreach ($relativo in $candidatos) {
        if (-not $relativo) { continue }
        $ruta = Join-Path $Repo $relativo
        $texto = [IO.File]::ReadAllText($ruta, $utf8)
        $lineas = $texto -split "`n"
        for ($i = 0; $i -lt $lineas.Count; $i++) {
            if ($lineas[$i] -match 'Copyright|©') { continue }
            $lineas[$i] = [regex]::Replace($lineas[$i], $patron, $evaluador)
        }
        $nuevo = $lineas -join "`n"
        if ($nuevo -ne $texto) {
            [IO.File]::WriteAllText($ruta, $nuevo, $utf8)
            $modificados += $relativo
        }
    }
    return ,$modificados
}

function Save-Config {
    param([string]$Repo, $Valores)
    [IO.File]::WriteAllText((Join-Path $Repo 'instalacion.json'), ($Valores | ConvertTo-Json) + "`n", $utf8)
}

# 1. Modo y datos.
$archivoConfig = Join-Path $raiz 'instalacion.json'
$guardado = $null
if (Test-Path -LiteralPath $archivoConfig) {
    $guardado = Get-Content -LiteralPath $archivoConfig -Raw -Encoding UTF8 | ConvertFrom-Json
}
$reconfigurar = [bool]$guardado
if ($reconfigurar -and ($Destino -or $SinPublicar)) {
    Write-Warning 'Este repo ya está publicado: se reconfigura en el lugar y se ignoran -Destino y -SinPublicar.'
}

$parametros = @{
    aprobador = $Aprobador; cuenta_github = $Cuenta; email = $Email; arnes = $Arnes; coordinacion = $Coordinacion
}
$valores = [ordered]@{}
foreach ($clave in $claves) {
    $valores[$clave] = $parametros[$clave]
    if (-not $valores[$clave] -and $guardado) { $valores[$clave] = [string]$guardado.$clave }
}
if ($reconfigurar -and -not $Arnes) {
    # Si el repo se renombró, el remoto origin manda.
    $url = Invoke-Tolerante { git -C $raiz remote get-url origin }
    if ($LASTEXITCODE -eq 0 -and $url) {
        $detectado = ([string]$url).TrimEnd('/') -replace '\.git$', '' -replace '^.*[/:]', ''
        if ($detectado -and $detectado -ne $valores['arnes']) {
            Write-Output "El remoto origin indica otro nombre de arnés: $detectado (registrado: $($valores['arnes']))."
            $valores['arnes'] = $detectado
        }
    }
}

$preguntar = $true
if ($reconfigurar) {
    Write-Output 'Datos registrados en el repo:'
    foreach ($clave in $claves) { Write-Output ("  {0}: {1}" -f $etiquetas[$clave], $valores[$clave]) }
    if ($Si) { $preguntar = $false }
    else { $preguntar = -not (Test-Afirmativo (Read-Host '¿Son correctos? (s/n)')) }
}
if ($preguntar) {
    foreach ($clave in $claves) {
        $actual = $valores[$clave]
        if ($parametros[$clave] -and -not $reconfigurar) { continue }
        if (-not $actual -and $clave -eq 'coordinacion' -and $valores['cuenta_github']) {
            $actual = "$($valores['cuenta_github'])/SharedCord"
        }
        $valores[$clave] = Read-Valor $clave $actual
    }
}
elseif (-not $valores['coordinacion'] -and $valores['cuenta_github']) {
    $valores['coordinacion'] = "$($valores['cuenta_github'])/SharedCord"
}
if (-not $valores['coordinacion'] -and $valores['cuenta_github']) {
    $valores['coordinacion'] = "$($valores['cuenta_github'])/SharedCord"
}

foreach ($clave in $claves) {
    $valor = [string]$valores[$clave]
    if ([string]::IsNullOrWhiteSpace($valor) -or $valor -match '\{\{|\}\}|[\r\n]') {
        throw "$($etiquetas[$clave]) no es válido: '$valor'."
    }
}
if ($valores['cuenta_github'] -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$') { throw "Cuenta de GitHub inválida: $($valores['cuenta_github'])" }
if ($valores['email'] -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "Email inválido: $($valores['email'])" }
if ($valores['arnes'] -notmatch '^[A-Za-z0-9._-]+$') { throw "Nombre de arnés inválido: $($valores['arnes'])" }
if ($valores['coordinacion'] -notmatch '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$') { throw "Repo de coordinación inválido: $($valores['coordinacion'])" }
if (($valores['coordinacion'] -split '/')[1] -eq $valores['arnes']) { throw 'El repo de coordinación debe ser distinto del repo del arnés.' }
if ($valores['email'] -notmatch '@users\.noreply\.github\.com$') {
    Write-Warning 'El email no es un noreply de GitHub: quedará visible en el repo y en los commits.'
}
$repoArnes = "$($valores['cuenta_github'])/$($valores['arnes'])"

$reemplazos = @{}
foreach ($clave in $claves) {
    $reemplazos[$marcadores[$clave]] = $valores[$clave]
    if ($guardado -and $guardado.$clave -and [string]$guardado.$clave -ne $valores[$clave]) {
        $reemplazos[[string]$guardado.$clave] = $valores[$clave]
    }
}
$autor = @('-c', "user.name=$($valores['cuenta_github'])", '-c', "user.email=$($valores['email'])")
$etiquetaEventos = 'workflow'
$colorEventos = 'd4c5f9'
$descripcionEventos = 'Evento observado del flujo del arnés'

if ($reconfigurar) {
    # 2a. Reconfigurar en el lugar.
    $configCambia = $false
    foreach ($clave in $claves) {
        if ([string]$guardado.$clave -ne $valores[$clave]) { $configCambia = $true }
    }
    if (-not $configCambia) {
        Write-Output 'El repo ya tiene estos datos; no se reescribió.'
    }
    else {
        Assert-SinCambios $raiz
        $modificados = Update-Marcadores $raiz $reemplazos
        Save-Config $raiz $valores
        Invoke-Git $raiz add -- instalacion.json @modificados | Out-Null
        Invoke-Git $raiz @autor commit -q -m "Reconfigurar el arnés para $($valores['cuenta_github'])" | Out-Null
        Write-Output "Repo reconfigurado y commiteado: $($modificados.Count) archivos e instalacion.json."
        Write-Output 'Publicar el commit con el flujo habitual del repo y reinstalar en cada PC.'
    }
}
else {
    # 2b. Publicar: copia limpia de la revisión actual en un repo nuevo, sin historial.
    Assert-SinCambios $raiz
    if (-not $Destino) { $Destino = Join-Path (Split-Path -Parent $raiz) $valores['arnes'] }
    $Destino = [IO.Path]::GetFullPath($Destino)
    $raizConBarra = $raiz.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($Destino -eq $raiz -or $Destino.StartsWith($raizConBarra, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'El destino no puede estar dentro de este repo.'
    }
    if ((Test-Path -LiteralPath $Destino) -and @(Get-ChildItem -LiteralPath $Destino -Force).Count -gt 0) {
        throw "El destino no está vacío: $Destino"
    }

    if (-not $SinPublicar) {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            throw 'Se requiere GitHub CLI (gh) con sesión iniciada. Usar -SinPublicar para armar sólo el repo local.'
        }
        Invoke-Tolerante { gh auth status } | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI no tiene sesión iniciada: ejecutar gh auth login.' }
        Invoke-Tolerante { gh repo view $repoArnes --json name } | Out-Null
        if ($LASTEXITCODE -eq 0) { throw "$repoArnes ya existe. Elegir otro nombre o borrarlo antes." }
    }

    $archivos = @(Invoke-Git $raiz -c core.quotepath=false ls-files)
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    foreach ($relativo in $archivos) {
        if (-not $relativo -or $relativo -eq 'instalacion.json') { continue }
        $hasta = Join-Path $Destino $relativo
        $carpeta = Split-Path -Parent $hasta
        if (-not (Test-Path -LiteralPath $carpeta)) { New-Item -ItemType Directory -Path $carpeta -Force | Out-Null }
        Copy-Item -LiteralPath (Join-Path $raiz $relativo) -Destination $hasta -Force
    }
    Invoke-Git $Destino init -q -b main | Out-Null
    Invoke-Git $Destino add -A | Out-Null
    $modificados = Update-Marcadores $Destino $reemplazos
    Save-Config $Destino $valores
    Invoke-Git $Destino add -A | Out-Null
    Invoke-Git $Destino @autor commit -q -m 'Arnés para Codex y Claude Code' | Out-Null
    Invoke-Git $Destino branch dev | Out-Null
    Invoke-Git $Destino checkout -q dev | Out-Null
    Invoke-Git $Destino config user.name $valores['cuenta_github'] | Out-Null
    Invoke-Git $Destino config user.email $valores['email'] | Out-Null
    Write-Output "Repo armado en $Destino`: un commit en main y dev, $($modificados.Count) archivos configurados."

    if ($SinPublicar) {
        Write-Output "No se publicó. Para hacerlo: gh repo create $repoArnes --private --source `"$Destino`" --remote origin; git -C `"$Destino`" push -u origin main dev; gh repo edit $repoArnes --default-branch dev; gh label create $etiquetaEventos --repo $repoArnes --color $colorEventos --description `"$descripcionEventos`" --force"
    }
    else {
        & gh repo create $repoArnes --private --source $Destino --remote origin
        if ($LASTEXITCODE -ne 0) { throw "No se pudo crear $repoArnes." }
        Invoke-Tolerante { git -C $Destino push -q -u origin main dev } | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudieron subir main y dev a $repoArnes." }
        & gh repo edit $repoArnes --default-branch dev | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo dejar dev como rama predeterminada de $repoArnes." }
        # La plantilla "Evento observado" del arnés usa esta etiqueta; GitHub no la crea sola.
        & gh label create $etiquetaEventos --repo $repoArnes --color $colorEventos --description $descripcionEventos --force | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo crear la etiqueta $etiquetaEventos en $repoArnes." }
        Write-Output "Publicado: https://github.com/$repoArnes (privado, ramas main y dev, etiqueta $etiquetaEventos)."
    }
    Write-Output "Siguiente paso, en cada PC: clonar $repoArnes y ejecutar pwsh -File scripts/Instalar-Arnes.ps1 (ver docs/INSTALACION.md)."
}

# 3. Repo de coordinación: si no existe, se crea privado desde plantilla-coordinacion.
if ($SinCoordinacion) { return }
$repoCoordinacion = $valores['coordinacion']
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Warning "GitHub CLI no está instalado: verificar o crear $repoCoordinacion a mano (ver plantilla-coordinacion/README.md)."
    return
}
$visibilidad = Invoke-Tolerante { gh repo view $repoCoordinacion --json visibility --jq .visibility }
if ($LASTEXITCODE -eq 0) {
    if ($visibilidad -ne 'PRIVATE') { Write-Warning "$repoCoordinacion existe pero no es privado ($visibilidad)." }
    else { Write-Output "Repo de coordinación verificado: $repoCoordinacion (privado)." }
    return
}
if (-not $Si) {
    if (-not (Test-Afirmativo (Read-Host "$repoCoordinacion no existe o no es accesible. ¿Crearlo privado ahora? (s/n)"))) {
        Write-Output "No se creó $repoCoordinacion. Queda pendiente antes de la primera transferencia o dependencia."
        return
    }
}
$temporal = Join-Path ([IO.Path]::GetTempPath()) ("coordinacion-" + [guid]::NewGuid().ToString('N'))
& (Join-Path $PSScriptRoot 'Preparar-Plantilla.ps1') -Tipo coordinacion -Destino $temporal | Out-Null
Invoke-Git $temporal init -q -b main | Out-Null
Invoke-Git $temporal add -A | Out-Null
Invoke-Git $temporal @autor commit -q -m 'Plantillas de coordinación' | Out-Null
& gh repo create $repoCoordinacion --private --source $temporal --push
if ($LASTEXITCODE -ne 0) { throw "No se pudo crear $repoCoordinacion." }
foreach ($etiqueta in (Get-Content -LiteralPath (Join-Path $temporal 'labels.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) {
    & gh label create $etiqueta.name --repo $repoCoordinacion --color $etiqueta.color --description $etiqueta.description --force | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo crear la etiqueta $($etiqueta.name)." }
}
Remove-Item -LiteralPath $temporal -Recurse -Force
Write-Output "Repo de coordinación creado: $repoCoordinacion (privado, con plantillas y etiquetas)."

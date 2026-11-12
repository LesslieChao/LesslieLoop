[CmdletBinding()]
param(
    # Carpeta personal donde se instala. Por defecto, la del usuario.
    [string]$Inicio = $HOME
)

# Instala el arnés en esta PC desde un repo ya publicado y configurado con Publicar-Arnes.ps1.
# No pide datos, no reescribe el repo ni commitea.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$raiz = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$archivoConfig = Join-Path $raiz 'instalacion.json'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$claves = @('aprobador', 'cuenta_github', 'email', 'arnes', 'coordinacion')

function Invoke-Git {
    $salida = & git -C $raiz @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') falló." }
    return $salida
}

# 1. Datos del repo publicado.
if (-not (Test-Path -LiteralPath $archivoConfig)) {
    throw 'Este repo no está configurado (falta instalacion.json). Primero publicarlo en la cuenta propia con scripts/Publicar-Arnes.ps1 (ver docs/PUBLICACION.md) e instalar desde ese repo.'
}
$guardado = Get-Content -LiteralPath $archivoConfig -Raw -Encoding UTF8 | ConvertFrom-Json
$valores = [ordered]@{}
foreach ($clave in $claves) {
    $valores[$clave] = [string]$guardado.$clave
    if ([string]::IsNullOrWhiteSpace($valores[$clave])) { throw "instalacion.json no tiene $clave. Corregirlo con scripts/Publicar-Arnes.ps1." }
}
$argumentos = @('grep', '-I', '-l', '-F')
foreach ($nombre in @('APROBADOR', 'CUENTA_GITHUB', 'EMAIL', 'ARNES', 'COORDINACION')) { $argumentos += @('-e', ('{{' + $nombre + '}}')) }
$argumentos += @('--', '.', ':!scripts/Publicar-Arnes.ps1', ':!scripts/Instalar-Arnes.ps1', ':!scripts/verificar_plantillas.py')
$pendientes = @(& git -C $raiz @argumentos)
if ($LASTEXITCODE -gt 1) { throw 'No se pudo revisar el repo.' }
if ($pendientes.Count -gt 0 -and $pendientes[0]) {
    throw "El repo tiene marcadores sin configurar ($($pendientes -join ', ')). Ejecutar scripts/Publicar-Arnes.ps1."
}
Write-Output "Instalando $($valores['arnes']) de $($valores['cuenta_github']) (aprueba: $($valores['aprobador']))."

# 2. Identidad Git de este clon.
Invoke-Git config user.name $valores['cuenta_github'] | Out-Null
Invoke-Git config user.email $valores['email'] | Out-Null

# 3. Instalar en la carpeta personal.
$base = Join-Path $Inicio ".$($valores['arnes'])"
function Copy-Archivo {
    param([string]$Origen, [string]$Destino)
    $carpeta = Split-Path -Parent $Destino
    if (-not (Test-Path -LiteralPath $carpeta)) { New-Item -ItemType Directory -Path $carpeta -Force | Out-Null }
    Copy-Item -LiteralPath (Join-Path $raiz $Origen) -Destination $Destino -Force
}
foreach ($par in @(@('.agents/skills', '.agents/skills'), @('.claude/skills', '.claude/skills'))) {
    $destinoSkills = Join-Path $Inicio $par[1]
    if (-not (Test-Path -LiteralPath $destinoSkills)) { New-Item -ItemType Directory -Path $destinoSkills -Force | Out-Null }
    foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $raiz $par[0]) -Directory) {
        $destinoSkill = Join-Path $destinoSkills $skill.Name
        if (Test-Path -LiteralPath $destinoSkill) { Remove-Item -LiteralPath $destinoSkill -Recurse -Force }
        Copy-Item -LiteralPath $skill.FullName -Destination $destinoSkill -Recurse -Force
    }
}
$inicioBloque = "<!-- inicio: $($valores['arnes']) -->"
$finBloque = "<!-- fin: $($valores['arnes']) -->"
foreach ($par in @(@('personal/AGENTS.md', '.codex/AGENTS.md'), @('personal/CLAUDE.md', '.claude/CLAUDE.md'))) {
    $destino = Join-Path $Inicio $par[1]
    $bloque = $inicioBloque + "`n" + [IO.File]::ReadAllText((Join-Path $raiz $par[0]), $utf8).TrimEnd() + "`n" + $finBloque
    $actual = ''
    if (Test-Path -LiteralPath $destino) { $actual = [IO.File]::ReadAllText($destino, $utf8) }
    else { New-Item -ItemType Directory -Path (Split-Path -Parent $destino) -Force | Out-Null }
    $patronBloque = '(?s)' + [regex]::Escape($inicioBloque) + '.*?' + [regex]::Escape($finBloque)
    if ($actual -match $patronBloque) {
        $resultado = [regex]::Replace($actual, $patronBloque, [System.Text.RegularExpressions.MatchEvaluator] { param($m) $bloque })
    }
    elseif ($actual.Trim()) { $resultado = $actual.TrimEnd() + "`n`n" + $bloque + "`n" }
    else { $resultado = $bloque + "`n" }
    [IO.File]::WriteAllText($destino, $resultado, $utf8)
}
foreach ($plantilla in @('personal/PROJECT.template.md', 'personal/OWNERS.template.md', 'HANDOFF.template.md')) {
    Copy-Archivo $plantilla (Join-Path (Join-Path $base 'templates') (Split-Path -Leaf $plantilla))
}
foreach ($documento in @('CONTRATO_HANDOFF.md', 'PRINCIPIOS_DISENO.md', 'CRITERIOS_ENTREGA_PRODUCTO.md', 'INSTALACION.md')) {
    Copy-Archivo "docs/$documento" (Join-Path $base $documento)
}
foreach ($script in @('Preparar-Proyecto.ps1', 'Generar-CodeGraph.ps1', 'Verificar-Identidad-Git.ps1',
                      'Iniciar-Sin-Deteccion-De-Agente.ps1', 'Verificar-Artefactos-Agente-Next.ps1')) {
    Copy-Archivo "scripts/$script" (Join-Path (Join-Path $base 'scripts') $script)
}
$revision = [string](Invoke-Git rev-parse HEAD)
$registro = [ordered]@{ revision = $revision; fecha = (Get-Date).ToString('yyyy-MM-dd'); origen = $raiz }
foreach ($clave in $claves) { $registro[$clave] = $valores[$clave] }
[IO.File]::WriteAllText((Join-Path $base 'instalacion.json'), ($registro | ConvertTo-Json) + "`n", $utf8)
Write-Output "Arnés instalado en $Inicio (estado en $base), revisión $revision."

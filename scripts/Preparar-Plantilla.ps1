[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('producto','coordinacion')][string]$Tipo,
    [Parameter(Mandatory)][string]$Destino
)

$ErrorActionPreference = 'Stop'
function Resolve-RutaCompleta {
    param([Parameter(Mandatory)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

$raizArnes = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$carpetaFuente = if ($Tipo -eq 'producto') { 'plantilla-proyecto' } else { 'plantilla-coordinacion' }
$fuente = Join-Path $raizArnes $carpetaFuente
$salida = Resolve-RutaCompleta $Destino
$comparacion = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$prefijoArnes = $raizArnes.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if ($salida.Equals($raizArnes, $comparacion) -or $salida.StartsWith($prefijoArnes, $comparacion)) {
    throw 'El destino debe estar fuera del repositorio del arnés.'
}
if (Test-Path -LiteralPath $salida) {
    if (!(Test-Path -LiteralPath $salida -PathType Container)) { throw 'El destino no es una carpeta.' }
    if (@(Get-ChildItem -LiteralPath $salida -Force).Count -gt 0) {
        throw 'El destino contiene archivos. Generar en una carpeta vacía y comparar antes de incorporar.'
    }
}
else {
    New-Item -ItemType Directory -Path $salida | Out-Null
}

# Force permite copiar .github y .gitignore incluso si el sistema los oculta.
Get-ChildItem -LiteralPath $fuente -Force | Copy-Item -Destination $salida -Recurse -Force
Write-Output "Plantilla $Tipo preparada en $salida"
Write-Output 'No se inicializó Git ni se configuró un remoto.'

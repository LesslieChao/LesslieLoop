[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Contenedor,
    [Parameter(Mandatory)][string]$Repositorio,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][ValidatePattern('^WT[0-9]{2}$')][string]$IdWT,
    [Parameter(Mandatory)][string]$Titulo,
    [Parameter(Mandatory)][string]$Rama
)

$ErrorActionPreference = 'Stop'
function Resolve-RutaCompleta {
    param([Parameter(Mandatory)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

$raiz = Resolve-RutaCompleta $Contenedor
$tituloLimpio = $Titulo.Trim()
if (!$tituloLimpio -or $tituloLimpio -match '[\x00-\x1f\\/:*?"<>|]' -or $tituloLimpio.EndsWith('.') -or $tituloLimpio.EndsWith(' ')) {
    throw 'El título del WT no es válido como nombre de carpeta.'
}
$nombreWT = "$IdWT - $tituloLimpio"
$repo = Join-Path $raiz 'repo'
$worktrees = Join-Path $raiz 'worktrees'
$wt = Join-Path $worktrees $nombreWT

if (!(Test-Path -LiteralPath $raiz -PathType Container)) {
    throw 'La carpeta contenedora debe existir antes de iniciar el proyecto.'
}
if (@(Get-ChildItem -LiteralPath $raiz -Force).Count -gt 0) {
    throw 'La carpeta contenedora debe estar vacía. Una inicialización parcial se reconcilia manualmente.'
}

git clone -- $Repositorio $repo
if ($LASTEXITCODE -ne 0) { throw 'No se pudo clonar el repositorio en repo/.' }
New-Item -ItemType Directory -Path $worktrees | Out-Null

git -C $repo rev-parse --verify --quiet "origin/$Base^{commit}" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "No existe la base remota origin/$Base." }
git -C $repo show-ref --verify --quiet "refs/heads/$Rama"
if ($LASTEXITCODE -eq 0) { throw "La rama local ya existe: $Rama" }
git -C $repo worktree add --no-track -b $Rama $wt "origin/$Base"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el primer worktree.' }

$comun = git -C $wt rev-parse --git-common-dir
$head = git -C $wt rev-parse HEAD
$branch = git -C $wt branch --show-current
if ($LASTEXITCODE -ne 0 -or !$branch) { throw 'El worktree creado no quedó en una rama verificable.' }
$upstreamRemote = git -C $wt config --get "branch.$branch.remote"
if ($LASTEXITCODE -eq 0 -and $upstreamRemote) { throw 'La rama del primer worktree no debe quedar siguiendo a un upstream.' }
$upstreamMerge = git -C $wt config --get "branch.$branch.merge"
if ($LASTEXITCODE -eq 0 -and $upstreamMerge) { throw 'La rama del primer worktree no debe quedar siguiendo a un upstream.' }

Write-Output "Contenedor: $raiz"
Write-Output "Checkout administrativo: $repo"
Write-Output "Directorio de worktrees: $worktrees"
Write-Output "WT: $wt"
Write-Output "Branch: $branch"
Write-Output "HEAD: $head"
Write-Output "Git common dir: $comun"

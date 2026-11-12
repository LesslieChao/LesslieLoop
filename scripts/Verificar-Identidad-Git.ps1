[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RepoPath,
    [Parameter(Mandatory)][string]$ExpectedEmail,
    [string]$ExpectedName,
    [string]$RevisionRange,
    [switch]$RequireGitHubNoreply
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ExpectedEmail) -or $ExpectedEmail -match 'pendiente|TODO|<|>') {
    throw 'ExpectedEmail no está definido con un valor real. No crear ni publicar commits.'
}

if ($RequireGitHubNoreply -and $ExpectedEmail -notmatch '^[0-9]+\+[^@\s]+@users\.noreply\.github\.com$') {
    throw "ExpectedEmail no tiene formato GitHub noreply con ID: $ExpectedEmail"
}

$repo = (Resolve-Path -LiteralPath $RepoPath).Path
git -C $repo rev-parse --is-inside-work-tree | Out-Null
if ($LASTEXITCODE -ne 0) { throw "No es un worktree Git válido: $repo" }

$actualName = (git -C $repo config --get user.name)
if ($LASTEXITCODE -ne 0) { $actualName = '' }
$actualEmail = (git -C $repo config --get user.email)
if ($LASTEXITCODE -ne 0) { $actualEmail = '' }

if ($ExpectedName -and $actualName -ne $ExpectedName) {
    throw "Identidad Git inválida: user.name='$actualName', esperado '$ExpectedName'."
}

if ($actualEmail -ne $ExpectedEmail) {
    throw "Identidad Git inválida: user.email='$actualEmail', esperado '$ExpectedEmail'. No crear commits. Corregir con: git config user.email `"$ExpectedEmail`""
}

if ($RevisionRange) {
    $rangeArgs = @($RevisionRange)
    if ($RevisionRange -notmatch '\.\.|\^|--not') {
        $rangeArgs = @('-n', '1', $RevisionRange)
    }
    $lines = @(git -C $repo log --format='%H%x00%an%x00%ae%x00%cn%x00%ce' @rangeArgs --)
    if ($LASTEXITCODE -ne 0) { throw "No se pudo leer el rango de commits: $RevisionRange" }
    foreach ($line in $lines) {
        if (-not $line) { continue }
        $parts = $line -split "`0", 5
        if ($parts.Count -ne 5) { throw "Salida de git log inesperada para identidad: $line" }
        $sha = $parts[0]
        $authorEmail = $parts[2]
        $committerEmail = $parts[4]
        if ($authorEmail -ne $ExpectedEmail -or $committerEmail -ne $ExpectedEmail) {
            throw "Commit $sha tiene identidad no autorizada: author <$authorEmail>, committer <$committerEmail>, esperado <$ExpectedEmail>. No transferir, publicar ni mergear."
        }
    }
}

Write-Output "Identidad Git verificada: $actualName <$actualEmail>"
if ($RevisionRange) { Write-Output "Rango verificado: $RevisionRange" }

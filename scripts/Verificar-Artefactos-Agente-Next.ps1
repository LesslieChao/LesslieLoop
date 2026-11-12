[CmdletBinding()]
param(
    [string]$RepoPath = "."
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param([string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Invoke-Git {
    param(
        [string]$Repo,
        [string[]]$Arguments
    )
    $output = & git -C $Repo @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git falló: git -C $Repo $($Arguments -join ' ')`n$output"
    }
    return $output
}

$repo = Resolve-FullPath $RepoPath
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    throw "RepoPath no existe o no es carpeta: $repo"
}

[void](Invoke-Git -Repo $repo -Arguments @("rev-parse", "--show-toplevel"))

$candidatos = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($args in @(
    @("diff", "--name-only", "--cached"),
    @("diff", "--name-only"),
    @("ls-files", "--others", "--exclude-standard")
)) {
    $salida = Invoke-Git -Repo $repo -Arguments $args
    foreach ($linea in $salida) {
        $rel = [string]$linea
        if ($rel.Trim()) {
            [void]$candidatos.Add($rel.Trim())
        }
    }
}

$hallazgos = New-Object System.Collections.Generic.List[string]
$marker = "<!-- BEGIN:nextjs-agent-rules -->"

foreach ($rel in $candidatos) {
    $abs = Join-Path $repo $rel
    if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) {
        continue
    }

    $texto = Get-Content -LiteralPath $abs -Raw -Encoding UTF8
    $nombre = Split-Path -Leaf $rel

    if ($texto.Contains($marker)) {
        $hallazgos.Add("$rel contiene $marker")
    }
    if ($nombre -ieq "CLAUDE.md" -and $texto.Trim() -eq "@AGENTS.md") {
        $hallazgos.Add("$rel parece generado por Next: contiene sólo @AGENTS.md")
    }
    if ($nombre -ieq "next-env.d.ts" -and $texto -match "(^|[\\/])\.next[\\/]dev[\\/]types") {
        $hallazgos.Add("$rel apunta a .next/dev/types")
    }
}

if ($hallazgos.Count -gt 0) {
    Write-Error ("Artefactos de agente generados por Next detectados:`n- " +
        ($hallazgos -join "`n- ") +
        "`nRemediación: no versionar AGENTS.md/CLAUDE.md generados, revertir next-env.d.ts si sólo cambió a .next/dev/types, y levantar el dev server con Iniciar-Sin-Deteccion-De-Agente.ps1.")
    exit 1
}

Write-Output "OK: no se detectaron artefactos de agente generados por Next."
exit 0

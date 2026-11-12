[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Comando
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

if (-not $Comando -or $Comando.Count -eq 0) {
    throw "Indicar el comando a ejecutar. Ejemplo: pwsh -File Iniciar-Sin-Deteccion-De-Agente.ps1 npm run dev"
}

$nombresExactos = @(
    "CLAUDECODE",
    "CLAUDE_CODE",
    "CLAUDE_CODE_IS_COWORK",
    "CODEX_THREAD_ID",
    "CODEX_SANDBOX",
    "CODEX_CI",
    "AI_AGENT",
    "GEMINI_CLI",
    "OPENCODE_CLIENT",
    "REPL_ID"
)
$prefijos = @("CURSOR_", "COPILOT_")

$backup = @{}
$aLimpiar = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

foreach ($nombre in $nombresExactos) {
    [void]$aLimpiar.Add($nombre)
}

foreach ($item in Get-ChildItem Env:) {
    foreach ($prefijo in $prefijos) {
        if ($item.Name.StartsWith($prefijo, [StringComparison]::OrdinalIgnoreCase)) {
            [void]$aLimpiar.Add($item.Name)
        }
    }
}

foreach ($nombre in $aLimpiar) {
    $valor = [Environment]::GetEnvironmentVariable($nombre, "Process")
    if ($null -ne $valor) {
        $backup[$nombre] = $valor
        Remove-Item -LiteralPath "Env:\$nombre" -ErrorAction SilentlyContinue
    }
}

$exitCode = 0
try {
    $ejecutable = $Comando[0]
    $argumentos = @()
    if ($Comando.Count -gt 1) {
        $argumentos = $Comando[1..($Comando.Count - 1)]
    }

    $global:LASTEXITCODE = $null
    & $ejecutable @argumentos
    if ($global:LASTEXITCODE -is [int]) {
        $exitCode = $global:LASTEXITCODE
    } elseif (-not $?) {
        $exitCode = 1
    }
} catch {
    Write-Error $_
    $exitCode = 1
} finally {
    foreach ($nombre in $aLimpiar) {
        Remove-Item -LiteralPath "Env:\$nombre" -ErrorAction SilentlyContinue
    }
    foreach ($entrada in $backup.GetEnumerator()) {
        Set-Item -LiteralPath "Env:\$($entrada.Key)" -Value $entrada.Value
    }
}

exit $exitCode

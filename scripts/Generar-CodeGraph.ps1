param(
    [Parameter(Mandatory = $true)]
    [string]$WTPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [string]$WT = '',

    [int]$MaxFileBytes = 262144,

    [int]$MaxFiles = 2000
)

$ErrorActionPreference = 'Stop'

function Run-Git {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Args
    )
    $output = & git -C $Path @Args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') fallo en $Path`: $output"
    }
    return ($output -join "`n")
}

function Normalize-RelPath {
    param([string]$Path)
    return ($Path -replace '\\', '/')
}

function Is-Excluded {
    param([string]$RelPath)
    $segments = (Normalize-RelPath $RelPath).Split('/')
    $excludedDirs = @(
        '.git', '.hg', '.svn',
        'node_modules', '.pnpm-store',
        'dist', 'build', 'coverage', 'out', 'output',
        '.next', '.nuxt', '.turbo', '.cache',
        '.venv', 'venv', '__pycache__',
        '.pytest_cache', '.mypy_cache', '.ruff_cache',
        'target', 'bin', 'obj'
    )
    foreach ($segment in $segments) {
        if ($excludedDirs -contains $segment) { return $true }
    }
    return $false
}

function Is-BinaryLike {
    param([string]$RelPath)
    $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    return @(
        '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.bmp',
        '.pdf', '.zip', '.7z', '.gz', '.tar', '.rar',
        '.mp4', '.mov', '.avi', '.mp3', '.wav',
        '.woff', '.woff2', '.ttf', '.otf',
        '.exe', '.dll', '.so', '.dylib', '.class', '.jar',
        '.db', '.sqlite', '.sqlite3'
    ) -contains $ext
}

function Get-Kind {
    param([string]$RelPath)
    $name = [IO.Path]::GetFileName($RelPath).ToLowerInvariant()
    $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    $path = Normalize-RelPath $RelPath
    if ($path -match '(^|/)(test|tests|spec|specs|__tests__)(/|$)' -or $name -match '\.(test|spec)\.') { return 'test' }
    if ($name -in @('package.json', 'pyproject.toml', 'requirements.txt', 'requirements.lock', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock', 'dockerfile', 'docker-compose.yml', 'docker-compose.yaml')) { return 'manifest' }
    if ($path -like '.github/workflows/*') { return 'ci' }
    if ($ext -in @('.md', '.rst', '.adoc')) { return 'doc' }
    if ($ext -in @('.json', '.yaml', '.yml', '.toml', '.ini', '.env', '.example')) { return 'config' }
    if ($ext -in @('.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.py', '.ps1', '.sh', '.go', '.rs', '.java', '.cs', '.php', '.rb', '.swift', '.kt', '.sql')) { return 'source' }
    return 'other'
}

function Add-Matches {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string]$Text,
        [string]$Pattern,
        [int]$Group = 1,
        [int]$Limit = 40
    )
    foreach ($match in [regex]::Matches($Text, $Pattern, 'Multiline')) {
        if ($Target.Count -ge $Limit) { break }
        $value = $match.Groups[$Group].Value.Trim()
        if ($value -and !$Target.Contains($value)) { [void]$Target.Add($value) }
    }
}

function Extract-Symbols {
    param([string]$RelPath, [string]$Text)
    $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    $symbols = [System.Collections.Generic.List[string]]::new()
    if ($ext -in @('.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs')) {
        Add-Matches $symbols $Text '^\s*(?:export\s+)?(?:async\s+)?function\s+([A-Za-z_$][\w$]*)'
        Add-Matches $symbols $Text '^\s*(?:export\s+)?class\s+([A-Za-z_$][\w$]*)'
        Add-Matches $symbols $Text '^\s*(?:export\s+)?interface\s+([A-Za-z_$][\w$]*)'
        Add-Matches $symbols $Text '^\s*(?:export\s+)?type\s+([A-Za-z_$][\w$]*)'
        Add-Matches $symbols $Text '^\s*export\s+const\s+([A-Za-z_$][\w$]*)'
    } elseif ($ext -eq '.py') {
        Add-Matches $symbols $Text '^\s*(?:async\s+)?def\s+([A-Za-z_]\w*)'
        Add-Matches $symbols $Text '^\s*class\s+([A-Za-z_]\w*)'
    } elseif ($ext -eq '.ps1') {
        Add-Matches $symbols $Text '^\s*function\s+([A-Za-z_][\w-]*)'
    } elseif ($ext -in @('.go', '.rs', '.java', '.cs', '.php', '.rb', '.swift', '.kt')) {
        Add-Matches $symbols $Text '^\s*(?:export\s+|public\s+|private\s+|protected\s+|func\s+|fn\s+|def\s+|class\s+|interface\s+|struct\s+|enum\s+)+([A-Za-z_][\w]*)'
    } elseif ($ext -in @('.md', '.rst')) {
        Add-Matches $symbols $Text '^\s{0,3}#{1,3}\s+(.+)$'
    }
    return @($symbols | Select-Object -First 25)
}

function Extract-Deps {
    param([string]$RelPath, [string]$Text)
    $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    $deps = [System.Collections.Generic.List[string]]::new()
    if ($ext -in @('.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs')) {
        Add-Matches $deps $Text '(?:import\s+.*?\s+from\s+|import\s*)["'']([^"'']+)["'']'
        Add-Matches $deps $Text 'require\(\s*["'']([^"'']+)["'']\s*\)'
    } elseif ($ext -eq '.py') {
        Add-Matches $deps $Text '^\s*from\s+([A-Za-z_][\w\.]*)\s+import\s+'
        Add-Matches $deps $Text '^\s*import\s+([A-Za-z_][\w\.]*)'
    }
    return @($deps | Select-Object -First 40)
}

function Resolve-RelativeImport {
    param(
        [string]$FromRelPath,
        [string]$Dep,
        [hashtable]$KnownFiles
    )
    if (!$Dep.StartsWith('.')) { return $null }
    $fromDir = Split-Path -Path (Normalize-RelPath $FromRelPath) -Parent
    $raw = if ([string]::IsNullOrEmpty($fromDir)) { $Dep } else { "$fromDir/$Dep" }
    $parts = (Normalize-RelPath $raw).Split('/')
    $stack = [System.Collections.Generic.List[string]]::new()
    foreach ($part in $parts) {
        if ([string]::IsNullOrWhiteSpace($part) -or $part -eq '.') { continue }
        if ($part -eq '..') {
            if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }
            continue
        }
        [void]$stack.Add($part)
    }
    $base = $stack -join '/'
    $candidates = @(
        $base,
        "$base.ts", "$base.tsx", "$base.js", "$base.jsx", "$base.mjs", "$base.cjs",
        "$base.py", "$base.ps1",
        "$base/index.ts", "$base/index.tsx", "$base/index.js", "$base/index.jsx", "$base/__init__.py"
    )
    foreach ($candidate in $candidates) {
        if ($KnownFiles.ContainsKey($candidate)) { return $candidate }
    }
    return $null
}

$resolvedWT = (Resolve-Path -LiteralPath $WTPath).Path
$repoRoot = (Run-Git -Path $resolvedWT rev-parse --show-toplevel).Trim()
$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path

$outputFull = [IO.Path]::GetFullPath($OutputRoot)
if ($outputFull.StartsWith($repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputRoot no puede estar dentro del repo del producto.'
}
New-Item -ItemType Directory -Path $outputFull -Force | Out-Null

$branch = (Run-Git -Path $repoRoot branch --show-current).Trim()
$head = (Run-Git -Path $repoRoot rev-parse HEAD).Trim()
$status = (& git -C $repoRoot status --short) -join "`n"
$trackedRaw = Run-Git -Path $repoRoot ls-files -z --cached --others --exclude-standard
$relPaths = @($trackedRaw -split "`0" | Where-Object { $_ })

$skipped = [ordered]@{
    excluded = 0
    binary = 0
    large = 0
    unreadable = 0
    over_limit = 0
}

$selected = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $relPaths) {
    $norm = Normalize-RelPath $rel
    if (Is-Excluded $norm) { $skipped.excluded++; continue }
    if (Is-BinaryLike $norm) { $skipped.binary++; continue }
    $full = Join-Path $repoRoot $norm
    if (!(Test-Path -LiteralPath $full)) { continue }
    $item = Get-Item -LiteralPath $full
    if ($item.Length -gt $MaxFileBytes) { $skipped.large++; continue }
    if ($selected.Count -ge $MaxFiles) { $skipped.over_limit++; continue }
    [void]$selected.Add($norm)
}

$knownFiles = @{}
foreach ($rel in $selected) { $knownFiles[$rel] = $true }

$files = [System.Collections.Generic.List[object]]::new()
$edges = [System.Collections.Generic.List[object]]::new()

foreach ($rel in $selected) {
    $full = Join-Path $repoRoot $rel
    try {
        $text = Get-Content -LiteralPath $full -Raw -Encoding UTF8
    } catch {
        $skipped.unreadable++
        continue
    }
    $deps = Extract-Deps $rel $text
    foreach ($dep in $deps) {
        $resolved = Resolve-RelativeImport $rel $dep $knownFiles
    [void]$edges.Add([pscustomobject][ordered]@{
            from = $rel
            to = $(if ($resolved) { $resolved } else { $dep })
            kind = $(if ($resolved) { 'relative' } else { 'external' })
        })
    }
    $lineCount = if ($text.Length -eq 0) { 0 } else { ([regex]::Matches($text, "`n")).Count + 1 }
    $item = Get-Item -LiteralPath $full
    [void]$files.Add([pscustomobject][ordered]@{
        path = $rel
        kind = Get-Kind $rel
        extension = [IO.Path]::GetExtension($rel).ToLowerInvariant()
        bytes = $item.Length
        lines = $lineCount
        symbols = @(Extract-Symbols $rel $text)
        deps = @($deps)
    })
}

$generatedAt = (Get-Date).ToUniversalTime().ToString('o')
$graph = [ordered]@{
    schema = 'codegraph-v1'
    generated_at = $generatedAt
    wt = $WT
    repo_root = $repoRoot
    branch = $branch
    head = $head
    dirty = [bool]($status.Trim())
    status_short = $status
    limits = [ordered]@{
        max_file_bytes = $MaxFileBytes
        max_files = $MaxFiles
    }
    skipped = $skipped
    files = @($files)
    edges = @($edges)
}

$graphPath = Join-Path $outputFull 'graph.json'
$summaryPath = Join-Path $outputFull 'resumen.md'
$manifestPath = Join-Path $outputFull 'manifest.md'

$graph | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $graphPath -Encoding UTF8
$graphHash = (Get-FileHash -LiteralPath $graphPath -Algorithm SHA256).Hash.ToLowerInvariant()

$byKind = @($files | Group-Object kind | Sort-Object Name)
$byExt = @($files | Group-Object extension | Sort-Object Count -Descending | Select-Object -First 15)
$byDir = @($files | ForEach-Object {
        $parts = $_.path.Split('/')
        if ($parts.Count -gt 1) { $parts[0] } else { '.' }
    } | Group-Object | Sort-Object Count -Descending | Select-Object -First 15)
$entryNames = @('package.json', 'pyproject.toml', 'README.md', 'Dockerfile', 'docker-compose.yml', 'docker-compose.yaml')
$entrypoints = @($files | Where-Object {
        $name = [IO.Path]::GetFileName($_.path)
        $entryNames -contains $name -or $_.path -match '(^|/)(src|app)/(main|index|app)\.'
    } | Select-Object -First 25)
$denseFiles = @($files | Sort-Object @{ Expression = { $_.symbols.Count }; Descending = $true }, @{ Expression = { $_.deps.Count }; Descending = $true }, @{ Expression = { $_.lines }; Descending = $true } | Select-Object -First 20)
$relativeEdges = @($edges | Where-Object { $_.kind -eq 'relative' } | Select-Object -First 30)

$summary = [System.Collections.Generic.List[string]]::new()
[void]$summary.Add("# CodeGraph $WT")
[void]$summary.Add("")
[void]$summary.Add("- Generado UTC: $generatedAt")
[void]$summary.Add("- Branch: $branch")
[void]$summary.Add("- HEAD: $head")
[void]$summary.Add("- Estado Git: $(if ($status.Trim()) { 'sucio' } else { 'limpio' })")
[void]$summary.Add("- Archivos mapeados: $($files.Count); edges: $($edges.Count); graph SHA256: $graphHash")
[void]$summary.Add("")
[void]$summary.Add("## Uso para ahorrar contexto")
[void]$summary.Add("")
[void]$summary.Add("Leer este resumen antes de abrir carpetas completas. Usar graph.json para ubicar archivos, simbolos y dependencias; abrir codigo fuente solamente cuando el encargo lo necesite.")
[void]$summary.Add("")
[void]$summary.Add("## Tipos de archivo")
[void]$summary.Add("")
foreach ($group in $byKind) { [void]$summary.Add("- $($group.Name): $($group.Count)") }
[void]$summary.Add("")
[void]$summary.Add("## Extensiones principales")
[void]$summary.Add("")
foreach ($group in $byExt) {
    $label = if ($group.Name) { $group.Name } else { '(sin extension)' }
    [void]$summary.Add("- ${label}: $($group.Count)")
}
[void]$summary.Add("")
[void]$summary.Add("## Directorios principales")
[void]$summary.Add("")
foreach ($group in $byDir) { [void]$summary.Add("- $($group.Name): $($group.Count)") }
[void]$summary.Add("")
[void]$summary.Add("## Entradas y manifiestos")
[void]$summary.Add("")
foreach ($file in $entrypoints) { [void]$summary.Add("- $($file.path) [$($file.kind)]") }
if ($entrypoints.Count -eq 0) { [void]$summary.Add("- No se detectaron entradas obvias.") }
[void]$summary.Add("")
[void]$summary.Add("## Archivos con mas senales")
[void]$summary.Add("")
foreach ($file in $denseFiles) {
    $symbols = if ($file.symbols.Count) { " simbolos=$($file.symbols.Count)" } else { '' }
    $depsText = if ($file.deps.Count) { " deps=$($file.deps.Count)" } else { '' }
    [void]$summary.Add("- $($file.path) [$($file.kind), $($file.lines) lineas$symbols$depsText]")
}
[void]$summary.Add("")
[void]$summary.Add("## Dependencias relativas detectadas")
[void]$summary.Add("")
foreach ($edge in $relativeEdges) { [void]$summary.Add("- $($edge.from) -> $($edge.to)") }
if ($relativeEdges.Count -eq 0) { [void]$summary.Add("- No se detectaron dependencias relativas.") }
[void]$summary.Add("")
[void]$summary.Add("## Omitidos")
[void]$summary.Add("")
foreach ($key in $skipped.Keys) { [void]$summary.Add("- ${key}: $($skipped[$key])") }
$summary -join "`n" | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$manifest = @(
    "# Manifest CodeGraph $WT",
    "",
    "- Schema: codegraph-v1",
    "- WT path: $resolvedWT",
    "- Repo root: $repoRoot",
    "- OutputRoot: $outputFull",
    "- Graph: graph.json",
    "- Summary: resumen.md",
    "- Graph SHA256: $graphHash",
    "- MaxFileBytes: $MaxFileBytes",
    "- MaxFiles: $MaxFiles",
    "- Excluye ruido de dependencias, builds, caches, binarios y archivos grandes.",
    "- No es fuente de verdad: Git y los archivos reales prevalecen."
)
$manifest -join "`n" | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Output "CodeGraph generado en $outputFull"
Write-Output "Archivos: $($files.Count); edges: $($edges.Count); SHA256: $graphHash"

param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutablePath,

    [string]$OutputZip
)

$ErrorActionPreference = 'Stop'

$exe = Get-Item -LiteralPath $ExecutablePath -ErrorAction Stop
$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoRoot = (Resolve-Path (Join-Path $clientRoot '..')).Path
$stageRoot = Join-Path $clientRoot 'dist/windows'
$downloadsRoot = Join-Path $repoRoot 'frontend/public/downloads/windows'

if ([string]::IsNullOrWhiteSpace($OutputZip)) {
    $OutputZip = Join-Path $downloadsRoot 'adventure-ots-client-windows.zip'
}

if (Test-Path $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageRoot | Out-Null

Copy-Item -LiteralPath $exe.FullName -Destination (Join-Path $stageRoot 'otclient.exe') -Force

Get-ChildItem -LiteralPath $exe.Directory.FullName -Filter '*.dll' -File |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $stageRoot $_.Name) -Force }

$resourceDirs = @('data', 'modules', 'mods', 'records')
foreach ($dir in $resourceDirs) {
    $sourceDir = Join-Path $clientRoot $dir
    if (Test-Path $sourceDir) {
        Copy-Item -LiteralPath $sourceDir -Destination (Join-Path $stageRoot $dir) -Recurse -Force
    }
}

$resourceFiles = @('init.lua', 'meta.lua', 'config.ini', 'otclientrc.lua', 'cacert.pem')
foreach ($file in $resourceFiles) {
    $sourceFile = Join-Path $clientRoot $file
    if (Test-Path $sourceFile) {
        Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $stageRoot $file) -Force
    }
}

if (-not (Test-Path $downloadsRoot)) {
    New-Item -ItemType Directory -Path $downloadsRoot -Force | Out-Null
}

if (Test-Path $OutputZip) {
    Remove-Item -LiteralPath $OutputZip -Force
}

Compress-Archive -Path (Join-Path $stageRoot '*') -DestinationPath $OutputZip -CompressionLevel Optimal
Write-Host "Packaged Windows client to $OutputZip"

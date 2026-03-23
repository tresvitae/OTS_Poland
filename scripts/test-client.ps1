param(
	[string]$ZipPath,

	[int]$TimeoutSeconds = 15,

	[switch]$KeepExtracted,

	[switch]$EnableDebug,

	[string[]]$ClientArgs,

	[switch]$FailOnTimeout
)

$ErrorActionPreference = 'Stop'

function Get-DefaultZipPath {
	$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
	return Join-Path $repoRoot 'adventure-ots/aac-frontend/public/downloads/windows/adventure-ots-client-windows.zip'
}

function Show-OtclientLog {
	param(
		[string]$RootPath
	)

	if ([string]::IsNullOrWhiteSpace($RootPath)) {
		return ''
	}

	$logPath = Join-Path $RootPath 'otclient.log'
	if (-not (Test-Path -LiteralPath $logPath)) {
		return ''
	}

	$logContent = Get-Content -LiteralPath $logPath -Raw
	if ($logContent) {
		Write-Host "---- otclient.log ----" -ForegroundColor Cyan
		Write-Host $logContent
	}

	return $logContent
}

if ([string]::IsNullOrWhiteSpace($ZipPath)) {
	$ZipPath = Get-DefaultZipPath
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
	throw "Client archive not found at '$ZipPath'."
}

if ($TimeoutSeconds -le 0) {
	throw "TimeoutSeconds must be greater than zero."
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("otclient-test-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

Write-Host "Extracting '$ZipPath' to '$tempRoot'..."
Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempRoot

$exePath = Join-Path $tempRoot 'otclient.exe'
if (-not (Test-Path -LiteralPath $exePath)) {
	$exePath = Get-ChildItem -LiteralPath $tempRoot -Filter 'otclient.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $exePath) {
		if (-not $KeepExtracted) {
			Remove-Item -LiteralPath $tempRoot -Recurse -Force
		}
		throw "Unable to locate otclient.exe inside extracted archive."
	}
	$exePath = $exePath.FullName
}

Write-Host "Launching '$exePath'..."
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $exePath
$processInfo.WorkingDirectory = (Split-Path -Parent $exePath)
$processInfo.UseShellExecute = $false

$argumentList = @()
if ($ClientArgs) {
	$argumentList += $ClientArgs
}
if ($EnableDebug) {
	if ($argumentList -notcontains '--debug' -and $argumentList -notcontains '-debug') {
		$argumentList += '--debug'
	}
}
if ($argumentList.Count -gt 0) {
	$processInfo.Arguments = [string]::Join(' ', $argumentList)
}

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo

$cleanupTemp = {
	param($pathToRemove)
	if ([string]::IsNullOrEmpty($pathToRemove)) {
		return
	}
	if (Test-Path -LiteralPath $pathToRemove) {
		Remove-Item -LiteralPath $pathToRemove -Recurse -Force
	}
}

$process.Start() | Out-Null

$hasExited = $process.WaitForExit($TimeoutSeconds * 1000)
if (-not $hasExited) {
	$process.Kill()
	$process.WaitForExit()
	$logDump = Show-OtclientLog -RootPath $tempRoot
	if (-not $KeepExtracted) {
		& $cleanupTemp $tempRoot
	}
	$process.Dispose()
	if ($FailOnTimeout) {
		throw "otclient.exe timed out after $TimeoutSeconds seconds." + $(if ($logDump) { " LOG: $logDump" } else { '' })
	}
	Write-Warning "otclient.exe was still running after $TimeoutSeconds seconds."
	Write-Host "Process stayed alive for the full timeout; treating as success." -ForegroundColor Green
	return
}

$exitCode = $process.ExitCode
$process.Dispose()

$logDumpOnExit = Show-OtclientLog -RootPath $tempRoot

if (-not $KeepExtracted) {
	& $cleanupTemp $tempRoot
}

if ($exitCode -ne 0) {
	$logNote = ''
	if ($logDumpOnExit) {
		$logNote = " LOG: $logDumpOnExit"
	}
	throw "otclient.exe exited with code $exitCode.$logNote"
}

Write-Host "otclient.exe finished successfully." -ForegroundColor Green

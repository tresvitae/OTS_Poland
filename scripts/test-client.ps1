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
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true

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
$process.EnableRaisingEvents = $true

$stdOutLines = New-Object System.Collections.Generic.List[string]
$stdErrLines = New-Object System.Collections.Generic.List[string]

$stdoutHandler = [System.Diagnostics.DataReceivedEventHandler]{
	param($sender, $args)
	if ($args.Data) {
		$stdOutLines.Add($args.Data)
		Write-Host "[STDOUT] $($args.Data)"
	}
}

$stderrHandler = [System.Diagnostics.DataReceivedEventHandler]{
	param($sender, $args)
	if ($args.Data) {
		$stdErrLines.Add($args.Data)
		Write-Warning "[STDERR] $($args.Data)"
	}
}

$process.add_OutputDataReceived($stdoutHandler)
$process.add_ErrorDataReceived($stderrHandler)

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
$process.BeginOutputReadLine()
$process.BeginErrorReadLine()

$hasExited = $process.WaitForExit($TimeoutSeconds * 1000)
if (-not $hasExited) {
	$process.Kill()
	$process.WaitForExit()
	$stdErr = [string]::Join([System.Environment]::NewLine, $stdErrLines.ToArray())
	if (-not $KeepExtracted) {
		& $cleanupTemp $tempRoot
	}
	$process.remove_OutputDataReceived($stdoutHandler)
	$process.remove_ErrorDataReceived($stderrHandler)
	$process.Dispose()
	if ($FailOnTimeout) {
		throw "otclient.exe timed out after $TimeoutSeconds seconds. STDERR: $stdErr"
	}
	Write-Warning "otclient.exe was still running after $TimeoutSeconds seconds. Captured STDERR (if any) shown below."
	if ($stdErr) {
		Write-Warning $stdErr
	}
	else {
		Write-Host "No STDERR captured." -ForegroundColor Yellow
	}
	Write-Host "Process stayed alive for the full timeout; treating as success." -ForegroundColor Green
	return
}

$exitCode = $process.ExitCode

$process.remove_OutputDataReceived($stdoutHandler)
$process.remove_ErrorDataReceived($stderrHandler)
$process.Dispose()

$stdOut = [string]::Join([System.Environment]::NewLine, $stdOutLines.ToArray())
$stdErrFinal = [string]::Join([System.Environment]::NewLine, $stdErrLines.ToArray())

if (-not $KeepExtracted) {
	& $cleanupTemp $tempRoot
}

if ($exitCode -ne 0) {
	throw "otclient.exe exited with code $exitCode. STDERR: $stdErrFinal"
}

Write-Host "otclient.exe finished successfully." -ForegroundColor Green
if ($stdOut) {
	Write-Host "STDOUT:`n$stdOut"
}
if ($stdErrFinal) {
	Write-Warning "STDERR:`n$stdErrFinal"
}

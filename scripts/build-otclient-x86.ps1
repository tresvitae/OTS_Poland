$ErrorActionPreference = 'Stop'

$env:VCPKG_ROOT = 'C:\msys64\home\Admin\vcpkg'
$env:VCPKG_CMAKE_OPTIONS = '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'
$env:VCPKG_CMAKE_CONFIGURE_OPTIONS = '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'

$vcVarsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat'
$clientDir = 'C:\Users\Admin\OTS_Poland\adventure-ots\client'
$buildOutputDir = Join-Path $clientDir 'build\windows-x86-release'
$runtimeStagingDir = Join-Path $buildOutputDir 'package-runtime'
$downloadsDir = 'C:\Users\Admin\OTS_Poland\adventure-ots\aac-frontend\public\downloads\windows'
$packageName = 'adventure-ots-client-windows.zip'
$targetZip = Join-Path $downloadsDir $packageName

$cmakeConfigure = 'cmake -S . -B build\windows-x86-release -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBRARY=ON -DOPTIONS_ENABLE_SCCACHE=OFF -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x86-windows-static -DVCPKG_HOST_TRIPLET=x86-windows-static'
$cmakeBuild = 'cmake --build build\windows-x86-release -j4'

$cmd = 'call "{0}" x86 && cd /d "{1}" && {2} && {3}' -f $vcVarsPath, $clientDir, $cmakeConfigure, $cmakeBuild
cmd.exe /c $cmd

if ($LASTEXITCODE -ne 0) {
	throw "Windows client build failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path $buildOutputDir)) {
	throw "Expected build output directory '$buildOutputDir' was not created"
}

$executable = Get-ChildItem -Path $buildOutputDir -Filter 'otclient.exe' -Recurse | Select-Object -First 1

if (-not $executable) {
	throw "Unable to locate otclient.exe under '$buildOutputDir'"
}

if (Test-Path $runtimeStagingDir) {
	Remove-Item -Path $runtimeStagingDir -Recurse -Force
}

New-Item -ItemType Directory -Path $runtimeStagingDir | Out-Null

$runtimeDirectories = @('data', 'mods', 'modules', 'records')
foreach ($dir in $runtimeDirectories) {
	$sourceDir = Join-Path $clientDir $dir
	if (Test-Path $sourceDir) {
		Copy-Item -Path $sourceDir -Destination (Join-Path $runtimeStagingDir $dir) -Recurse -Force
	}
}

$runtimeFiles = @('init.lua', 'meta.lua', 'config.ini', 'otclientrc.lua', 'cacert.pem')
foreach ($file in $runtimeFiles) {
	$sourceFile = Join-Path $clientDir $file
	if (Test-Path $sourceFile) {
		Copy-Item -Path $sourceFile -Destination (Join-Path $runtimeStagingDir $file) -Force
	}
}

Copy-Item -Path $executable.FullName -Destination (Join-Path $runtimeStagingDir 'otclient.exe') -Force

if (-not (Test-Path $downloadsDir)) {
	New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
}

if (Test-Path $targetZip) {
	Remove-Item -Path $targetZip -Force
}

$itemsToArchive = Get-ChildItem -Path $runtimeStagingDir
Compress-Archive -Path $itemsToArchive -DestinationPath $targetZip -Force

Write-Host "Packaged Windows client -> $targetZip"

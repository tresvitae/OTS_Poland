$ErrorActionPreference = 'Stop'

$env:VCPKG_ROOT = 'C:\msys64\home\Admin\vcpkg'
$env:VCPKG_CMAKE_OPTIONS = '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'
$env:VCPKG_CMAKE_CONFIGURE_OPTIONS = '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'

$vcVarsPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat'
$clientDir = 'C:\Users\Admin\OTS_Poland\adventure-ots\client'

$cmakeConfigure = 'cmake -S . -B build\windows-x86-release -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBRARY=ON -DOPTIONS_ENABLE_SCCACHE=OFF -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x86-windows-static -DVCPKG_HOST_TRIPLET=x86-windows-static'
$cmakeBuild = 'cmake --build build\windows-x86-release -j4'

$cmd = 'call "{0}" x86 && cd /d "{1}" && {2} && {3}' -f $vcVarsPath, $clientDir, $cmakeConfigure, $cmakeBuild
cmd.exe /c $cmd

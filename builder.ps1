# Android Template Builder
# Android Studio and necessary SDK components must be installed
# Java JDK must be installed

# Globals
$UserDirectoryAndroid = "C:\Users\" + $env:UserName
$BaseDirAndroid = Get-Location | Select-Object -ExpandProperty Path

# Check installed directories
function check_android_installation {
    if (-not (Test-Path -Path "$UserDirectoryAndroid\AppData\Local\Android\Sdk\platform-tools")){
        Write-Output "Android Platform Tools is not installed. Please follow the installation instructions."
        break
    }
    if (-not (Test-Path -Path "$UserDirectoryAndroid\AppData\Local\Android\Sdk\emulator")){
        Write-Output "Android Emulator is not installed. Please follow the installation instructions."
        break
    }
    if (-not (Test-Path -Path "$UserDirectoryAndroid\AppData\Local\Android\Sdk\cmdline-tools\latest\bin")){
        Write-Output "Android Command Line Tools is not installed. Please follow the installation instructions."
    }
}

# Builds the Android Emulator
function build_android_emulator {
    Set-Location "$UserDirectoryAndroid\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\"
    .\avdmanager.bat create avd --force --name Android_Template --abi google_apis/x86 --package 'system-images;android-28;google_apis;x86' --device 'Nexus 6P'
}

# Runs the Emulator on a different process
function run_android_emulator {
    Start-Job -ScriptBlock {
        Set-Location "$($args[0])\AppData\Local\Android\Sdk\emulator"
        .\emulator.exe -avd Android_Template -writable-system | Out-Null
    } -ArgumentList $UserDirectoryAndroid
}

# Checks if the Emulator is up and running
function check_android_emulator_status {

    $valueAndroid = 0
    $boolAndroid = $false

    Set-Location "$UserDirectoryAndroid\AppData\Local\Android\Sdk\platform-tools"

    while ($valueAndroid -ne 10){
        Write-Host "Checking device status... $valueAndroid"
        $statusAndroid = .\adb.exe devices | Select-Object -Skip 1
        if ($statusAndroid -like "*device*"){
            $boolAndroid = $true
            $valueAndroid = 10   
        }
        else {
            $valueAndroid++
            Start-Sleep -Seconds 30
        }
    }
    return $boolAndroid
}

# Setup Emulator
function setup_android_emulator {
    # Check if Emulator is running
    $install_cert_procAndroid = check_android_emulator_status
    if ($install_cert_procAndroid -eq $true){
        # Install Certificate
        Set-Location "$UserDirectoryAndroid\AppData\Local\Android\Sdk\platform-tools"
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe remount

        if (check_android_emulator_status){
            .\adb.exe push "$BaseDirAndroid\9a5ba575.0" /system/etc/security/cacerts
            .\adb.exe shell chmod 644 /system/etc/security/cacerts/9a5ba575.0
			Start-Sleep -Seconds 15
            .\adb.exe shell reboot -p
            Write-Host "Rebooting phone..."
        }
        else {
            Write-Host "Failed to remount device."
        }
    }
    else {
        Write-Output "Unable to connect to emulator."
        break
    }
    # Wait for Clean Shutdown
    Start-Sleep -Seconds 30
    
    # Boot Writeable Disk
    run_android_emulator

    $install_gsuite_procAndroid = check_android_emulator_status
    if ($install_gsuite_procAndroid -eq $true){
        # Install GSuite
        Set-Location "$UserDirectoryAndroid\AppData\Local\Android\Sdk\platform-tools"
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe root
        Start-Sleep -Seconds 5
        .\adb.exe remount

        if (check_android_emulator_status){
            .\adb.exe push "$BaseDirAndroid\gplay\app" /system
            .\adb.exe push "$BaseDirAndroid\gplay\priv-app" /system
            .\adb.exe push "$BaseDirAndroid\gplay\etc" /system
            .\adb.exe push "$BaseDirAndroid\gplay\framework" /system
            .\adb.exe shell reboot -p
        }
        else {
            Write-Host "Failed to remount device."
        }
    }
    else {
        Write-Output "Unable to connect to emulator."
        break
    }
}

# MAIN
check_android_installation
build_android_emulator
run_android_emulator
setup_android_emulator

# Wait for Clean Shutdown
Start-Sleep -Seconds 25

# Boot Finished Device
run_android_emulator

Write-Host "Build is complete."

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Runtime.WindowsRuntime

$radio = [Windows.Devices.Radios.Radio,Windows.Devices.Radios,ContentType=WindowsRuntime]
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1
} | Select-Object -First 1

function Read-Result($operation, [type] $resultType) {
    $task = $asTask.MakeGenericMethod($resultType).Invoke($null, @($operation))
    if (!$task.Wait(2000)) { throw 'Windows radio query timed out.' }
    $task.Result
}

function Get-RadioState($kind) {
    if ($null -eq $radios) { return 'unknown' }
    $matchingRadios = @($radios | Where-Object Kind -eq $kind)
    if (!$matchingRadios.Count) { return 'unavailable' }
    if ($matchingRadios.State -contains 'On') { return 'on' }
    if ($matchingRadios.State -contains 'Off' -or $matchingRadios.State -contains 'Disabled') { return 'off' }
    return 'unknown'
}

$radios = $null
try {
    $radios = @(Read-Result ($radio::GetRadiosAsync()) ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]]))
} catch {}

$wifi = @{ state = Get-RadioState 'WiFi'; name = ''; signalStrength = -1 }
try {
    $network = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]
    $profile = $network::GetConnectionProfiles() | Where-Object {
        $_.IsWlanConnectionProfile -and $_.GetNetworkConnectivityLevel() -ne 'None'
    } | Sort-Object { [int] $_.GetNetworkConnectivityLevel() } -Descending | Select-Object -First 1
    if ($profile) {
        $wifi.state = 'connected'
        $wifi.name = $profile.ProfileName
        $bars = $profile.GetSignalBars()
        if ($null -ne $bars) { $wifi.signalStrength = $bars / 5 }
    }
} catch {}

$bluetooth = @{ state = Get-RadioState 'Bluetooth'; devices = $null }
if ($bluetooth.state -eq 'on') {
    $deviceInfo = [Windows.Devices.Enumeration.DeviceInformation,Windows.Devices.Enumeration,ContentType=WindowsRuntime]
    $collection = [Windows.Devices.Enumeration.DeviceInformationCollection,Windows.Devices.Enumeration,ContentType=WindowsRuntime]
    $kind = [Windows.Devices.Enumeration.DeviceInformationKind,Windows.Devices.Enumeration,ContentType=WindowsRuntime]
    $classic = [Windows.Devices.Bluetooth.BluetoothDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime]
    $lowEnergy = [Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime]
    $connected = 'System.Devices.Aep.IsConnected'
    $container = 'System.Devices.Aep.ContainerId'
    try {
        $devices = @(foreach ($type in $classic, $lowEnergy) {
            $selector = $type::GetDeviceSelectorFromPairingState($true)
            Read-Result ($deviceInfo::FindAllAsync($selector, [string[]]@($connected, $container), $kind::AssociationEndpoint)) $collection
        })
        $bluetooth.devices = @($devices | Where-Object Name | Group-Object {
            if ($_.Properties[$container]) { $_.Properties[$container] } else { $_.Id }
        } | ForEach-Object {
            @{
                name = $_.Group[0].Name
                connected = @($_.Group | Where-Object { $_.Properties[$connected] -eq $true }).Count -gt 0
            }
        } | Sort-Object { $_.connected } -Descending)
    } catch {}
}

@{ wifi = $wifi; bluetooth = $bluetooth } | ConvertTo-Json -Compress -Depth 4

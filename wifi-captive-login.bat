@echo off
setlocal

:: Wi-Fi 網卡名稱；若名稱不同，請修改這一行
set "WIFI_ADAPTER_NAME=Wi-Fi"

:: 確認是否具有系統管理員權限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell.exe -NoProfile -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Setting up Wi-Fi DNS and scheduled restore...

:: 將 PowerShell 程式從此 bat 檔中讀出並執行
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$content = Get-Content -LiteralPath '%~f0' -Raw; " ^
    "$script = $content -split '(?m)^:POWERSHELL_SCRIPT\r?$', 2; " ^
    "if ($script.Count -ne 2) { Write-Error 'Script marker not found.'; exit 1 }; " ^
    "Invoke-Expression $script[1]"

if %errorlevel% neq 0 (
    echo.
    echo Failed. Please check the error message above.
    pause
    exit /b 1
)

echo.
pause
exit /b 0

:POWERSHELL_SCRIPT
$ErrorActionPreference = 'Stop'

$adapterName = $env:WIFI_ADAPTER_NAME
$taskName = 'RestoreWiFiDns'
$portalUrl = 'http://www.msftconnecttest.com/redirect'

try {
    # 取得 Wi-Fi 網卡
    $adapter = Get-NetAdapter -Name $adapterName -ErrorAction Stop
    $adapterGuid = $adapter.InterfaceGuid.ToString()

    # 排程將執行的 PowerShell 程式
    $restoreScript = @"
`$ErrorActionPreference = 'Stop'

try {
    `$adapter = Get-NetAdapter |
        Where-Object { `$_.InterfaceGuid.ToString() -eq '$adapterGuid' } |
        Select-Object -First 1

    if (-not `$adapter) {
        throw 'The original Wi-Fi adapter was not found.'
    }

    Set-DnsClientServerAddress ``
        -InterfaceIndex `$adapter.ifIndex ``
        -ServerAddresses '8.8.8.8', '8.8.4.4'

    Clear-DnsClientCache -ErrorAction SilentlyContinue

    # 成功後移除排程
    Unregister-ScheduledTask ``
        -TaskName '$taskName' ``
        -Confirm:`$false
}
catch {
    Write-Error `$_
    exit 1
}
"@

    $encodedScript = [Convert]::ToBase64String(
        [Text.Encoding]::Unicode.GetBytes($restoreScript)
    )

    $powershellExe = Join-Path $env:SystemRoot `
        'System32\WindowsPowerShell\v1.0\powershell.exe'

    $action = New-ScheduledTaskAction `
        -Execute $powershellExe `
        -Argument "-NoProfile -NonInteractive -EncodedCommand $encodedScript"

    $restoreTime = (Get-Date).AddMinutes(5)

    $trigger = New-ScheduledTaskTrigger `
        -Once `
        -At $restoreTime

    $taskPrincipal = New-ScheduledTaskPrincipal `
        -UserId 'SYSTEM' `
        -LogonType ServiceAccount `
        -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries

    # 先建立排程；若建立失敗，不會變更 DNS
    # 重複執行時，覆蓋舊排程並重新計算五分鐘
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $taskPrincipal `
        -Settings $settings `
        -Force | Out-Null

    try {
        # 將 DNS 設為自動取得
        Set-DnsClientServerAddress `
            -InterfaceIndex $adapter.ifIndex `
            -ResetServerAddresses
    }
    catch {
        Unregister-ScheduledTask `
            -TaskName $taskName `
            -Confirm:$false `
            -ErrorAction SilentlyContinue

        throw
    }

    Clear-DnsClientCache -ErrorAction SilentlyContinue

    Write-Host "Adapter: $($adapter.Name)"
    Write-Host 'DNS is now set to automatic.'
    Write-Host "Google DNS will be restored at $restoreTime."

    # 開啟網路登入偵測網址
    Start-Process $portalUrl
}
catch {
    Write-Error "Failed: $_"
    exit 1
}
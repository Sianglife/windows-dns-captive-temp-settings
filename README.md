# Wi-Fi Captive Portal DNS Switcher

Temporarily set your Wi-Fi adapter to obtain DNS automatically, open the Windows captive portal detection URL, and schedule Google Public DNS to be configured five minutes later.

## Features

1. Requests administrator privileges.
2. Creates a scheduled task to configure DNS after five minutes.
3. Sets the selected Wi-Fi adapter to obtain DNS automatically and clears the DNS cache.
4. Opens `http://www.msftconnecttest.com/redirect` in the default browser so the network can redirect to its login page.
5. Sets IPv4 DNS to `8.8.8.8` and `8.8.4.4` after five minutes, then removes the task if it succeeds.

## Requirements

- Windows with Windows PowerShell, networking management, and Task Scheduler components.
- An account that can grant administrator privileges.
- A connection to the Wi-Fi network that requires authentication.

## Usage

1. Save the batch script as `wifi-captive-login.bat`.
2. Double-click the file and approve the administrator privilege prompt.
3. Follow the network provider's instructions in the browser to sign in.
4. Five minutes later, the scheduled task will configure Google Public DNS. You may close the command window while waiting.

> Whether a login page appears depends on the network configuration. If it does not appear, check your Wi-Fi connection or use the login URL provided by the network operator.

## Configure the Wi-Fi Adapter Name

The default adapter name is `Wi-Fi`. If yours is different, open the BAT file in a text editor and change this line near the top:

```bat
set "WIFI_ADAPTER_NAME=Wi-Fi"
```

To find the adapter name, run the following command in PowerShell and check the `Name` column:

```powershell
Get-NetAdapter | Format-Table Name, Status, InterfaceDescription
```

For example, if the adapter is named `Wi-Fi 2`, use:

```bat
set "WIFI_ADAPTER_NAME=Wi-Fi 2"
```

## Scheduled Task and Notes

- The scheduled task is named `RestoreWiFiDns` and runs as `SYSTEM`. It deletes itself after successfully setting DNS. If it fails, it remains available for inspection in Windows Task Scheduler.
- Running the BAT file again replaces the existing task and restarts the five-minute countdown.
- If the computer is shut down or asleep when the task is due, the task can run when it becomes available again.
- The script sets the specified Google IPv4 DNS addresses; it **does not save or restore your previous DNS settings**. Resetting DNS to automatic may affect both IPv4 and IPv6, while the scheduled task configures only IPv4 DNS.
- If DNS was set to automatic but the scheduled task failed, open PowerShell as administrator and configure it manually. Change `Wi-Fi` to your adapter name if needed:

```powershell
Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses '8.8.8.8', '8.8.4.4'
```

- To cancel the scheduled task manually, run the following in an administrator PowerShell window. Removing the task does not change the current DNS settings:

```powershell
Unregister-ScheduledTask -TaskName 'RestoreWiFiDns' -Confirm:$false
```

# Wi-Fi Captive Portal DNS 切換工具

在需要網頁認證的 Wi-Fi 網路中，暫時將網卡的 DNS 設為自動取得，開啟網路登入偵測頁面，並在五分鐘後將 IPv4 DNS 設為 Google Public DNS。

## 功能

1. 要求系統管理員權限。
2. 建立五分鐘後執行的 DNS 還原排程。
3. 將指定 Wi-Fi 網卡的 DNS 設為自動取得，並清除 DNS 快取。
4. 在預設瀏覽器開啟 `http://www.msftconnecttest.com/redirect`，供網路重新導向至登入頁面。
5. 時間到後，將 IPv4 DNS 設為 `8.8.8.8` 和 `8.8.4.4`；成功後移除排程。

## 使用需求

- Windows 電腦，以及系統內建的 Windows PowerShell、網路管理與工作排程元件。
- 可授予系統管理員權限的帳號。
- 已連線至需要登入的 Wi-Fi 網路。

## 使用方式

1. 將 `wifi-captive-login.bat` 儲存至電腦。
2. 雙擊執行，並在系統提示時允許系統管理員權限。
3. 瀏覽器開啟後，依網路提供者的指示完成登入。
4. 五分鐘後，排程會將 DNS 設為 Google Public DNS；執行期間可關閉命令視窗。

> 網路是否會顯示登入頁面，取決於該網路的設定。若未顯示，請檢查 Wi-Fi 連線，或使用網路提供者指定的登入網址。

## 設定 Wi-Fi 網卡名稱

預設網卡名稱為 `Wi-Fi`。如果電腦使用其他名稱，請以文字編輯器開啟 BAT 檔，修改開頭的設定：

```bat
set "WIFI_ADAPTER_NAME=Wi-Fi"
```

可以在 PowerShell 中執行以下指令，查看網卡的 `Name` 欄位：

```powershell
Get-NetAdapter | Format-Table Name, Status, InterfaceDescription
```

例如網卡名稱為 `Wi-Fi 2`，就改為：

```bat
set "WIFI_ADAPTER_NAME=Wi-Fi 2"
```

## 排程與注意事項

- 排程名稱為 `RestoreWiFiDns`，以 `SYSTEM` 身分執行。成功設定 DNS 後會自動刪除；失敗時會保留，可在 Windows「工作排程器」中查看執行結果。
- 再次執行 BAT 會覆蓋同名排程，並重新計算五分鐘。
- 如果到期時電腦關機或睡眠，排程會在之後可執行時補跑。
- 腳本會將 DNS 設為指定的 Google IPv4 DNS，**不會記錄或還原執行前原本的 DNS**。自動取得的設定可能同時影響 IPv4 與 IPv6；排程只指定 IPv4 DNS。
- 若 DNS 已改為自動，但排程還原失敗，可以管理員身分開啟 PowerShell，手動設定（請依實際網卡名稱修改）：

```powershell
Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses '8.8.8.8', '8.8.4.4'
```

- 手動取消排程可在管理員 PowerShell 中執行以下指令；取消排程不會自動變更目前的 DNS：

```powershell
Unregister-ScheduledTask -TaskName 'RestoreWiFiDns' -Confirm:$false
```

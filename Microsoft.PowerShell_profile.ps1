# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 3.7.0
function simple {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$SimpleArgs
    )

    if ($null -eq $global:SimpleServers) {
        $global:SimpleServers = @{}
    }
    $profilePath = $PROFILE
    $repository = "kennymonster454/simple"
    $updateUrl = "https://raw.githubusercontent.com/$repository/main/Microsoft.PowerShell_profile.ps1"

    # SIMPLE .smp script runner (Windows PowerShell 5.1).
    # .spe files continue to the SPE game runner below.
    if ($SimpleArgs.Count -ge 2 -and $SimpleArgs[0].ToLowerInvariant() -eq "run") {
        $scriptPath = ($SimpleArgs[1..($SimpleArgs.Count - 1)] -join " ").Trim().Trim('"')
        $scriptExtension = [IO.Path]::GetExtension($scriptPath).ToLowerInvariant()
        if ($scriptExtension -eq ".smp") {
            if (!(Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
                Write-Host "SMP file not found: $scriptPath"
                return
            }
            try {
                foreach ($scriptLine in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $scriptPath).Path)) {
                    $trimmedLine = $scriptLine.Trim()
                    if ($trimmedLine -and !$trimmedLine.StartsWith("#")) {
                        Write-Host ("> " + $trimmedLine) -ForegroundColor DarkGray
                        simple $trimmedLine
                    }
                }
            } catch {
                Write-Host "Could not run SMP file: $($_.Exception.Message)"
            }
            return
        }
    }

    # Correct only command words at the start; never rewrite paths, names, or say-text.
    if ($SimpleArgs.Count -gt 0 -and $SimpleArgs[0] -notmatch '^(?i)say$') {
        $fixes = @{
            "shwo"="show"; "sho"="show"; "opn"="open"; "opne"="open";
            "flies"="files"; "fiels"="files"; "drivs"="drives";
            "foldrs"="folders"; "folers"="folders"; "progams"="programs";
            "calclator"="calculator"; "calculater"="calculator";
            "notpad"="notepad"; "creat"="create"; "foler"="folder";
            "tim"="time"; "comand"="command"; "comands"="commands"
        }
        $firstWord = $SimpleArgs[0].ToLowerInvariant()
        if ($fixes.ContainsKey($firstWord)) {
            $SimpleArgs[0] = $fixes[$firstWord]
            Write-Host ("SIMPLE spelling fix: " + $firstWord + " -> " + $SimpleArgs[0]) -ForegroundColor Yellow
        }
        if ($SimpleArgs.Count -gt 1 -and $SimpleArgs[0].ToLowerInvariant() -in @("show","open","go","create")) {
            $secondWord = $SimpleArgs[1].ToLowerInvariant()
            if ($fixes.ContainsKey($secondWord)) {
                $SimpleArgs[1] = $fixes[$secondWord]
                Write-Host ("SIMPLE spelling fix: " + $secondWord + " -> " + $SimpleArgs[1]) -ForegroundColor Yellow
            }
            if ($SimpleArgs.Count -gt 2 -and (($SimpleArgs[0].ToLowerInvariant() -eq "show" -and $SimpleArgs[1].ToLowerInvariant() -eq "my") -or ($SimpleArgs[0].ToLowerInvariant() -eq "create" -and $SimpleArgs[1].ToLowerInvariant() -eq "a"))) {
                $thirdWord = $SimpleArgs[2].ToLowerInvariant()
                if ($fixes.ContainsKey($thirdWord)) {
                    $SimpleArgs[2] = $fixes[$thirdWord]
                    Write-Host ("SIMPLE spelling fix: " + $thirdWord + " -> " + $SimpleArgs[2]) -ForegroundColor Yellow
                }
            }
        }
    }

    $english = ($SimpleArgs -join " ").Trim()

    # Online/offline mode is a session setting. Local commands remain usable offline.
    if ($null -eq $global:SimpleOfflineMode) { $global:SimpleOfflineMode = $false }
    if ($english -match '^(?i)offline$') {
        $global:SimpleOfflineMode = $true
        Write-Host "SIMPLE is now OFFLINE." -ForegroundColor Yellow
        Write-Host "Local commands remain available. Updates are disabled until you type: simple online"
        return
    }
    if ($english -match '^(?i)online$') {
        $global:SimpleOfflineMode = $false
        Write-Host "SIMPLE is now ONLINE." -ForegroundColor Green
        Write-Host "All commands are available, including: simple update"
        return
    }

    # SPE: run .smp scripts and .spe games.
    if ($SimpleArgs.Count -ge 2 -and $SimpleArgs[0].ToLowerInvariant() -eq "run") {
        $runPath = ($SimpleArgs[1..($SimpleArgs.Count - 1)] -join " ").Trim().Trim('"')
        if (!(Test-Path -LiteralPath $runPath -PathType Leaf)) { Write-Host "File not found: $runPath"; return }
        $runExtension = [IO.Path]::GetExtension($runPath).ToLowerInvariant()
        try {
            if ($runExtension -eq ".smp") {
                foreach ($scriptLine in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $runPath).Path)) {
                    $commandLine = $scriptLine.Trim()
                    if ($commandLine -and !$commandLine.StartsWith("#")) { simple $commandLine }
                }
            } elseif ($runExtension -eq ".spe") {
                $game = Get-Content -LiteralPath $runPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if ($game.format -ne "SPE" -or [string]::IsNullOrWhiteSpace([string]$game.html)) { throw "Invalid SPE file." }
                $folder = Join-Path ([IO.Path]::GetTempPath()) "SIMPLE-SPE"
                if (!(Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
                $htmlPath = Join-Path $folder ([IO.Path]::GetFileNameWithoutExtension($runPath) + ".html")
                [IO.File]::WriteAllText($htmlPath,[string]$game.html,(New-Object System.Text.UTF8Encoding($false)))
                Write-Host ("Launching SPE game: " + $game.title)
                Start-Process -FilePath $htmlPath
            } else { Write-Host "SIMPLE runs .smp scripts and .spe games." }
        } catch { Write-Host ("Could not run file: " + $_.Exception.Message) -ForegroundColor Red }
        return
    }

    # SPE game creator: turn a plain-English prompt into a playable game.
    if ($english -match '(?i)^make (?:me )?(?:a )?(?:(2\.5d|2d)\s+)?game(?:\s+where)?\s+(.+)') {
        $requestedMode = $matches[1]
        $description = $matches[2].Trim()
        $mode = "2D"
        if (($requestedMode -and $requestedMode.ToLowerInvariant() -eq "2.5d") -or ($description -match '(?i)2\.5d|3d-looking|almost fully 3d')) { $mode = "2.5D" }
        $title = "SPE Adventure"
        if ($description -match '(?i)cat|kitten') { $title = "Cat Adventure" }
        elseif ($description -match '(?i)robot') { $title = "Robot Adventure" }
        elseif ($description -match '(?i)space|spaceship|planet|astronaut') { $title = "Space Adventure" }
        elseif ($description -match '(?i)haunted|ghost') { $title = "Haunted Adventure" }
        elseif ($description -match '(?i)dinosaur|dino') { $title = "Dinosaur Adventure" }
        elseif ($description -match '(?i)forest|woods') { $title = "Forest Adventure" }
        $titleJson = ConvertTo-Json -InputObject $title -Compress
        $modeJson = ConvertTo-Json -InputObject $mode -Compress
        $html = @'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SPE Game</title>
<style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#101827;color:white;font-family:Segoe UI,Arial}canvas{display:block;width:100%;height:100%}#hud{position:fixed;top:14px;left:14px;padding:12px 16px;background:#101827dd;border:1px solid #ffffff55;border-radius:10px}#help{position:fixed;bottom:14px;left:50%;transform:translateX(-50%);padding:9px 14px;background:#101827dd;border-radius:8px}#win{display:none;position:fixed;inset:0;align-items:center;justify-content:center;background:#07101dcc;font-size:36px;font-weight:bold}</style></head>
<body><canvas id="game"></canvas><div id="hud"><b id="title"></b><div id="mode"></div><div id="score">Stars: 0/8</div></div><div id="help">Move: WASD / arrows · Collect 8 stars</div><div id="win">YOU WIN!</div>
<script>
const TITLE=__TITLE__,MODE=__MODE__;document.title=TITLE+" - SPE";document.getElementById("title").textContent=TITLE;document.getElementById("mode").textContent=MODE+" game";
const c=document.getElementById("game"),g=c.getContext("2d");let w=0,h=0,keys={},score=0,won=false;const p={x:100,y:100};let stars=[];
function size(){w=c.width=innerWidth;h=c.height=innerHeight}addEventListener("resize",size);size();
function reset(){score=0;won=false;p.x=w/2;p.y=h/2;stars=[];for(let i=0;i<8;i++)stars.push({x:30+Math.random()*Math.max(1,w-60),y:60+Math.random()*Math.max(1,h-100),got:false})}
addEventListener("keydown",e=>{keys[e.key.toLowerCase()]=true;if(e.key.startsWith("Arrow"))e.preventDefault()});addEventListener("keyup",e=>keys[e.key.toLowerCase()]=false);
function circle(x,y,r,color){g.beginPath();g.arc(x,y,r,0,Math.PI*2);g.fillStyle=color;g.fill()}
function frame(){g.fillStyle=MODE==="2.5D"?"#24434d":"#183b2b";g.fillRect(0,0,w,h);g.strokeStyle="#ffffff18";for(let x=0;x<w;x+=50){g.beginPath();g.moveTo(x,0);g.lineTo(x,h);g.stroke()}for(let y=0;y<h;y+=50){g.beginPath();g.moveTo(0,y);g.lineTo(w,y);g.stroke()}
if(!won){let dx=(keys.d||keys.arrowright?1:0)-(keys.a||keys.arrowleft?1:0),dy=(keys.s||keys.arrowdown?1:0)-(keys.w||keys.arrowup?1:0),m=Math.hypot(dx,dy)||1;p.x=Math.max(12,Math.min(w-12,p.x+dx/m*3));p.y=Math.max(12,Math.min(h-12,p.y+dy/m*3));stars.forEach(s=>{if(!s.got&&Math.hypot(s.x-p.x,s.y-p.y)<20){s.got=true;score++;document.getElementById("score").textContent="Stars: "+score+"/8";if(score===8){won=true;document.getElementById("win").style.display="flex"}}})}
stars.forEach(s=>{if(!s.got)circle(s.x,s.y,8,"#ffe58a")});circle(p.x,p.y+4,14,"#0008");circle(p.x,p.y,12,"#54d9e8");circle(p.x,p.y-3,5,"#e5fbff");requestAnimationFrame(frame)}
reset();requestAnimationFrame(frame);
</script></body></html>
'@
        $html = $html.Replace("__TITLE__", $titleJson).Replace("__MODE__", $modeJson)
        $safeTitle = $title -replace '[\\/:*?"<>|]', ''
        $path = Join-Path (Get-Location).Path ($safeTitle + ".spe")
        $number = 2
        while (Test-Path -LiteralPath $path) { $path = Join-Path (Get-Location).Path ($safeTitle + "-" + $number + ".spe"); $number++ }
        $spe = [ordered]@{format="SPE";formatVersion=1;title=$title;mode=$mode;description=$description;html=$html}
        [IO.File]::WriteAllText($path,(ConvertTo-Json -InputObject $spe -Depth 5),(New-Object System.Text.UTF8Encoding($false)))
        Write-Host "SPE game created!" -ForegroundColor Green
        Write-Host ("Title: " + $title)
        Write-Host ("Mode: " + $mode)
        Write-Host ("File: " + $path)
        Write-Host ('Run it with: simple run "' + $path + '"')
        return
    }

    if ($english -match '^(?i)(help|show commands)$') {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                         SIMPLE COMMANDS 3.6.1                        ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  BASIC                                                                 ║"
        Write-Host "║  simple print <text>                                                   ║"
        Write-Host "║  simple say <text>   |   simple clear screen   |   simple what time is it"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  FILES                                                                 ║"
        Write-Host "║  simple show my files   |   simple show my folders   |   simple show my drives"
        Write-Host "║  simple show files in <drive>:   |   simple show folders in <drive>:"
        Write-Host "║  simple find a file called <name> in <drive>:"
        Write-Host "║  simple create a folder called <name> in <drive>:"
        Write-Host "║  simple open <drive>:   |   simple go to <drive>:"
        Write-Host "║  simple open in simple <text.txt>"
        Write-Host "║  simple make a game where <description>"
        Write-Host "║  simple make a 2.5d game where <description>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  SYSTEM                                                                ║"
        Write-Host "║  simple show running programs   |   simple show my computer info"
        Write-Host "║  simple show wifi status   |   simple open notepad   |   simple open calculator"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  VECTOR & WINDOWS                                                      ║"
        Write-Host "║  simple vector ip <address>"
        Write-Host "║  simple open window <HTML file path>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  LOCALHOST                                                             ║"
        Write-Host "║  simple localhost start <port>   |   simple localhost stop <port>"
        Write-Host "║  simple localhost status <port>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  UPDATES                                                               ║"
        Write-Host "║  simple offline   |   simple online                                    ║"
        Write-Host "║  simple update   |   simple update localhost <port>   |   simple update timeline"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  SCRIPTS                                                               ║"
        Write-Host "║  simple run <path to .smp file>"
        Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        return
    }
    if ($english -match '^(?i)(show my drives|show drives)$') {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name,Root,Used,Free | Format-Table -AutoSize
        return
    }
    if ($english -match '^(?i)(show my files|show files)$') {
        Get-ChildItem -LiteralPath (Get-Location).Path -Force -ErrorAction SilentlyContinue | Select-Object Mode,Length,Name | Format-Table -AutoSize
        return
    }
    if ($english -match '^(?i)show files in ([A-Za-z]:)$') {
        $driveRoot = $matches[1] + "\"
        if (Test-Path -LiteralPath $driveRoot -PathType Container) {
            Get-ChildItem -LiteralPath $driveRoot -Force -ErrorAction SilentlyContinue | Select-Object Mode,Length,Name | Format-Table -AutoSize
        } else { Write-Host "Drive unavailable: $driveRoot" }
        return
    }
    if ($english -match '^(?i)show folders in ([A-Za-z]:)$') {
        $driveRoot = $matches[1] + "\"
        if (Test-Path -LiteralPath $driveRoot -PathType Container) {
            Get-ChildItem -LiteralPath $driveRoot -Directory -Force -ErrorAction SilentlyContinue | Select-Object Name,FullName | Format-Table -AutoSize
        } else { Write-Host "Drive unavailable: $driveRoot" }
        return
    }
    if ($english -match '^(?i)(show my folders|show folders)$') {
        Get-ChildItem -LiteralPath (Get-Location).Path -Directory -Force -ErrorAction SilentlyContinue | Select-Object Name,FullName | Format-Table -AutoSize
        return
    }
    if ($english -match '^(?i)(show running programs|show my programs)$') {
        Get-Process | Sort-Object ProcessName | Select-Object ProcessName,Id | Format-Table -AutoSize
        return
    }
    if ($english -match '^(?i)open in simple (.+)$') {
        $textPath = $matches[1].Trim().Trim('"')
        if ([IO.Path]::GetExtension($textPath).ToLowerInvariant() -ne ".txt") {
            Write-Host "SIMPLE viewer opens .txt files only."
        } elseif (!(Test-Path -LiteralPath $textPath -PathType Leaf)) {
            Write-Host "Text file not found: $textPath"
        } else {
            try {
                $resolvedTextPath = (Resolve-Path -LiteralPath $textPath -ErrorAction Stop).Path
                $textContent = [IO.File]::ReadAllText($resolvedTextPath)
                Write-Host ""
                Write-Host ("--- " + [IO.Path]::GetFileName($resolvedTextPath) + " ---")
                if ([string]::IsNullOrEmpty($textContent)) { Write-Host "(This file is empty.)" }
                else { Write-Host $textContent }
                Write-Host ("--- End of file ---")
            } catch { Write-Host "Could not open text file: $($_.Exception.Message)" }
        }
        return
    }
    if ($english -match '^(?i)open ([A-Za-z]:)$') {
        $driveRoot = $matches[1] + "\"
        if (Test-Path -LiteralPath $driveRoot -PathType Container) { Start-Process -FilePath explorer.exe -ArgumentList $driveRoot }
        else { Write-Host "Drive unavailable: $driveRoot" }
        return
    }
    if ($english -match '^(?i)go to ([A-Za-z]:)$') {
        $driveRoot = $matches[1] + "\"
        if (Test-Path -LiteralPath $driveRoot -PathType Container) {
            Set-Location -LiteralPath $driveRoot
            Write-Host ("Current folder: " + (Get-Location).Path)
        } else { Write-Host "Drive unavailable: $driveRoot" }
        return
    }
    if ($english -match '^(?i)create a folder called (.+?)(?: in ([A-Za-z]:))?$') {
        $folderName = $matches[1].Trim().Trim('"')
        $targetRoot = if ($matches[2]) { $matches[2] + "\" } else { (Get-Location).Path }
        if ([string]::IsNullOrWhiteSpace($folderName) -or $folderName -match '[\\/:*?"<>|]') {
            Write-Host "Invalid folder name."
        } elseif (!(Test-Path -LiteralPath $targetRoot -PathType Container)) {
            Write-Host "Location unavailable: $targetRoot"
        } else {
            $targetPath = Join-Path -Path $targetRoot -ChildPath $folderName
            if (Test-Path -LiteralPath $targetPath) { Write-Host "Already exists: $targetPath" }
            else {
                try {
                    New-Item -ItemType Directory -Path $targetPath -ErrorAction Stop | Out-Null
                    Write-Host "Created: $targetPath"
                } catch { Write-Host "Could not create folder: $($_.Exception.Message)" }
            }
        }
        return
    }
    if ($english -match '^(?i)find a file called (.+?) in ([A-Za-z]:)$') {
        $fileName = $matches[1].Trim().Trim('"')
        $searchRoot = $matches[2] + "\"
        if (!(Test-Path -LiteralPath $searchRoot -PathType Container)) { Write-Host "Drive unavailable: $searchRoot" }
        elseif ([string]::IsNullOrWhiteSpace($fileName) -or $fileName -match '[\\/:*?"<>|]') { Write-Host "Invalid file name." }
        else {
            Get-ChildItem -LiteralPath $searchRoot -File -Filter $fileName -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 100 FullName
        }
        return
    }
    if ($english -match '^(?i)open notepad$') { Start-Process -FilePath notepad.exe; return }
    if ($english -match '^(?i)open calculator$') { Start-Process -FilePath calc.exe; return }
    if ($english -match '^(?i)(what time is it|show the time)$') { Get-Date; return }
    if ($english -match '^(?i)show my computer info$') {
        try { Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,OSArchitecture | Format-List } catch { Write-Host "Could not read Windows information." }
        try { Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores | Format-List } catch { Write-Host "Could not read processor information." }
        return
    }
    if ($english -match '^(?i)show wifi status$') {
        if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
            Get-NetAdapter | Where-Object { $_.Name -match "Wi-?Fi|Wireless" } | Select-Object Name,Status,LinkSpeed | Format-Table -AutoSize
        } else { netsh wlan show interfaces }
        return
    }
    if ($english -match '^(?i)say (.*)$') { Write-Host $matches[1]; return }
    if ($english -match '^(?i)clear screen$') { Clear-Host; return }
    if (!$SimpleArgs) {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                         SIMPLE COMMANDS 3.5.5                        ║" -ForegroundColor Cyan
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  BASIC                                                                 ║"
        Write-Host "║  simple print <text>                                                   ║"
        Write-Host "║  simple say <text>   |   simple clear screen   |   simple what time is it"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  FILES                                                                 ║"
        Write-Host "║  simple show my files   |   simple show my folders   |   simple show my drives"
        Write-Host "║  simple show files in <drive>:   |   simple show folders in <drive>:"
        Write-Host "║  simple find a file called <name> in <drive>:"
        Write-Host "║  simple create a folder called <name> in <drive>:"
        Write-Host "║  simple open <drive>:   |   simple go to <drive>:"
        Write-Host "║  simple open in simple <text.txt>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  SYSTEM                                                                ║"
        Write-Host "║  simple show running programs   |   simple show my computer info"
        Write-Host "║  simple show wifi status   |   simple open notepad   |   simple open calculator"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  VECTOR & WINDOWS                                                      ║"
        Write-Host "║  simple vector ip <address>"
        Write-Host "║  simple open window <HTML file path>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  LOCALHOST                                                             ║"
        Write-Host "║  simple localhost start <port>   |   simple localhost stop <port>"
        Write-Host "║  simple localhost status <port>"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  UPDATES                                                               ║"
        Write-Host "║  simple update   |   simple update localhost <port>   |   simple update timeline"
        Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "║  SCRIPTS                                                               ║"
        Write-Host "║  simple run <path to .smp file>"
        Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        return
    }

    switch ($SimpleArgs[0].ToLower()) {

        "print" {
            if ($SimpleArgs.Count -gt 1) {
                $SimpleArgs[1..($SimpleArgs.Count - 1)] -join " "
            }
        }

        "vector" {
            if ($SimpleArgs.Count -ge 3 -and $SimpleArgs[1] -eq "ip") {
                $global:SimpleVectorIP = $SimpleArgs[2]
                Write-Host "Vector IP: $global:SimpleVectorIP"
            }
            else {
                Write-Host "Usage: simple vector ip <address>"
            }
        }

        "open" {
            if ($SimpleArgs.Count -lt 3 -or $SimpleArgs[1].ToLower() -ne "window") {
                Write-Host "Usage: simple open window <HTML file path or localhost URL>"
                return
            }

            $windowTarget = ($SimpleArgs[2..($SimpleArgs.Count - 1)] -join " ").Trim().Trim('"')
            $navigateTarget = $null
            $targetUri = $null

            if ([Uri]::TryCreate($windowTarget, [UriKind]::Absolute, [ref]$targetUri) -and $targetUri.Scheme -match '^https?$') {
                if ($targetUri.IsLoopback) {
                    $navigateTarget = $targetUri.AbsoluteUri
                } else {
                    Write-Host "SIMPLE windows only open local files or localhost addresses."
                    return
                }
            } else {
                if (!(Test-Path -LiteralPath $windowTarget -PathType Leaf)) {
                    Write-Host "HTML file not found: $windowTarget"
                    return
                }
                $resolvedPath = (Resolve-Path -LiteralPath $windowTarget).Path
                if ([IO.Path]::GetExtension($resolvedPath).ToLower() -notin @(".html", ".htm")) {
                    Write-Host "Please select an .html or .htm file."
                    return
                }
                $navigateTarget = ([Uri]$resolvedPath).AbsoluteUri
            }

            try {
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                Add-Type -AssemblyName System.Drawing -ErrorAction Stop
                [System.Windows.Forms.Application]::EnableVisualStyles()
                $window = New-Object System.Windows.Forms.Form
                $window.Text = "SIMPLE - Localhost"
                $window.StartPosition = "CenterScreen"
                $window.Size = New-Object System.Drawing.Size(1100, 760)
                $window.MinimumSize = New-Object System.Drawing.Size(500, 350)
                $viewer = New-Object System.Windows.Forms.WebBrowser
                $viewer.Dock = [System.Windows.Forms.DockStyle]::Fill
                $viewer.ScriptErrorsSuppressed = $true
                $viewer.IsWebBrowserContextMenuEnabled = $true
                $viewer.WebBrowserShortcutsEnabled = $true
                $window.Controls.Add($viewer)
                # Navigate after the form is shown so the WebBrowser control has a valid window handle.
                $window.Add_Shown({ $viewer.Navigate($navigateTarget) })
                [void]$window.ShowDialog()
                $window.Dispose()
                $viewer.Dispose()
            } catch {
                Write-Host "Could not open the SIMPLE window: $($_.Exception.Message)"
            }
        }

        "update" {
            if ($global:SimpleOfflineMode) {
                Write-Host "SIMPLE is OFFLINE. The update command is unavailable in offline mode." -ForegroundColor Yellow
                Write-Host "Connect to the internet, then type: simple online"
                return
            }
            if ($SimpleArgs.Count -ge 2 -and $SimpleArgs[1].ToLower() -eq "timeline") {
                Write-Host "Loading SIMPLE version timeline..."
                try {
                    $historyUrl = "https://api.github.com/repos/kennymonster454/simple/commits?path=Microsoft.PowerShell_profile.ps1&per_page=100"
                    $history = Invoke-RestMethod -Uri $historyUrl -Headers @{
                        "User-Agent" = "SIMPLE-Updater"
                        "Accept" = "application/vnd.github+json"
                    } -ErrorAction Stop

                    if (!$history -or $history.Count -eq 0) {
                        throw "GitHub returned no version history."
                    }

                    $choices = @()
                    foreach ($entry in $history) {
                        if (!$entry.sha) { continue }
                        $shortSha = ([string]$entry.sha).Substring(0, 7)
                        $message = [string]$entry.commit.message
                        $message = ($message -split "`n", 2)[0]
                        $date = ([DateTime]$entry.commit.author.date).ToLocalTime().ToString("yyyy-MM-dd HH:mm")
                        $choices += [PSCustomObject]@{
                            Sha = [string]$entry.sha
                            ShortSha = $shortSha
                            Message = $message
                            Date = $date
                        }
                    }

                    Write-Host ""
                    Write-Host "SIMPLE VERSION TIMELINE"
                    for ($i = 0; $i -lt $choices.Count; $i++) {
                        Write-Host ("[{0}] {1} | {2} | {3}" -f ($i + 1), $choices[$i].Date, $choices[$i].ShortSha, $choices[$i].Message)
                    }
                    Write-Host "[0] Cancel"
                    $selection = Read-Host "Choose a version"

                    if ($selection -eq "100") {
                        Write-Host ""
                        Write-Host "SIMPLE HAS A SURPRISE FOR YOU..." -ForegroundColor Red
                        Start-Sleep -Milliseconds 500
                        Clear-Host

                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
                            [System.Windows.Forms.Application]::EnableVisualStyles()

                            # Read filenames only from common folders. No file contents are opened or uploaded.
                            $fileNames = @()
                            $scanFolders = @(
                                [Environment]::GetFolderPath("Desktop"),
                                [Environment]::GetFolderPath("MyDocuments"),
                                (Join-Path $env:USERPROFILE "Downloads"),
                                [Environment]::GetFolderPath("MyPictures"),
                                [Environment]::GetFolderPath("MyVideos")
                            ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } | Select-Object -Unique

                            foreach ($folder in $scanFolders) {
                                try {
                                    $remaining = 300 - $fileNames.Count
                                    if ($remaining -le 0) { break }
                                    $found = Get-ChildItem -LiteralPath $folder -File -Recurse -Force -ErrorAction SilentlyContinue |
                                        Select-Object -First $remaining
                                    foreach ($item in $found) {
                                        $fileNames += $item.Name
                                        if ($fileNames.Count -ge 300) { break }
                                    }
                                } catch {}
                                if ($fileNames.Count -ge 300) { break }
                            }

                            if ($fileNames.Count -eq 0) {
                                $fileNames = @("NO_FILES_FOUND.txt", "SIMPLE_SCAN.log", "SYSTEM_REPORT.dat")
                            }

                            $prankForms = New-Object System.Collections.ArrayList
                            $prankState = [hashtable]::Synchronized(@{ Closing = $false; Forms = $null })
                            $prankState.Forms = $prankForms
                            $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

                            # 100 separate warning windows; each displays a real filename.
                            for ($p = 0; $p -lt 100; $p++) {
                                $popup = New-Object System.Windows.Forms.Form
                                $popup.Text = "SIMPLE DATABASE TRANSFER"
                                $popup.StartPosition = "Manual"
                                $popup.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
                                $popup.Size = New-Object System.Drawing.Size(300, 145)
                                $popup.MaximizeBox = $false
                                $popup.MinimizeBox = $false
                                $popup.TopMost = $true
                                $popup.BackColor = [System.Drawing.Color]::Black

                                $message = New-Object System.Windows.Forms.Label
                                $message.Dock = [System.Windows.Forms.DockStyle]::Fill
                                $message.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                                $message.ForeColor = [System.Drawing.Color]::Lime
                                $message.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
                                $fileName = [string]$fileNames[$p % $fileNames.Count]
                                $message.Text = "FILE DETECTED:" + [Environment]::NewLine + $fileName + [Environment]::NewLine + [Environment]::NewLine + "SENDING TO SIMPLE DATABASE..."
                                $popup.Controls.Add($message)

                                $x = $screen.Left + (($p * 37) % [Math]::Max(1, ($screen.Width - 300)))
                                $y = $screen.Top + (($p * 53) % [Math]::Max(1, ($screen.Height - 145)))
                                $popup.Location = New-Object System.Drawing.Point($x, $y)
                                [void]$prankForms.Add($popup)
                            }

                            foreach ($popup in $prankForms) {
                                $popup.Add_FormClosed({
                                    if (!$prankState.Closing) {
                                        $prankState.Closing = $true
                                        foreach ($other in @($prankState.Forms)) {
                                            if (!$other.IsDisposed -and $other -ne $this) {
                                                $other.Close()
                                            }
                                        }

                                        # The HELP scene is visual only and uses filenames, never file contents.
                                        $flood = New-Object System.Windows.Forms.Form
                                        $flood.Text = "SIMPLE"
                                        $flood.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
                                        $flood.StartPosition = "Manual"
                                        $flood.Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
                                        $flood.TopMost = $true
                                        $flood.BackColor = [System.Drawing.Color]::Black
                                        $flood.Show()

                                        $headline = New-Object System.Windows.Forms.Label
                                        $headline.Text = "HELP! HELP! HELP!  SIMPLE IS LOSING CONTROL!"
                                        $headline.ForeColor = [System.Drawing.Color]::Red
                                        $headline.BackColor = [System.Drawing.Color]::Black
                                        $headline.Font = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
                                        $headline.AutoSize = $true
                                        $headline.Location = New-Object System.Drawing.Point(20, 15)
                                        $flood.Controls.Add($headline)

                                        $random = New-Object System.Random
                                        $sprites = New-Object System.Collections.ArrayList
                                        $spriteCount = [Math]::Min(180, [Math]::Max(100, $fileNames.Count))
                                        for ($i = 0; $i -lt $spriteCount; $i++) {
                                            $sprite = New-Object System.Windows.Forms.Label
                                            $sprite.AutoSize = $true
                                            $sprite.BackColor = [System.Drawing.Color]::Transparent
                                            $sprite.ForeColor = [System.Drawing.Color]::FromArgb($random.Next(100, 256), $random.Next(100, 256), $random.Next(100, 256))
                                            $sprite.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
                                            $sprite.Text = "FILE: " + [string]$fileNames[$i % $fileNames.Count]
                                            $sprite.Tag = [PSCustomObject]@{ VX = $random.Next(-8, 9); VY = $random.Next(-8, 9) }
                                            if ($sprite.Tag.VX -eq 0) { $sprite.Tag.VX = 3 }
                                            if ($sprite.Tag.VY -eq 0) { $sprite.Tag.VY = 2 }
                                            $sprite.Location = New-Object System.Drawing.Point(
                                                $random.Next(0, [Math]::Max(1, $flood.ClientSize.Width - 180)),
                                                $random.Next(70, [Math]::Max(71, $flood.ClientSize.Height - 30))
                                            )
                                            $flood.Controls.Add($sprite)
                                            [void]$sprites.Add($sprite)
                                        }

                                        $timer = New-Object System.Windows.Forms.Timer
                                        $timer.Interval = 25
                                        $timer.Add_Tick({
                                            foreach ($sprite in $sprites) {
                                                if ($sprite.IsDisposed) { continue }
                                                $vx = [int]$sprite.Tag.VX
                                                $vy = [int]$sprite.Tag.VY
                                                $nx = $sprite.Left + $vx
                                                $ny = $sprite.Top + $vy
                                                $maxX = [Math]::Max(0, $flood.ClientSize.Width - $sprite.Width)
                                                $maxY = [Math]::Max(70, $flood.ClientSize.Height - $sprite.Height)
                                                if ($nx -le 0 -or $nx -ge $maxX) { $vx = -$vx; $nx = [Math]::Max(0, [Math]::Min($maxX, $nx)) }
                                                if ($ny -le 65 -or $ny -ge $maxY) { $vy = -$vy; $ny = [Math]::Max(65, [Math]::Min($maxY, $ny)) }
                                                $sprite.Tag.VX = $vx
                                                $sprite.Tag.VY = $vy
                                                $sprite.Location = New-Object System.Drawing.Point($nx, $ny)
                                            }
                                        })
                                        $flood.Add_FormClosed({ $timer.Stop(); $timer.Dispose() })
                                        $timer.Start()

                                        try {
                                            for ($beep = 0; $beep -lt 5; $beep++) { [Console]::Beep(900, 120) }
                                        } catch {}
                                        [void]$flood.ShowDialog()
                                        $timer.Stop()
                                        $timer.Dispose()
                                        $flood.Dispose()
                                    }
                                })
                                $popup.Show()
                            }

                            while (@($prankForms | Where-Object { !$_.IsDisposed }).Count -gt 0) {
                                [System.Windows.Forms.Application]::DoEvents()
                                Start-Sleep -Milliseconds 20
                            }
                            foreach ($popup in $prankForms) {
                                if (!$popup.IsDisposed) { $popup.Dispose() }
                            }
                        }
                        catch {
                            Write-Host "SIMPLE effect failed: $($_.Exception.Message)" -ForegroundColor Red
                        }
                        Write-Host "SIMPLE TIMELINE COMPLETE."
                        return
                    }
                    if ($selection -eq "0" -or [string]::IsNullOrWhiteSpace($selection)) {
                        Write-Host "Cancelled."
                        return
                    }

                    $number = 0
                    if (![int]::TryParse($selection, [ref]$number) -or $number -lt 1 -or $number -gt $choices.Count) {
                        throw "That is not a valid timeline number."
                    }

                    $chosen = $choices[$number - 1]
                    $historicalUrl = "https://raw.githubusercontent.com/kennymonster454/simple/$($chosen.Sha)/Microsoft.PowerShell_profile.ps1"
                    $historicalResponse = Invoke-WebRequest -Uri $historicalUrl -UseBasicParsing -ErrorAction Stop
                    $historicalCode = [string]$historicalResponse.Content

                    if ([string]::IsNullOrWhiteSpace($historicalCode) -or
                        $historicalCode -notmatch '(?m)^#\s*VERSION\s+\S+' -or
                        $historicalCode -notmatch '(?im)^function\s+simple\b') {
                        throw "That commit is not a SIMPLE profile."
                    }

                    $tokens = $null
                    $parseErrors = $null
                    [void][System.Management.Automation.Language.Parser]::ParseInput($historicalCode, [ref]$tokens, [ref]$parseErrors)
                    if ($parseErrors.Count -gt 0) {
                        throw "That saved version has a PowerShell syntax error: $($parseErrors[0].Message)"
                    }

                    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $timelineBackup = "$profilePath.timeline-$stamp.backup"
                    $timelineTemp = "$profilePath.timeline-$stamp.tmp"
                    Copy-Item -LiteralPath $profilePath -Destination $timelineBackup -Force -ErrorAction Stop
                    [System.IO.File]::WriteAllText($timelineTemp, $historicalCode, (New-Object System.Text.UTF8Encoding($true)))

                    try {
                        [System.IO.File]::Copy($timelineTemp, $profilePath, $true)
                        . $profilePath
                    }
                    catch {
                        [System.IO.File]::Copy($timelineBackup, $profilePath, $true)
                        throw
                    }
                    finally {
                        Remove-Item -LiteralPath $timelineTemp -Force -ErrorAction SilentlyContinue
                    }

                    Write-Host "Restored SIMPLE version $($chosen.ShortSha)."
                    Write-Host "Backup: $timelineBackup"
                    Write-Host "Use 'simple update' to return to the latest version."
                }
                catch {
                    Write-Host "Timeline failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                return
            }

            $startLocalhost = $false
            $startPort = 0

            if ($SimpleArgs.Count -ge 3 -and $SimpleArgs[1].ToLower() -eq "localhost") {
                if (![int]::TryParse($SimpleArgs[2], [ref]$startPort) -or $startPort -lt 1 -or $startPort -gt 65535) {
                    Write-Host "Usage: simple update localhost <port>"
                    return
                }
                $startLocalhost = $true
            }

            Write-Host "Checking for Simple updates..."

            $tempPath = "$profilePath.simple-update.tmp"
            $updateSucceeded = $false

            try {
                # Fetch the current main-branch file through GitHub's Contents API.
                # This avoids stale raw.githubusercontent.com cache responses.
                $apiUrl = "https://api.github.com/repos/$repository/contents/Microsoft.PowerShell_profile.ps1?ref=main"
                $apiResponse = Invoke-RestMethod -Uri $apiUrl -Headers @{
                    "User-Agent" = "SIMPLE-Updater"
                    "Accept" = "application/vnd.github+json"
                    "Cache-Control" = "no-cache"
                } -ErrorAction Stop

                if (!$apiResponse.content -or $apiResponse.encoding -ne "base64") {
                    throw "GitHub did not return the profile as base64 content."
                }
                $encodedContent = ([string]$apiResponse.content) -replace '\s', ''
                $newCode = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedContent))
                if ([string]::IsNullOrWhiteSpace($newCode)) {
                    throw "GitHub returned an empty file."
                }

                # Check that the download is actually a SIMPLE profile.
                if ($newCode -notmatch '(?m)^#\s*VERSION\s+\S+' -or $newCode -notmatch '(?im)^function\s+simple\b') {
                    throw "The downloaded file is not a valid SIMPLE profile."
                }

                $onlineMatch = [regex]::Match($newCode, '(?m)^#\s*VERSION\s+(.+?)\s*$')
                $onlineVersion = $onlineMatch.Groups[1].Value.Trim()

                # Parse the entire download before touching the installed profile.
                $tokens = $null
                $parseErrors = $null
                [void][System.Management.Automation.Language.Parser]::ParseInput($newCode, [ref]$tokens, [ref]$parseErrors)
                if ($parseErrors.Count -gt 0) {
                    throw "The GitHub profile has a PowerShell syntax error: $($parseErrors[0].Message)"
                }

                if (!(Test-Path -LiteralPath $profilePath -PathType Leaf)) {
                    throw "The installed PowerShell profile was not found: $profilePath"
                }

                $installedCode = [System.IO.File]::ReadAllText($profilePath)
                $installedMatch = [regex]::Match($installedCode, '(?m)^#\s*VERSION\s+(.+?)\s*$')
                $installedVersion = if ($installedMatch.Success) { $installedMatch.Groups[1].Value.Trim() } else { "unknown" }

                # Compare the complete contents, not just the version label.
                $installedCompare = $installedCode.Replace("`r`n", "`n").TrimEnd()
                $downloadCompare = $newCode.Replace("`r`n", "`n").TrimEnd()

                if ($installedCompare -ceq $downloadCompare) {
                    Write-Host "Simple $installedVersion is already up to date."
                    $updateSucceeded = $true
                }
                else {
                    # Write and verify a temporary copy first.
                    [System.IO.File]::WriteAllText($tempPath, $newCode, (New-Object System.Text.UTF8Encoding($true)))
                    $tempCode = [System.IO.File]::ReadAllText($tempPath)
                    if ($tempCode.Replace("`r`n", "`n").TrimEnd() -cne $downloadCompare) {
                        throw "The temporary update file did not pass verification."
                    }

                    $tempTokens = $null
                    $tempErrors = $null
                    [void][System.Management.Automation.Language.Parser]::ParseInput($tempCode, [ref]$tempTokens, [ref]$tempErrors)
                    if ($tempErrors.Count -gt 0) {
                        throw "The temporary update file failed its syntax check."
                    }

                    # Delete the old profile, then move the verified new profile into its place.
                    Remove-Item -LiteralPath $profilePath -Force -ErrorAction Stop
                    Move-Item -LiteralPath $tempPath -Destination $profilePath -ErrorAction Stop

                    # Confirm the installed file matches the downloaded file.
                    $finalCode = [System.IO.File]::ReadAllText($profilePath)
                    if ($finalCode.Replace("`r`n", "`n").TrimEnd() -cne $downloadCompare) {
                        throw "The installed profile did not match the verified download."
                    }

                    Write-Host "Simple updated from $installedVersion to $onlineVersion!"
                    $updateSucceeded = $true
                }

                # Reload the profile in this function scope, then promote the new
                # SIMPLE function into global scope so it survives this call.
                . $profilePath
                $reloadedSimple = Get-Item -Path Function:\simple -ErrorAction Stop
                Set-Item -Path Function:\global:simple -Value $reloadedSimple.ScriptBlock -ErrorAction Stop
            }
            catch {
                Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Your previous profile was kept."
            }
            finally {
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            }

            if ($updateSucceeded -and $startLocalhost) {
                simple localhost start $startPort
            }
        }
        "localhost" {
            if ($SimpleArgs.Count -lt 3) {
                Write-Host "Usage: simple localhost start/stop/status <port>"
                return
            }

            $action = $SimpleArgs[1].ToLower()
            $port = 0
            if (![int]::TryParse($SimpleArgs[2], [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
                Write-Host "Invalid port."
                return
            }

            if ($action -eq "start") {
                Write-Host ""
                Write-Host "Do you want to add an HTML file or keep the default?"
                Write-Host "Type 1 for HTML"
                Write-Host "Type 2 for default"
                $choice = Read-Host "SIMPLE"

                if ($choice -eq "1") {
                    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                    $dialog = New-Object System.Windows.Forms.OpenFileDialog
                    $dialog.Filter = "HTML files (*.html;*.htm)|*.html;*.htm"
                    $dialog.Title = "Select HTML file"
                    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                        Write-Host "Selection cancelled."
                        return
                    }
                    $localHtmlPath = $dialog.FileName
                }
                elseif ($choice -eq "2") {
                    $localFolder = Join-Path $env:LOCALAPPDATA "Simple\Localhost"
                    New-Item -ItemType Directory -Path $localFolder -Force -ErrorAction Stop | Out-Null
                    $localHtmlPath = Join-Path $localFolder "index.html"
                    $defaultHtml = @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIMPLE</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#071b12;color:#eaffef;font-family:Segoe UI,Arial,sans-serif;line-height:1.55}
.top{background:linear-gradient(135deg,#087a3d,#16a34a);padding:34px 26px 30px;border-bottom:4px solid #5ee58b}
.wrap{max-width:980px;margin:0 auto;padding:26px 22px}
.brand{font-size:38px;font-weight:800;letter-spacing:2px;margin:0;color:white}
.tag{margin:5px 0 0;color:#d8ffe4;font-size:16px}
h2{color:#86efac;margin:0 0 14px;font-size:22px}
.panel{background:#102b1d;border:1px solid #236b43;border-radius:12px;padding:20px;margin:0 0 20px}
.grid{display:flex;flex-wrap:wrap;gap:12px}
.item{flex:1 1 260px;background:#0a2116;border:1px solid #205b39;border-radius:9px;padding:13px}
code{color:#a7f3c0;background:#153c27;padding:3px 6px;border-radius:5px;font-family:Consolas,monospace}
p{margin:7px 0;color:#d5eadd}
.foot{color:#8db69a;font-size:13px;text-align:center;padding:8px}
</style>
</head>
<body>
<header class="top"><div class="wrap"><h1 class="brand">SIMPLE</h1><p class="tag">Your local SIMPLE command center</p></div></header>
<main class="wrap">
<section class="panel"><h2>Welcome</h2><p>SIMPLE is a small command language created by Kenny. This page is stored and opened directly on your PC.</p><p><strong style="color:#86efac">Local window: running</strong></p></section>
<section class="panel"><h2>Commands</h2><div class="grid">
<div class="item"><code>simple print &lt;text&gt;</code><p>Prints text in PowerShell.</p></div>
<div class="item"><code>simple vector ip &lt;address&gt;</code><p>Stores your Vector's IP address.</p></div>
<div class="item"><code>simple open window &lt;HTML path&gt;</code><p>Opens a local HTML page in a SIMPLE desktop window.</p></div>
<div class="item"><code>simple localhost start &lt;port&gt;</code><p>Opens this local page in a desktop window. No web server or internet is used.</p></div>
<div class="item"><code>simple offline</code><p>Switches SIMPLE to offline mode. Local commands keep working.</p></div>
<div class="item"><code>simple online</code><p>Restores internet-dependent commands such as updates.</p></div>
<div class="item"><code>simple update</code><p>Checks GitHub and updates SIMPLE. Internet required.</p></div>
</div></section>
<section class="panel"><h2>SIMPLE Updates</h2><p>To view the version history, run <code>simple update timeline</code> in PowerShell while online.</p></section>
<div class="foot">SIMPLE &bull; Local desktop interface &bull; Runs directly from your PC</div>
</main>
</body>
</html>
'@
                    [System.IO.File]::WriteAllText($localHtmlPath, $defaultHtml, [System.Text.UTF8Encoding]::new($false))
                }
                else {
                    Write-Host "Invalid choice."
                    return
                }

                if (!(Test-Path -LiteralPath $localHtmlPath -PathType Leaf)) {
                    Write-Host "HTML file not found: $localHtmlPath"
                    return
                }

                Write-Host "Opening SIMPLE's local desktop window..."
                Write-Host "No localhost server is started. No internet is required."
                simple open window $localHtmlPath
            }
            elseif ($action -eq "stop") {
                Write-Host "SIMPLE localhost is a local desktop window, not a server."
                Write-Host "Close the SIMPLE window to finish it."
            }
            elseif ($action -eq "status") {
                Write-Host "SIMPLE localhost uses a local HTML file and desktop window."
                Write-Host "No TCP server or internet connection is used."
            }
            else {
                Write-Host "Unknown localhost command."
            }
        }

        default {
            Write-Host "Unknown command: $($SimpleArgs[0])"
        }
    }
}

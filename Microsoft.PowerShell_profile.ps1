# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 3.5
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

    # SIMPLE English interpreter and .smp script runner (Windows PowerShell 5.1).
    if ($SimpleArgs.Count -ge 2 -and $SimpleArgs[0].ToLowerInvariant() -eq "run") {
        $scriptPath = ($SimpleArgs[1..($SimpleArgs.Count - 1)] -join " ").Trim().Trim('"')
        if ([IO.Path]::GetExtension($scriptPath).ToLowerInvariant() -ne ".smp" -or !(Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            Write-Host "SMP file not found or not a .smp file."
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
    if ($english -match '^(?i)(help|show commands)$') {
        Write-Host "SIMPLE ENGLISH COMMANDS"
        Write-Host "show my files | show my folders | show my drives"
        Write-Host "show files in D: | show folders in C: | show running programs"
        Write-Host "open C: | go to D: | open notepad | open calculator"
        Write-Host "create a folder called Games in D: | what time is it"
        Write-Host "find a file called test.txt in F:"
        Write-Host "show my computer info | show wifi status | say hello | clear screen"
        Write-Host "simple run C:\path\script.smp"
        Write-Host "Existing: simple print, vector ip, open window, localhost, update, update timeline"
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
        Write-Host "SIMPLE COMMANDS"
        Write-Host "simple print <text>"
        Write-Host "simple vector ip <address>"
        Write-Host "simple open window <HTML file path>"
        Write-Host "simple localhost start <port>"
        Write-Host "simple localhost stop <port>"
        Write-Host "simple localhost status <port>"
        Write-Host "simple update"
        Write-Host "simple update localhost <port>"
        Write-Host "simple update timeline"
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
                Write-Host "Usage: simple open window <HTML file path>"
                return
            }

            $htmlPath = ($SimpleArgs[2..($SimpleArgs.Count - 1)] -join " ").Trim('"')

            if (!(Test-Path -LiteralPath $htmlPath -PathType Leaf)) {
                Write-Host "HTML file not found: $htmlPath"
                return
            }

            $resolvedPath = (Resolve-Path -LiteralPath $htmlPath).Path
            if ([IO.Path]::GetExtension($resolvedPath).ToLower() -notin @(".html", ".htm")) {
                Write-Host "Please select an .html or .htm file."
                return
            }

            try {
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                Add-Type -AssemblyName System.Drawing -ErrorAction Stop

                [System.Windows.Forms.Application]::EnableVisualStyles()

                $window = New-Object System.Windows.Forms.Form
                $window.Text = "Simple Window"
                $window.StartPosition = "CenterScreen"
                $window.Size = New-Object System.Drawing.Size(1000, 700)
                $window.MinimumSize = New-Object System.Drawing.Size(400, 300)

                $viewer = New-Object System.Windows.Forms.WebBrowser
                $viewer.Dock = [System.Windows.Forms.DockStyle]::Fill
                $viewer.ScriptErrorsSuppressed = $true
                $viewer.IsWebBrowserContextMenuEnabled = $true
                $viewer.WebBrowserShortcutsEnabled = $true
                $window.Controls.Add($viewer)

                $viewer.Navigate(([Uri]$resolvedPath).AbsoluteUri)
                [void]$window.ShowDialog()
                $window.Dispose()
                $viewer.Dispose()
            }
            catch {
                Write-Host "Could not open the Simple window: $($_.Exception.Message)"
            }
        }

        "update" {
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

                    . $profilePath
                    Write-Host "Simple updated from $installedVersion to $onlineVersion!"
                    $updateSucceeded = $true
                }
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

            if (![int]::TryParse($SimpleArgs[2], [ref]$port) -or
                $port -lt 1 -or $port -gt 65535) {
                Write-Host "Invalid port."
                return
            }

            if ($action -eq "start") {
                if ($global:SimpleServers.ContainsKey($port)) {
                    $existing = $global:SimpleServers[$port]
                    if (!$existing.HasExited) {
                        Write-Host "Simple localhost is already running on port $port."
                        return
                    }
                    $global:SimpleServers.Remove($port)
                }

                $test = [System.Net.Sockets.TcpClient]::new()
                $occupied = $false
                try {
                    $test.Connect("127.0.0.1", $port)
                    $occupied = $true
                }
                catch {}
                finally {
                    $test.Dispose()
                }

                if ($occupied) {
                    Write-Host "Port $port is already in use."
                    return
                }

                Write-Host ""
                Write-Host "Do you want to add an HTML file or keep the default?"
                Write-Host "Type 1 for HTML"
                Write-Host "Type 2 for default"
                $choice = Read-Host "SIMPLE"
                $htmlPath = "-"

                if ($choice -eq "1") {
                    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                    $dialog = New-Object System.Windows.Forms.OpenFileDialog
                    $dialog.Filter = "HTML files (*.html;*.htm)|*.html;*.htm"
                    $dialog.Title = "Select HTML file"
                    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                        Write-Host "Selection cancelled."
                        return
                    }
                    $htmlPath = $dialog.FileName
                }
                elseif ($choice -ne "2") {
                    Write-Host "Invalid choice."
                    return
                }

                # Run the server in an in-process PowerShell runspace; loopback only.
                $logDirectory = Join-Path $env:LOCALAPPDATA "Simple\Logs"
                New-Item -ItemType Directory -Path $logDirectory -Force -ErrorAction Stop | Out-Null
                $logPath = Join-Path $logDirectory ("localhost-{0}.log" -f $port)
                $state = [hashtable]::Synchronized(@{ StopRequested = $false; Listener = $null })
                Add-Content -LiteralPath $logPath -Value ("[{0}] START REQUESTED 127.0.0.1:{1}" -f (Get-Date -Format o), $port)
                $serverCode = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('JEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICJTdG9wIgokbGlzdGVuZXIgPSAkbnVsbAp0cnkgewogICAgJGxpc3RlbmVyID0gW1N5c3RlbS5OZXQuU29ja2V0cy5UY3BMaXN0ZW5lcl06Om5ldyhbU3lzdGVtLk5ldC5JUEFkZHJlc3NdOjpMb29wYmFjaywgJFBvcnQpCiAgICAkbGlzdGVuZXIuU3RhcnQoKQoKICAgIHdoaWxlICgkdHJ1ZSkgewogICAgICAgICRjbGllbnQgPSAkbGlzdGVuZXIuQWNjZXB0VGNwQ2xpZW50KCkKICAgICAgICAkcmVhZGVyID0gJG51bGwKICAgICAgICB0cnkgewogICAgICAgICAgICAkc3RyZWFtID0gJGNsaWVudC5HZXRTdHJlYW0oKQogICAgICAgICAgICAkcmVhZGVyID0gW1N5c3RlbS5JTy5TdHJlYW1SZWFkZXJdOjpuZXcoJHN0cmVhbSwgW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6QVNDSUksICRmYWxzZSwgMTAyNCwgJHRydWUpCiAgICAgICAgICAgICRyZXF1ZXN0TGluZSA9ICRyZWFkZXIuUmVhZExpbmUoKQoKICAgICAgICAgICAgaWYgKCRudWxsIC1uZSAkcmVxdWVzdExpbmUpIHsKICAgICAgICAgICAgICAgIHdoaWxlICgkdHJ1ZSkgewogICAgICAgICAgICAgICAgICAgICRoZWFkZXJMaW5lID0gJHJlYWRlci5SZWFkTGluZSgpCiAgICAgICAgICAgICAgICAgICAgaWYgKCRudWxsIC1lcSAkaGVhZGVyTGluZSAtb3IgJGhlYWRlckxpbmUgLWVxICIiKSB7IGJyZWFrIH0KICAgICAgICAgICAgICAgIH0KCiAgICAgICAgICAgICAgICBpZiAoJEh0bWxQYXRoIC1uZSAiLSIgLWFuZCAoVGVzdC1QYXRoIC1MaXRlcmFsUGF0aCAkSHRtbFBhdGggLVBhdGhUeXBlIExlYWYpKSB7CiAgICAgICAgICAgICAgICAgICAgJGJvZHkgPSBbU3lzdGVtLklPLkZpbGVdOjpSZWFkQWxsVGV4dCgkSHRtbFBhdGgpCiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICBlbHNlIHsKICAgICAgICAgICAgICAgICAgICAkYm9keSA9IEAiCjwhRE9DVFlQRSBodG1sPgo8aHRtbCBsYW5nPSJlbiI+CjxoZWFkPgo8bWV0YSBjaGFyc2V0PSJVVEYtOCI+CjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MSI+Cjx0aXRsZT5TaW1wbGUgRG9jdW1lbnRhdGlvbjwvdGl0bGU+CjxzdHlsZT4KYm9keSB7IGZvbnQtZmFtaWx5OiBTZWdvZSBVSSwgQXJpYWwsIHNhbnMtc2VyaWY7IG1heC13aWR0aDogODUwcHg7IG1hcmdpbjogNDhweCBhdXRvOyBwYWRkaW5nOiAwIDIycHg7IGxpbmUtaGVpZ2h0OiAxLjY7IGNvbG9yOiAjMjAyMTI0OyB9CmgxIHsgbWFyZ2luLWJvdHRvbTogNHB4OyB9IC5zdWIgeyBjb2xvcjogIzY2NjsgbWFyZ2luLXRvcDogMDsgfQpjb2RlIHsgYmFja2dyb3VuZDogI2YxZjNmNDsgcGFkZGluZzogM3B4IDZweDsgYm9yZGVyLXJhZGl1czogNHB4OyB9CnNlY3Rpb24geyBtYXJnaW4tdG9wOiAyOHB4OyB9ICN1cGRhdGVzIHsgcGFkZGluZzogMTJweCAxNnB4OyBiYWNrZ3JvdW5kOiAjZjRmNmY4OyBib3JkZXItcmFkaXVzOiA4cHg7IH0KPC9zdHlsZT4KPC9oZWFkPgo8Ym9keT4KPGgxPlNpbXBsZSBEb2N1bWVudGF0aW9uPC9oMT4KPHAgY2xhc3M9InN1YiI+QSBzbWFsbCBjb21tYW5kIGxhbmd1YWdlIGNyZWF0ZWQgYnkgS2VubnkuPC9wPgo8c2VjdGlvbj4KPGgyPkNvbW1hbmRzPC9oMj4KPHA+PGNvZGU+c2ltcGxlIHByaW50ICZsdDt0ZXh0Jmd0OzwvY29kZT4g4oCUIHByaW50cyB0ZXh0LjwvcD4KPHA+PGNvZGU+c2ltcGxlIHZlY3RvciBpcCAmbHQ7YWRkcmVzcyZndDs8L2NvZGU+IOKAlCBzdG9yZXMgdGhlIFZlY3RvciBJUCBhZGRyZXNzLjwvcD4KPHA+PGNvZGU+c2ltcGxlIG9wZW4gd2luZG93ICZsdDtIVE1MIGZpbGUgcGF0aCZndDs8L2NvZGU+IOKAlCBvcGVucyBhbiBIVE1MIGZpbGUgaW4gYSBTaW1wbGUgd2luZG93LjwvcD4KPHA+PGNvZGU+c2ltcGxlIGxvY2FsaG9zdCBzdGFydCAmbHQ7cG9ydCZndDs8L2NvZGU+IOKAlCBzdGFydHMgdGhpcyBsb2NhbGhvc3Qgc2VydmVyLjwvcD4KPHA+PGNvZGU+c2ltcGxlIGxvY2FsaG9zdCBzdG9wICZsdDtwb3J0Jmd0OzwvY29kZT4g4oCUIHN0b3BzIGEgbG9jYWxob3N0IHNlcnZlci48L3A+CjxwPjxjb2RlPnNpbXBsZSBsb2NhbGhvc3Qgc3RhdHVzICZsdDtwb3J0Jmd0OzwvY29kZT4g4oCUIGNoZWNrcyBhIGxvY2FsaG9zdCBzZXJ2ZXIuPC9wPgo8cD48Y29kZT5zaW1wbGUgdXBkYXRlPC9jb2RlPiDigJQgdXBkYXRlcyB0aGUgU0lNUExFIGNvbW1hbmQgc3lzdGVtLjwvcD4KPC9zZWN0aW9uPgo8c2VjdGlvbj4KPGgyPlNpbXBsZSBVcGRhdGVzPC9oMj4KPGRpdiBpZD0idXBkYXRlcyI+Q2hlY2tpbmcgZm9yIHVwZGF0ZSBpbmZvcm1hdGlvbi4uLjwvZGl2Pgo8L3NlY3Rpb24+CjxzY3JpcHQ+Cihhc3luYyBmdW5jdGlvbiAoKSB7CiAgY29uc3QgcGFuZWwgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgidXBkYXRlcyIpOwogIHRyeSB7CiAgICBjb25zdCByZXNwb25zZSA9IGF3YWl0IGZldGNoKCJodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20va2Vubnltb25zdGVyNDU0L3NpbXBsZS9tYWluL3VwZGF0ZS5qc29uIiwgeyBjYWNoZTogIm5vLXN0b3JlIiB9KTsKICAgIGlmICghcmVzcG9uc2Uub2spIHRocm93IG5ldyBFcnJvcigiTm8gdXBkYXRlIGluZm9ybWF0aW9uIGlzIHB1Ymxpc2hlZCB5ZXQuIik7CiAgICBjb25zdCBkYXRhID0gYXdhaXQgcmVzcG9uc2UuanNvbigpOwogICAgaWYgKCFkYXRhLnZlcnNpb24gfHwgIUFycmF5LmlzQXJyYXkoZGF0YS51cGRhdGVzKSkgdGhyb3cgbmV3IEVycm9yKCJUaGUgdXBkYXRlIGluZm9ybWF0aW9uIGZpbGUgaXMgaW52YWxpZC4iKTsKICAgIGNvbnN0IGhlYWRpbmcgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCJzdHJvbmciKTsKICAgIGhlYWRpbmcudGV4dENvbnRlbnQgPSAiTGF0ZXN0IFNJTVBMRSB2ZXJzaW9uOiAiICsgZGF0YS52ZXJzaW9uOwogICAgcGFuZWwucmVwbGFjZUNoaWxkcmVuKGhlYWRpbmcpOwogICAgZGF0YS51cGRhdGVzLmZvckVhY2goZnVuY3Rpb24gKGl0ZW0pIHsKICAgICAgY29uc3QgZW50cnkgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCJwIik7CiAgICAgIGVudHJ5LnRleHRDb250ZW50ID0gaXRlbS5kYXRlID8gaXRlbS5kYXRlICsgIiDigJQgIiArIGl0ZW0uaW5mbyA6IGl0ZW0uaW5mbzsKICAgICAgcGFuZWwuYXBwZW5kQ2hpbGQoZW50cnkpOwogICAgfSk7CiAgfSBjYXRjaCAoZXJyb3IpIHsKICAgIHBhbmVsLnRleHRDb250ZW50ID0gZXJyb3IubWVzc2FnZTsKICB9Cn0pKCk7Cjwvc2NyaXB0Pgo8L2JvZHk+CjwvaHRtbD4KIkAKICAgICAgICAgICAgICAgIH0KCiAgICAgICAgICAgICAgICAkYnl0ZXMgPSBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4LkdldEJ5dGVzKCRib2R5KQogICAgICAgICAgICAgICAgJGNybGYgPSBbc3RyaW5nXVtjaGFyXTEzICsgW3N0cmluZ11bY2hhcl0xMAogICAgICAgICAgICAgICAgJGhlYWRlciA9ICJIVFRQLzEuMSAyMDAgT0siICsgJGNybGYgKyAiQ29udGVudC1UeXBlOiB0ZXh0L2h0bWw7IGNoYXJzZXQ9dXRmLTgiICsgJGNybGYgKyAiQ29udGVudC1MZW5ndGg6ICQoJGJ5dGVzLkxlbmd0aCkiICsgJGNybGYgKyAiQ29ubmVjdGlvbjogY2xvc2UiICsgJGNybGYgKyAkY3JsZgogICAgICAgICAgICAgICAgJGhlYWRlckJ5dGVzID0gW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6QVNDSUkuR2V0Qnl0ZXMoJGhlYWRlcikKICAgICAgICAgICAgICAgICRzdHJlYW0uV3JpdGUoJGhlYWRlckJ5dGVzLCAwLCAkaGVhZGVyQnl0ZXMuTGVuZ3RoKQogICAgICAgICAgICAgICAgJHN0cmVhbS5Xcml0ZSgkYnl0ZXMsIDAsICRieXRlcy5MZW5ndGgpCiAgICAgICAgICAgICAgICAkc3RyZWFtLkZsdXNoKCkKICAgICAgICAgICAgfQogICAgICAgIH0KICAgICAgICBjYXRjaCB7fQogICAgICAgIGZpbmFsbHkgewogICAgICAgICAgICBpZiAoJHJlYWRlcikgeyAkcmVhZGVyLkRpc3Bvc2UoKSB9CiAgICAgICAgICAgICRjbGllbnQuQ2xvc2UoKQogICAgICAgIH0KICAgIH0KfQpjYXRjaCB7fQpmaW5hbGx5IHsKICAgIGlmICgkbGlzdGVuZXIpIHsgJGxpc3RlbmVyLlN0b3AoKSB9Cn0='))
                # Record exceptions that were previously swallowed by empty catch blocks.
                $serverCode = $serverCode.Replace('catch {}', 'catch { Add-Content -LiteralPath $LogPath -Value ("[{0}] SERVER ERROR {1}" -f (Get-Date -Format o), $_.Exception.ToString()) }')
                $serverCode = $serverCode.Replace('while ($true) {','while (!$State.StopRequested) { if (!$listener.Pending()) { Start-Sleep -Milliseconds 100; continue }')
                $serverCode = $serverCode.Replace('$listener.Start()','$listener.Start()' + [Environment]::NewLine + '$State.Listener = $listener' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] LISTENING 127.0.0.1:{1}" -f (Get-Date -Format o), $Port)')
                $serverCode = $serverCode.Replace('$client = $listener.AcceptTcpClient()','$client = $listener.AcceptTcpClient()' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] CONNECTION {1}" -f (Get-Date -Format o), $client.Client.RemoteEndPoint)')
                $serverCode = $serverCode.Replace('$requestLine = $reader.ReadLine()','$requestLine = $reader.ReadLine()' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] REQUEST {1}" -f (Get-Date -Format o), $requestLine)')
                # Port, HtmlPath, State, and LogPath are supplied directly to the runspace.
                $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
                $runspace.Open()
                $runspace.SessionStateProxy.SetVariable("Port",$port)
                $runspace.SessionStateProxy.SetVariable("HtmlPath",$htmlPath)
                $runspace.SessionStateProxy.SetVariable("State",$state)
                $runspace.SessionStateProxy.SetVariable("LogPath",$logPath)
                $powerShell = [PowerShell]::Create()
                $powerShell.Runspace = $runspace
                [void]$powerShell.AddScript($serverCode)
                try { $async = $powerShell.BeginInvoke() }
                catch {
                    $powerShell.Dispose(); $runspace.Dispose()
                    Add-Content -LiteralPath $logPath -Value ("[{0}] START ERROR {1}" -f (Get-Date -Format o), $_.Exception.Message)
                    Write-Host "Could not start localhost: $($_.Exception.Message)"
                    return
                }
                $ready=$false
                for($i=0;$i -lt 50;$i++){
                    Start-Sleep -Milliseconds 100
                    if($async.IsCompleted){break}
                    $probe=[System.Net.Sockets.TcpClient]::new()
                    try{$probe.Connect("127.0.0.1",$port);$ready=$true;break}catch{}finally{$probe.Dispose()}
                }
                if(!$ready){
                    $state.StopRequested=$true
                    if($state.Listener){try{$state.Listener.Stop()}catch{}}
                    try{$powerShell.EndInvoke($async)}catch{}
                    $powerShell.Dispose();$runspace.Dispose()
                    Add-Content -LiteralPath $logPath -Value ("[{0}] START FAILED" -f (Get-Date -Format o))
                    Write-Host "Server failed to start. Log: $logPath"
                    if(Test-Path -LiteralPath $logPath){Get-Content -LiteralPath $logPath -Tail 12}
                    return
                }
                $global:SimpleServers[$port]=@{PowerShell=$powerShell;Runspace=$runspace;Async=$async;State=$state;LogPath=$logPath}
                Write-Host "Simple localhost started!"
                Write-Host "Port: $port"
                Write-Host "Address: http://localhost:$port"
                Write-Host "Local log: $logPath"
                Add-Content -LiteralPath $logPath -Value ("[{0}] SERVER STARTED" -f (Get-Date -Format o))
                Start-Process "http://localhost:$port"
            }
            elseif ($action -eq "stop") {
                if (!$global:SimpleServers.ContainsKey($port)) {
                    Write-Host "No SIMPLE server is being tracked on port $port."
                    return
                }

                $server=$global:SimpleServers[$port]
                $server.State.StopRequested=$true
                if($server.State.Listener){try{$server.State.Listener.Stop()}catch{}}
                try{$server.PowerShell.EndInvoke($server.Async)}catch{}
                Add-Content -LiteralPath $server.LogPath -Value ("[{0}] SERVER STOPPED" -f (Get-Date -Format o))
                $server.PowerShell.Dispose();$server.Runspace.Dispose()
                $global:SimpleServers.Remove($port)
                Write-Host "Simple localhost stopped on port $port."
                Write-Host "Local log: $($server.LogPath)"
            }
            elseif ($action -eq "status") {
                if (!$global:SimpleServers.ContainsKey($port)) {
                    Write-Host "Simple localhost is NOT running on port $port."
                    return
                }

                $server=$global:SimpleServers[$port]
                if($server.Async.IsCompleted){
                    try{$server.PowerShell.EndInvoke($server.Async)}catch{}
                    $server.PowerShell.Dispose();$server.Runspace.Dispose()
                    $global:SimpleServers.Remove($port)
                    Write-Host "Simple localhost is NOT running on port $port. Log: $($server.LogPath)"
                    return
                }
                $probe=[System.Net.Sockets.TcpClient]::new();$connected=$false
                try{$probe.Connect("127.0.0.1",$port);$connected=$true}catch{}finally{$probe.Dispose()}
                if($connected){Write-Host "Simple localhost is RUNNING!";Write-Host "http://localhost:$port"}else{Write-Host "Server runspace exists but is not accepting connections."}
                Write-Host "Log: $($server.LogPath)"
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

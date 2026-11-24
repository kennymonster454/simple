# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 2.3

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

    if (!$SimpleArgs) {
        Write-Host "SIMPLE COMMANDS"
        Write-Host "simple print <text>"
        Write-Host "simple vector ip <address>"
        Write-Host "simple open window <HTML file path>"
        Write-Host "simple localhost start <port>"
        Write-Host "simple localhost stop <port>"
        Write-Host "simple localhost status <port>"
        Write-Host "simple update"
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
            Write-Host "Checking for Simple updates..."
            $tempPath = "$profilePath.download"
            $backupPath = "$profilePath.backup"
            try {
                $response = Invoke-WebRequest -Uri $updateUrl -UseBasicParsing -ErrorAction Stop
                $newCode = [string]$response.Content
                if ([string]::IsNullOrWhiteSpace($newCode)) { throw "The downloaded file is empty." }
                if ($newCode -notmatch 'function\s+simple') { throw "The downloaded file does not contain the Simple command." }
                $parseTokens = $null
                $parseErrors = $null
                [void][System.Management.Automation.Language.Parser]::ParseInput($newCode, [ref]$parseTokens, [ref]$parseErrors)
                if ($parseErrors.Count -gt 0) { throw "GitHub returned invalid PowerShell code: $($parseErrors[0].Message)" }
                $onlineMatch = [regex]::Match($newCode, '(?m)^#\s*VERSION\s+(.+?)\s*$')
                if (!$onlineMatch.Success) { throw "The GitHub SIMPLE version could not be identified." }
                if (!(Test-Path -LiteralPath $profilePath -PathType Leaf)) { throw "The installed SIMPLE profile was not found." }
                $installedCode = Get-Content -LiteralPath $profilePath -Raw -ErrorAction Stop
                $installedMatch = [regex]::Match($installedCode, '(?m)^#\s*VERSION\s+(.+?)\s*$')
                if (!$installedMatch.Success) { throw "The installed SIMPLE version could not be identified." }
                $installedVersion = $installedMatch.Groups[1].Value.Trim()
                $onlineVersion = $onlineMatch.Groups[1].Value.Trim()
                if ($installedVersion -eq $onlineVersion) {
                    Write-Host "Simple $installedVersion is already installed. No update is needed."
                    return
                }
                [System.IO.File]::WriteAllText($tempPath, $newCode, ([System.Text.UTF8Encoding]::new($true)))
                Copy-Item -LiteralPath $profilePath -Destination $backupPath -Force -ErrorAction Stop
                Move-Item -LiteralPath $tempPath -Destination $profilePath -Force -ErrorAction Stop
                . $profilePath
                Write-Host "Simple updated from $installedVersion to $onlineVersion!"
                Write-Host "Backup: $backupPath"
            }
            catch {
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                Write-Host "Update failed: $($_.Exception.Message)"
                Write-Host "Your existing Simple installation was not replaced unless installation had already completed."
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
                $serverCode = $serverCode.Replace('while ($true) {','while (!$State.StopRequested) { if (!$listener.Pending()) { Start-Sleep -Milliseconds 100; continue }')
                $serverCode = $serverCode.Replace('$listener.Start()','$listener.Start()' + [Environment]::NewLine + '$State.Listener = $listener' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] LISTENING 127.0.0.1:{1}" -f (Get-Date -Format o), $Port)')
                $serverCode = $serverCode.Replace('$client = $listener.AcceptTcpClient()','$client = $listener.AcceptTcpClient()' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] CONNECTION {1}" -f (Get-Date -Format o), $client.Client.RemoteEndPoint)')
                $serverCode = $serverCode.Replace('$requestLine = $reader.ReadLine()','$requestLine = $reader.ReadLine()' + [Environment]::NewLine + 'Add-Content -LiteralPath $LogPath -Value ("[{0}] REQUEST {1}" -f (Get-Date -Format o), $requestLine)')
                $serverCode = ('$Port = ' + $port) + [Environment]::NewLine + ('$HtmlPath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(''{0}''))' -f [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($htmlPath))) + [Environment]::NewLine + '$State = $args[0]' + [Environment]::NewLine + '$LogPath = $args[1]' + [Environment]::NewLine + $serverCode
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

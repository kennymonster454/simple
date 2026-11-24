# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 2.0

function simple {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$SimpleArgs
    )

    $root = Join-Path $env:LOCALAPPDATA "Simple\Servers"
    $serverPath = Join-Path $root "simple-server.ps1"
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

            try {
                $response = Invoke-WebRequest -Uri $updateUrl -UseBasicParsing -ErrorAction Stop
                $newCode = $response.Content

                if ([string]::IsNullOrWhiteSpace($newCode)) {
                    throw "The downloaded file is empty."
                }

                if ($newCode -notmatch 'function\s+simple') {
                    throw "The downloaded file does not contain the Simple command."
                }

                $backupPath = "$profilePath.backup"

                if (Test-Path $profilePath) {
                    Copy-Item $profilePath $backupPath -Force
                }

                Set-Content -Path $profilePath -Value $newCode -Encoding UTF8 -ErrorAction Stop

                . $profilePath

                Write-Host "Simple updated successfully!"
                Write-Host "Backup: $backupPath"
            }
            catch {
                Write-Host "Update failed: $($_.Exception.Message)"
                Write-Host "Your existing Simple installation should remain available."
            }
        }

        "localhost" {
            if ($SimpleArgs.Count -lt 2) {
                Write-Host "Usage: simple localhost start/stop/status <port>"
                return
            }

            $action = $SimpleArgs[1].ToLower()

            if ($SimpleArgs.Count -lt 3) {
                Write-Host "Please specify a port."
                return
            }

            $port = 0

            if (![int]::TryParse($SimpleArgs[2], [ref]$port) -or
                $port -lt 1 -or $port -gt 65535) {
                Write-Host "Invalid port."
                return
            }

            $pidFile = Join-Path $root "$port.pid"
            $logFile = Join-Path $root "$port.log"

            if ($action -eq "start") {

                if (!(Test-Path $root)) {
                    New-Item -ItemType Directory -Path $root -Force | Out-Null
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
                    Add-Type -AssemblyName System.Windows.Forms

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

                Remove-Item $logFile -Force -ErrorAction SilentlyContinue

                $engine = Join-Path $PSHOME "powershell.exe"
                $arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" {1} "{2}" "{3}"' -f $serverPath, $port, $htmlPath, $logFile

                try {
                    $process = Start-Process -FilePath $engine -ArgumentList $arguments -PassThru -WindowStyle Hidden
                }
                catch {
                    Write-Host "Could not launch server: $($_.Exception.Message)"
                    return
                }

                $ready = $false

                for ($i = 0; $i -lt 50; $i++) {
                    Start-Sleep -Milliseconds 100

                    if (Test-Path $logFile) {
                        $log = Get-Content $logFile -Raw

                        if ($log -match "READY $port") {
                            $ready = $true
                            break
                        }

                        if ($log -match "SERVER ERROR") {
                            break
                        }
                    }

                    if ($process.HasExited) {
                        break
                    }
                }

                if (!$ready) {
                    if (!$process.HasExited) {
                        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    }

                    Write-Host "Server failed to start."

                    if (Test-Path $logFile) {
                        Get-Content $logFile | Write-Host
                    }

                    return
                }

                Set-Content -Path $pidFile -Value $process.Id

                Write-Host "Simple localhost started!"
                Write-Host "Port: $port"
                Write-Host "Address: http://localhost:$port"

                Start-Process "http://localhost:$port"
            }

            elseif ($action -eq "stop") {

                if (!(Test-Path $pidFile)) {
                    Write-Host "No Simple server registered on port $port."
                    return
                }

                $serverPid = [int](Get-Content $pidFile -Raw)

                try {
                    Stop-Process -Id $serverPid -Force -ErrorAction Stop
                    Write-Host "Simple localhost stopped on port $port."
                }
                catch {
                    Write-Host "Server process was already stopped."
                }

                Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
            }

            elseif ($action -eq "status") {

                if (!(Test-Path $pidFile)) {
                    Write-Host "Simple localhost is NOT running on port $port."
                    return
                }

                $serverPid = [int](Get-Content $pidFile -Raw)
                $process = Get-Process -Id $serverPid -ErrorAction SilentlyContinue

                if (!$process) {
                    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
                    Write-Host "Simple localhost is NOT running on port $port."
                    return
                }

                $test = [System.Net.Sockets.TcpClient]::new()
                $connected = $false

                try {
                    $test.Connect("127.0.0.1", $port)
                    $connected = $true
                }
                catch {}
                finally {
                    $test.Dispose()
                }

                if ($connected) {
                    Write-Host "Simple localhost is RUNNING!"
                    Write-Host "http://localhost:$port"
                }
                else {
                    Write-Host "Server process exists but is not accepting connections."
                }
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

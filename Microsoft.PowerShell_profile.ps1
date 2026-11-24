# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 2.0

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

                # The server runs as a hidden child process. Its process object
                # is tracked in memory; SIMPLE does not create server, PID, or log files.
                $serverCode = @'
$ErrorActionPreference = "Stop"
$listener = $null
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    $listener.Start()

    while ($true) {
        $client = $listener.AcceptTcpClient()
        $reader = $null
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
            $requestLine = $reader.ReadLine()

            if ($null -ne $requestLine) {
                while ($true) {
                    $headerLine = $reader.ReadLine()
                    if ($null -eq $headerLine -or $headerLine -eq "") { break }
                }

                if ($HtmlPath -ne "-" -and (Test-Path -LiteralPath $HtmlPath -PathType Leaf)) {
                    $body = [System.IO.File]::ReadAllText($HtmlPath)
                }
                else {
                    $body = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Simple Documentation</title>
<style>
body { font-family: Segoe UI, Arial, sans-serif; max-width: 850px; margin: 48px auto; padding: 0 22px; line-height: 1.6; color: #202124; }
h1 { margin-bottom: 4px; } .sub { color: #666; margin-top: 0; }
code { background: #f1f3f4; padding: 3px 6px; border-radius: 4px; }
section { margin-top: 28px; } #updates { padding: 12px 16px; background: #f4f6f8; border-radius: 8px; }
</style>
</head>
<body>
<h1>Simple Documentation</h1>
<p class="sub">A small command language created by Kenny.</p>
<section>
<h2>Commands</h2>
<p><code>simple print &lt;text&gt;</code> — prints text.</p>
<p><code>simple vector ip &lt;address&gt;</code> — stores the Vector IP address.</p>
<p><code>simple open window &lt;HTML file path&gt;</code> — opens an HTML file in a Simple window.</p>
<p><code>simple localhost start &lt;port&gt;</code> — starts this localhost server.</p>
<p><code>simple localhost stop &lt;port&gt;</code> — stops a localhost server.</p>
<p><code>simple localhost status &lt;port&gt;</code> — checks a localhost server.</p>
<p><code>simple update</code> — updates the SIMPLE command system.</p>
</section>
<section>
<h2>Simple Updates</h2>
<div id="updates">Checking for update information...</div>
</section>
<script>
(async function () {
  const panel = document.getElementById("updates");
  try {
    const response = await fetch("https://raw.githubusercontent.com/kennymonster454/simple/main/update.json", { cache: "no-store" });
    if (!response.ok) throw new Error("No update information is published yet.");
    const data = await response.json();
    if (!data.version || !Array.isArray(data.updates)) throw new Error("The update information file is invalid.");
    const heading = document.createElement("strong");
    heading.textContent = "Latest SIMPLE version: " + data.version;
    panel.replaceChildren(heading);
    data.updates.forEach(function (item) {
      const entry = document.createElement("p");
      entry.textContent = item.date ? item.date + " — " + item.info : item.info;
      panel.appendChild(entry);
    });
  } catch (error) {
    panel.textContent = error.message;
  }
})();
</script>
</body>
</html>
"@
                }

                $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
                $crlf = [string][char]13 + [string][char]10
                $header = "HTTP/1.1 200 OK" + $crlf + "Content-Type: text/html; charset=utf-8" + $crlf + "Content-Length: $($bytes.Length)" + $crlf + "Connection: close" + $crlf + $crlf
                $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
                $stream.Write($headerBytes, 0, $headerBytes.Length)
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
            }
        }
        catch {}
        finally {
            if ($reader) { $reader.Dispose() }
            $client.Close()
        }
    }
}
catch {}
finally {
    if ($listener) { $listener.Stop() }
}
'@

                $htmlEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($htmlPath))
                $serverCode = ('$Port = ' + $port) + [Environment]::NewLine +
                    ('$HtmlPath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(''{0}''))' -f $htmlEncoded) +
                    [Environment]::NewLine + $serverCode
                $encodedServer = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($serverCode))
                $engine = Join-Path $PSHOME "powershell.exe"

                try {
                    $process = Start-Process -FilePath $engine -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encodedServer" -PassThru -WindowStyle Hidden -ErrorAction Stop
                }
                catch {
                    Write-Host "Could not launch localhost: $($_.Exception.Message)"
                    return
                }

                $ready = $false
                for ($i = 0; $i -lt 50; $i++) {
                    Start-Sleep -Milliseconds 100
                    if ($process.HasExited) { break }

                    $probe = [System.Net.Sockets.TcpClient]::new()
                    try {
                        $probe.Connect("127.0.0.1", $port)
                        $ready = $true
                        break
                    }
                    catch {}
                    finally {
                        $probe.Dispose()
                    }
                }

                if (!$ready) {
                    if (!$process.HasExited) {
                        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    }
                    Write-Host "Server failed to start. The process did not open port $port."
                    return
                }

                $global:SimpleServers[$port] = $process
                Write-Host "Simple localhost started!"
                Write-Host "Port: $port"
                Write-Host "Address: http://localhost:$port"
                Start-Process "http://localhost:$port"
            }
            elseif ($action -eq "stop") {
                if (!$global:SimpleServers.ContainsKey($port)) {
                    Write-Host "No SIMPLE server is being tracked on port $port."
                    return
                }

                $process = $global:SimpleServers[$port]
                if (!$process.HasExited) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
                $global:SimpleServers.Remove($port)
                Write-Host "Simple localhost stopped on port $port."
            }
            elseif ($action -eq "status") {
                if (!$global:SimpleServers.ContainsKey($port)) {
                    Write-Host "Simple localhost is NOT running on port $port."
                    return
                }

                $process = $global:SimpleServers[$port]
                if ($process.HasExited) {
                    $global:SimpleServers.Remove($port)
                    Write-Host "Simple localhost is NOT running on port $port."
                    return
                }

                $probe = [System.Net.Sockets.TcpClient]::new()
                $connected = $false
                try {
                    $probe.Connect("127.0.0.1", $port)
                    $connected = $true
                }
                catch {}
                finally {
                    $probe.Dispose()
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

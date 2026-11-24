# SIMPLE LANGUAGE
# SIMPLE COMMAND SYSTEM - CREATED BY KENNY
# VERSION 2.7

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
        Write-Host "simple update localhost <port>"
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
            $startLocalhost = $false
            $startPort = 0
            if ($SimpleArgs.Count -ge 3 -and $SimpleArgs[1].ToLower() -eq "localhost") {
                if (![int]::TryParse($SimpleArgs[2], [ref]$startPort) -or $startPort -lt 1 -or $startPort -gt 65535) {
                    Write-Host "Usage: simple update localhost <port>"
                    return
                }
                $startLocalhost = $true
            }

            $updateSucceeded = $false
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
                $installedCompare = $installedCode.Replace("`r`n", "`n").TrimEnd()
                $onlineCompare = $newCode.Replace("`r`n", "`n").TrimEnd()

                if ($installedCompare -ceq $onlineCompare) {
                    Write-Host "Simple $installedVersion is already fully up to date."
                    $updateSucceeded = $true
                }
                else {
                    [System.IO.File]::WriteAllText($tempPath, $newCode, ([System.Text.UTF8Encoding]::new($true)))
                    Copy-Item -LiteralPath $profilePath -Destination $backupPath -Force -ErrorAction Stop
                    Move-Item -LiteralPath $tempPath -Destination $profilePath -Force -ErrorAction Stop
                    . $profilePath
                    Write-Host "Simple updated from $installedVersion to $onlineVersion!"
                    Write-Host "Backup: $backupPath"
                    $updateSucceeded = $true
                }
            }
            catch {
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                Write-Host "Update failed: $($_.Exception.Message)"
                Write-Host "Your existing Simple installation was not replaced unless installation had already completed."
            }

            if ($updateSucceeded -and $startLocalhost) {
                simple localhost start $startPort
            }
        }

        "localhost" {
            Write-Host ""
            Write-Host "SIMPLE LOCALHOST IS CURRENTLY NOT WORKING." -ForegroundColor Yellow
            Write-Host "The localhost feature is under development and is being rebuilt." -ForegroundColor Yellow
            Write-Host "No server was started."
            Write-Host ""
            return
        }
        default {
            Write-Host "Unknown command: $($SimpleArgs[0])"
        }
    }
}

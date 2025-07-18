<#
    SilentInstaller installs all required SSI applications without requiring user intervention. 
    Additionally, Swift Assist is installed, and the SSI printers are configured. 

    The script uses a configuration file located in the /config directory.
    Running SilentInstaller with no arguments defaults to installing all items defined in the config file.
#>

param (
    [ValidateNotNullOrEmpty()]
    # Update this config file Yearly.
    [string]$ConfigFile = "config\SSI-Install-Default.json",
    
    [ValidateSet("HRSA", "CMS", "Both", "")]
    [string]$Keyword,
    
    [switch]$Verbose
)

# Initialize VPN flags
$HRSA = $true
$CMS = $true

# Verbose Mode Handling
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

# Check if the config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Error "The config file '$ConfigFile' was not found. Please check the file path."
    exit
}

# Read and parse the JSON configuration file
$config = Get-Content $ConfigFile | ConvertFrom-Json

# Set the working directory
Set-Location "C:\Users\localadmin\Desktop\SSI-Install-2024"

# Progress tracking variables
$TotalSteps = $config.Count
$CurrentStep = 0

# Iterate over each item in the configuration
foreach ($app in $config.apps) {
    try {
        # Check if the item should be skipped based on VPN flags
        if (($app.Name -eq "Cisco Anyconnect" -and -not $HRSA) -or
            (($app.Name -eq "Citrix Workspace" -or $app.Name -eq "Zscaler") -and -not $CMS)) {
            Write-Verbose "Skipping $($app.Name) as it's not required based on VPN selection."
            continue
        }
        
        $installer = $null
        # Check processor architecture to install the correct DUO version.
        if ($app.PSObject.Properties['architecture']) {
            $archMap = $app.architecture

            if ($archMap.ContainsKey($architecture)) {
                $installer = $archMap[$architecture]
            } elseif ($archMap.ContainsKey("x86") -and $architecture -eq "AMD64") {
                # Optional fallback for AMD64 to x86 if needed
                $installer = $archMap["x86"]
            } else {
                Write-Warning "No installer found for $($app.name) on $architecture"
                continue
            }
        } elseif ($app.PSObject.Properties['FilePath']) {
            $installer = $app.FilePath
        }

        # Increment step counter
        $CurrentStep++

        # Calculate percentage completion
        $PercentComplete = [math]::Round(($CurrentStep / $TotalSteps) * 100, 2)

        # Display progress
        Write-Progress -Activity "Installing SSI 2025 Software Suite" -Status "Step $CurrentStep of $TotalSteps\: Installing $($app.Name)" -PercentComplete $PercentComplete

        # Prepare Start-Process parameters
        $params = @{
            FilePath      = $installer
            ArgumentList  = $app.ArgumentList
            PassThru      = $true
            Wait          = $true
        }

        # Start the installation process
        Start-Process @params
        Write-Host "$($app.Name) installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install $($app.Name): $_.Exception.Message"
    }
    finally {
        Write-Verbose "Completed step $CurrentStep of $TotalSteps."
    }
}

# Extract Swift Assist launcher and run registry file
try {
    Expand-Archive -LiteralPath 'Swift Assist Launcher.zip' -DestinationPath "C:\Users\Public"
    Start-Process -FilePath "C:\Users\Public\SwiftAssistLauncher.reg" -Wait
    Write-Host "Swift Assist Launcher set up successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to set up Swift Assist Launcher: $_.Exception.Message"
}

# Add SSI printers
try {
    Add-Printer -IppURL "10.7.5.3" -Name "Front Office Printer"
    Add-Printer -IppURL "10.7.5.5" -Name "Upstairs Printer"
    Write-Host "SSI printers added successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to add printers: $_.Exception.Message"
}

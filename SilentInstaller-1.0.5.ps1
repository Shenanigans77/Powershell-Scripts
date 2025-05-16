param (
    [ValidateNotNullOrEmpty()]
    # Update this config file Yearly.
    [string]$ConfigFile = "config\SSI-Install-2024-Default.json",
    
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

# Set VPN flags based on keyword input
switch ($Keyword) {
    "HRSA" {
        $CMS = $false
    }
    "CMS" {
        $HRSA = $false
    }
    "Both" {
        $HRSA = $true
        $CMS = $true
    }
    Default {}
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
foreach ($item in $config) {
    try {
        # Check if the item should be skipped based on VPN flags
        if (($item.Name -eq "Cisco Anyconnect" -and -not $HRSA) -or
            (($item.Name -eq "Citrix Workspace" -or $item.Name -eq "Zscaler") -and -not $CMS)) {
            Write-Verbose "Skipping $($item.Name) as it's not required based on VPN selection."
            continue
        }

        # Increment step counter
        $CurrentStep++

        # Calculate percentage completion
        $PercentComplete = [math]::Round(($CurrentStep / $TotalSteps) * 100, 2)

        # Display progress
        Write-Progress -Activity "Installing SSI 2024 Software Suite" -Status "Step $CurrentStep of $TotalSteps\: Installing $($item.Name)" -PercentComplete $PercentComplete

        # Prepare Start-Process parameters
        $params = @{
            FilePath      = $item.FilePath
            ArgumentList  = $item.ArgumentList
            PassThru      = $true
            Wait          = $true
        }

        # Start the installation process
        Start-Process @params
        Write-Host "$($item.Name) installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install $($item.Name): $_.Exception.Message"
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

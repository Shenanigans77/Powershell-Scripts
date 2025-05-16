# Set script to stop on errors
$ErrorActionPreference = 'Stop'

# Define certificate paths
$certs = @{
    "Root"        = ".\Cyberark Certs\Entrust Managed Services Root CA.cer"
    "Intermediate"= ".\Cyberark Certs\Federal Common Policy CA G2.cer"
    "Personal"    = ".\Cyberark Certs\HHS-FPKI-Intermediate-CA-E1.cer"
}

# Define store mapping
$storeMap = @{
    "Root"        = "Root"
    "Intermediate"= "CA"
    "Personal"    = "CA"
}

foreach ($name in $certs.Keys) {
    $certPath = $certs[$name]

    if (-Not (Test-Path $certPath)) {
        Write-Error "Certificate file not found: $certPath"
        continue
    }

    try {
        # Load certificate
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($certPath)

        # Open the correct store
        $storeName = $storeMap[$name]
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, "LocalMachine")
        $store.Open("ReadWrite")

        # Add certificate
        $store.Add($cert)
        Write-Host "$name certificate imported into $storeName store." -ForegroundColor Green

        $store.Close()
    } catch {
        Write-Error "Failed to import $name certificate: $_"
    }
}

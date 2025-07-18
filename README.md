# SSI Endpoint Configuration

---

## Configuration Instructions

Run this script before joinging the machine to the domain.

---

### Silent Installer

#### Step 1

Open Powershell as admin on the new device.
Run `Set-ExecutionPolicy Unrestricted` and answer Yes.

#### Step 2

Run SilentInstaller-1.0.5.ps1
Running with no options will default to the software defined in the config file SSI-Install-Default.json

#### Notes

Greenshot will open a browser window once it is done installing.
Once that happens, close Greenshot from the system tray so the installer can continue.

### CyberArk Certs

Run CyberArkInstaller.ps1 in the same elevated PowerShell terminal.

### Conclusion

Adding the machine to the domain will change the execution policy back to the desired RemoteSigned.

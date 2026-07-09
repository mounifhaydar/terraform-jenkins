# Manual Terraform Provider Installation Script
# Run this after downloading terraform-provider-aws_5.80.0_windows_amd64.zip

$version = "5.80.0"
$zipFile = "terraform-provider-aws_5.80.0_windows_amd64.zip"
$pluginDir = "$env:APPDATA\terraform.d\plugins\registry.terraform.io\hashicorp\aws\$version\windows_amd64"

# Check if zip file exists
if (!(Test-Path $zipFile)) {
    Write-Error "Provider zip file not found: $zipFile"
    Write-Output "Download it from: https://releases.hashicorp.com/terraform-provider-aws/$version/"
    exit 1
}

# Create plugin directory
New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null

# Extract
Write-Output "Extracting to: $pluginDir"
Expand-Archive -Path $zipFile -DestinationPath $pluginDir -Force

# Verify
$installed = Get-ChildItem $pluginDir -Filter "terraform-provider-aws*.exe"
if ($installed) {
    Write-Output "✓ Provider installed successfully:"
    $installed | Select-Object Name, Length, LastWriteTime | Format-List
    Write-Output "`nNow run: terraform init"
} else {
    Write-Error "Installation failed - executable not found"
}

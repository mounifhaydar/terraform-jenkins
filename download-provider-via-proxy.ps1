# Download Terraform AWS Provider via alternative methods
# This script tries multiple approaches to download the provider

$version = "5.80.0"
$fileName = "terraform-provider-aws_${version}_windows_amd64.zip"
$outputFile = "C:\Users\user\Downloads\$fileName"

Write-Output "=== Terraform AWS Provider Downloader ==="
Write-Output "Version: $version"
Write-Output ""

# Method 1: Try CloudFlare CDN mirror
Write-Output "[Method 1] Trying CloudFlare mirror..."
$cloudflareUrl = "https://cloudflare-releases.hashicorp.com/terraform-provider-aws/$version/$fileName"
try {
    Invoke-WebRequest -Uri $cloudflareUrl -OutFile $outputFile -UseBasicParsing -TimeoutSec 60
    if (Test-Path $outputFile) {
        Write-Output "✓ SUCCESS via CloudFlare!"
        Write-Output "File saved to: $outputFile"
        exit 0
    }
} catch {
    Write-Output "✗ Failed: $($_.Exception.Message)"
}

# Method 2: Try GitHub mirror (if exists)
Write-Output "`n[Method 2] Trying GitHub releases..."
$githubUrl = "https://github.com/hashicorp/terraform-provider-aws/releases/download/v$version/$fileName"
try {
    Invoke-WebRequest -Uri $githubUrl -OutFile $outputFile -UseBasicParsing -TimeoutSec 60
    if (Test-Path $outputFile) {
        Write-Output "✓ SUCCESS via GitHub!"
        Write-Output "File saved to: $outputFile"
        exit 0
    }
} catch {
    Write-Output "✗ Failed: $($_.Exception.Message)"
}

# Method 3: Try with curl (sometimes bypasses PowerShell restrictions)
Write-Output "`n[Method 3] Trying with curl..."
$curlUrl = "https://releases.hashicorp.com/terraform-provider-aws/$version/$fileName"
try {
    & curl.exe -L -o $outputFile $curlUrl --connect-timeout 30 --max-time 120
    if (Test-Path $outputFile) {
        $size = (Get-Item $outputFile).Length
        if ($size -gt 1MB) {
            Write-Output "✓ SUCCESS with curl!"
            Write-Output "File saved to: $outputFile"
            Write-Output "Size: $([math]::Round($size / 1MB, 2)) MB"
            exit 0
        }
    }
} catch {
    Write-Output "✗ Failed: $($_.Exception.Message)"
}

# Method 4: Instructions for manual download
Write-Output "`n[Method 4] Manual download required"
Write-Output ""
Write-Output "All automatic methods failed. Please:"
Write-Output "1. Connect to a VPN or use a different network"
Write-Output "2. Try downloading from: https://releases.hashicorp.com/terraform-provider-aws/$version/"
Write-Output "3. Or use this direct link: $curlUrl"
Write-Output "4. Save to: $outputFile"
Write-Output ""
Write-Output "Once downloaded, run: .\INSTALL_PROVIDER.ps1"

exit 1

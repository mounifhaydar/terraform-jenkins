# Destroy Jenkins Infrastructure
# Reverses everything created by deploy-jenkins.ps1

$ErrorActionPreference = "Stop"

if (!(Test-Path ".\infrastructure-state.json")) {
    Write-Error "No infrastructure state found. Nothing to destroy."
    exit 1
}

$state = Get-Content ".\infrastructure-state.json" | ConvertFrom-Json

Write-Output "=== Destroying Jenkins Infrastructure ==="
Write-Output "Created: $($state.created)"
Write-Output ""

$confirm = Read-Host "Are you sure you want to destroy all resources? (yes/no)"
if ($confirm -ne "yes") {
    Write-Output "Aborted."
    exit 0
}

try {
    # Delete Security Group
    Write-Output "[1/5] Deleting security group..."
    aws ec2 delete-security-group `
        --group-id $state.security_group_id `
        --region $state.region 2>$null
    Write-Output "✓ Security group deleted"

    # Detach and delete Internet Gateway
    Write-Output "[2/5] Deleting internet gateway..."
    aws ec2 detach-internet-gateway `
        --vpc-id $state.vpc_id `
        --internet-gateway-id $state.igw_id `
        --region $state.region 2>$null
    
    aws ec2 delete-internet-gateway `
        --internet-gateway-id $state.igw_id `
        --region $state.region 2>$null
    Write-Output "✓ Internet gateway deleted"

    # Delete Route Table
    Write-Output "[3/5] Deleting route table..."
    aws ec2 delete-route-table `
        --route-table-id $state.route_table_id `
        --region $state.region 2>$null
    Write-Output "✓ Route table deleted"

    # Delete Subnets
    Write-Output "[4/5] Deleting subnets..."
    foreach ($subnetId in ($state.public_subnet_ids + $state.private_subnet_ids)) {
        aws ec2 delete-subnet `
            --subnet-id $subnetId `
            --region $state.region 2>$null
    }
    Write-Output "✓ All subnets deleted"

    # Delete VPC
    Write-Output "[5/5] Deleting VPC..."
    Start-Sleep -Seconds 2  # Wait for dependencies
    aws ec2 delete-vpc `
        --vpc-id $state.vpc_id `
        --region $state.region 2>$null
    Write-Output "✓ VPC deleted"

    # Remove state file
    Remove-Item ".\infrastructure-state.json"
    Write-Output ""
    Write-Output "=== Destruction Complete! ==="

} catch {
    Write-Output "Error during destruction: $_"
    Write-Output "State file preserved for manual cleanup"
    exit 1
}

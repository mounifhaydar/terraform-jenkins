# Pure AWS CLI Script - Replaces Terraform
# Creates Jenkins infrastructure without Terraform provider

$ErrorActionPreference = "Stop"

# Load variables from terraform.tfvars
$tfvars = Get-Content .\terraform.tfvars | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' }
$config = @{}
foreach ($line in $tfvars) {
    if ($line -match '^\s*(\w+)\s*=\s*"?([^"]+)"?') {
        $config[$matches[1]] = $matches[2].Trim('"')
    } elseif ($line -match '^\s*(\w+)\s*=\s*\[(.*)\]') {
        $config[$matches[1]] = $matches[2].Split(',') | ForEach-Object { $_.Trim().Trim('"') }
    }
}

Write-Output "=== Jenkins Infrastructure Deployment (AWS CLI) ==="
Write-Output "Region: us-east-1"
Write-Output "VPC CIDR: $($config['vpc_cidr'])"
Write-Output ""

# Step 1: Create VPC
Write-Output "[1/7] Creating VPC..."
$vpcId = aws ec2 create-vpc `
    --cidr-block $config['vpc_cidr'] `
    --region us-east-1 `
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$($config['vpc_name'])}]" `
    --query 'Vpc.VpcId' `
    --output text

if ($LASTEXITCODE -ne 0) { throw "Failed to create VPC" }
Write-Output "✓ VPC created: $vpcId"

# Step 2: Create Public Subnets
Write-Output "`n[2/7] Creating public subnets..."
$publicSubnetIds = @()
for ($i = 0; $i -lt $config['cidr_public_subnet'].Count; $i++) {
    $subnetId = aws ec2 create-subnet `
        --vpc-id $vpcId `
        --cidr-block $config['cidr_public_subnet'][$i] `
        --availability-zone $config['eu_availability_zone'][$i] `
        --region us-east-1 `
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=jenkins-public-subnet-$($i+1)}]" `
        --query 'Subnet.SubnetId' `
        --output text
    
    if ($LASTEXITCODE -ne 0) { throw "Failed to create public subnet $($i+1)" }
    $publicSubnetIds += $subnetId
    Write-Output "✓ Public subnet $($i+1) created: $subnetId"
}

# Step 3: Create Private Subnets
Write-Output "`n[3/7] Creating private subnets..."
$privateSubnetIds = @()
for ($i = 0; $i -lt $config['cidr_private_subnet'].Count; $i++) {
    $subnetId = aws ec2 create-subnet `
        --vpc-id $vpcId `
        --cidr-block $config['cidr_private_subnet'][$i] `
        --availability-zone $config['eu_availability_zone'][$i] `
        --region us-east-1 `
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=jenkins-private-subnet-$($i+1)}]" `
        --query 'Subnet.SubnetId' `
        --output text
    
    if ($LASTEXITCODE -ne 0) { throw "Failed to create private subnet $($i+1)" }
    $privateSubnetIds += $subnetId
    Write-Output "✓ Private subnet $($i+1) created: $subnetId"
}

# Step 4: Create Internet Gateway
Write-Output "`n[4/7] Creating Internet Gateway..."
$igwId = aws ec2 create-internet-gateway `
    --region us-east-1 `
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=jenkins-igw}]" `
    --query 'InternetGateway.InternetGatewayId' `
    --output text

aws ec2 attach-internet-gateway `
    --vpc-id $vpcId `
    --internet-gateway-id $igwId `
    --region us-east-1

if ($LASTEXITCODE -ne 0) { throw "Failed to create/attach IGW" }
Write-Output "✓ Internet Gateway created and attached: $igwId"

# Step 5: Create and configure Route Table
Write-Output "`n[5/7] Creating public route table..."
$rtId = aws ec2 create-route-table `
    --vpc-id $vpcId `
    --region us-east-1 `
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=jenkins-public-rt}]" `
    --query 'RouteTable.RouteTableId' `
    --output text

aws ec2 create-route `
    --route-table-id $rtId `
    --destination-cidr-block 0.0.0.0/0 `
    --gateway-id $igwId `
    --region us-east-1 | Out-Null

foreach ($subnetId in $publicSubnetIds) {
    aws ec2 associate-route-table `
        --route-table-id $rtId `
        --subnet-id $subnetId `
        --region us-east-1 | Out-Null
}

Write-Output "✓ Route table created and associated: $rtId"

# Step 6: Create Security Group
Write-Output "`n[6/7] Creating security group..."
$sgId = aws ec2 create-security-group `
    --group-name jenkins-sg `
    --description "Security group for Jenkins" `
    --vpc-id $vpcId `
    --region us-east-1 `
    --query 'GroupId' `
    --output text

# Allow SSH
aws ec2 authorize-security-group-ingress `
    --group-id $sgId `
    --protocol tcp `
    --port 22 `
    --cidr 0.0.0.0/0 `
    --region us-east-1 | Out-Null

# Allow HTTP
aws ec2 authorize-security-group-ingress `
    --group-id $sgId `
    --protocol tcp `
    --port 80 `
    --cidr 0.0.0.0/0 `
    --region us-east-1 | Out-Null

# Allow Jenkins port
aws ec2 authorize-security-group-ingress `
    --group-id $sgId `
    --protocol tcp `
    --port 8080 `
    --cidr 0.0.0.0/0 `
    --region us-east-1 | Out-Null

Write-Output "✓ Security group created: $sgId"

# Step 7: Save state
Write-Output "`n[7/7] Saving infrastructure state..."
$state = @{
    vpc_id = $vpcId
    public_subnet_ids = $publicSubnetIds
    private_subnet_ids = $privateSubnetIds
    igw_id = $igwId
    route_table_id = $rtId
    security_group_id = $sgId
    region = "us-east-1"
    created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$state | ConvertTo-Json | Set-Content ".\infrastructure-state.json"
Write-Output "✓ State saved to infrastructure-state.json"

Write-Output "`n=== Deployment Complete! ==="
Write-Output ""
Write-Output "Infrastructure Details:"
Write-Output "  VPC ID: $vpcId"
Write-Output "  Public Subnets: $($publicSubnetIds -join ', ')"
Write-Output "  Private Subnets: $($privateSubnetIds -join ', ')"
Write-Output "  Internet Gateway: $igwId"
Write-Output "  Security Group: $sgId"
Write-Output ""
Write-Output "Next Steps:"
Write-Output "  1. Review infrastructure-state.json"
Write-Output "  2. To destroy: .\destroy-jenkins.ps1"

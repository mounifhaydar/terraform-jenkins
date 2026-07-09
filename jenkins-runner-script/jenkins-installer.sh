#!/bin/bash
# Redirect all output to log file
exec > /var/log/jenkins-install.log 2>&1
set -x

echo "============================================"
echo "Jenkins Docker Installation"
echo "Started: $(date)"
echo "============================================"

# Step 1: Update packages
echo "[STEP 1] System update..."
dnf update -y

# Step 2: Install Docker
echo "[STEP 2] Installing Docker..."
dnf install -y docker git wget unzip

# Step 3: Start Docker
echo "[STEP 3] Starting Docker service..."
systemctl enable docker
systemctl start docker
docker --version

# Step 4: Set up Jenkins data directory
echo "[STEP 4] Creating Jenkins data directory..."
mkdir -p /var/jenkins_home
# UID 1000 is the jenkins user inside the container
chown -R 1000:1000 /var/jenkins_home

# Step 5: Pull Jenkins image first (separate from run, so we can see progress)
echo "[STEP 5] Pulling Jenkins LTS image (this takes 2-5 minutes)..."
docker pull jenkins/jenkins:lts-jdk21
echo "Pull complete: $(date)"

# Step 6: Run Jenkins container
echo "[STEP 6] Starting Jenkins container..."
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/jenkins_home:/var/jenkins_home \
  -e JENKINS_HOME=/var/jenkins_home \
  jenkins/jenkins:lts-jdk21

echo "Container started: $(docker ps --filter name=jenkins --format '{{.ID}} {{.Status}}')"

# Step 7: Wait for Jenkins to fully initialize (generates initialAdminPassword)
echo "[STEP 7] Waiting for Jenkins to initialize..."
TIMEOUT=300
ELAPSED=0
while [ $${ELAPSED} -lt $${TIMEOUT} ]; do
  if docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
    echo "Jenkins is ready!"
    break
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
  echo "Waiting... $${ELAPSED}s elapsed"
done

# Step 8: Print access info
echo ""
echo "============================================"
echo "JENKINS SETUP COMPLETE"
echo "Finished: $(date)"
echo "============================================"
echo "Container status:"
docker ps
echo ""
echo "Jenkins initial admin password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Not ready yet - Jenkins still initializing"
echo ""
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

# Step 9: Install Terraform (background, non-blocking)
echo "[STEP 9] Installing Terraform in background..."
TF_VERSION="1.9.8"
wget -q "https://releases.hashicorp.com/terraform/$${TF_VERSION}/terraform_$${TF_VERSION}_linux_amd64.zip" \
  -O /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /tmp/
mv /tmp/terraform /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm -f /tmp/terraform.zip
echo "Terraform installed: $(terraform version | head -1)"

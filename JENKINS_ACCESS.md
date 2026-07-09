# Jenkins Setup Complete ✅

## 🎯 Access Information

**Instance Details:**
- **Public IP:** `98.80.210.203`
- **Instance Type:** t3.small (2 vCPU, 2GB RAM, 20GB storage)
- **Instance ID:** i-0f06cc53ad97de9ab
- **OS:** Amazon Linux 2023
- **Java:** Amazon Corretto 17
- **Jenkins:** Latest LTS (Debian stable)
- **Terraform:** v1.9.8

---

## 🌐 Access URLs

### Direct Access (Recommended for initial setup)
```
http://98.80.210.203:8080
```

### Via Load Balancer (Use after health check passes)
```
http://dev-proj-1-alb-1649870251.us-east-1.elb.amazonaws.com
```

---

## 🔐 Getting Jenkins Initial Admin Password

### Method 1: SSH into the instance
```bash
ssh -i ~/.ssh/aws_ec2_terraform ec2-user@98.80.210.203
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Method 2: Check the installation log
```bash
ssh -i ~/.ssh/aws_ec2_terraform ec2-user@98.80.210.203
sudo cat /var/log/jenkins-install.log
```

**Note:** Jenkins takes ~3-5 minutes to fully start after the instance boots. If the password file doesn't exist yet, wait a minute and try again.

---

## ⏱️ Installation Timeline

- **00:00** - Instance launched
- **00:30** - User data script starts
- **02:00** - Jenkins packages installed
- **03:00** - Jenkins service starting
- **04:00** - **Jenkins UI should be accessible**
- **05:00** - Jenkins fully initialized

---

## 🔍 Troubleshooting

### Check if Jenkins is running:
```bash
ssh -i ~/.ssh/aws_ec2_terraform ec2-user@98.80.210.203
sudo systemctl status jenkins
```

### View Jenkins logs:
```bash
sudo journalctl -u jenkins -f
```

### Check installation progress:
```bash
sudo tail -f /var/log/jenkins-install.log
```

### Restart Jenkins (if needed):
```bash
sudo systemctl restart jenkins
```

---

## 📝 First Time Setup Steps

1. **Wait 4-5 minutes** after instance launch
2. Open browser to `http://98.80.210.203:8080`
3. You'll see "Unlock Jenkins" page
4. SSH to the instance and get the password:
   ```bash
   ssh -i ~/.ssh/aws_ec2_terraform ec2-user@98.80.210.203
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
5. Copy the password and paste it into the browser
6. Choose "Install suggested plugins"
7. Create your first admin user
8. Set Jenkins URL (keep default or use ALB URL)
9. Start using Jenkins!

---

## 🏗️ Infrastructure Details

**VPC:**
- CIDR: 10.0.0.0/16
- Public Subnets: 10.0.1.0/24 (us-east-1a), 10.0.2.0/24 (us-east-1b)
- Private Subnets: 10.0.3.0/24 (us-east-1a), 10.0.4.0/24 (us-east-1b)

**Security Groups:**
- SSH (22) - Open to 0.0.0.0/0 ⚠️
- HTTP (80) - Open to 0.0.0.0/0
- HTTPS (443) - Open to 0.0.0.0/0
- Jenkins (8080) - Open to 0.0.0.0/0 ⚠️

**Load Balancer:**
- Type: Application Load Balancer
- Scheme: Internet-facing
- Listener: HTTP:80 → Jenkins:8080
- Health Check: /login on port 8080

---

## ⚠️ Security Recommendations

After initial setup, consider:

1. **Restrict SSH access** to your IP only
2. **Close port 8080** to public (access only via ALB)
3. **Enable HTTPS** by:
   - Registering a domain in Route53
   - Uncommenting the `hosted_zone` and `certificate_manager` modules in `main.tf`
   - Running `terraform apply`
4. **Configure Jenkins security**:
   - Enable CSRF protection
   - Configure proper authentication
   - Set up role-based access control

---

## 🗑️ Cleanup

To destroy all resources when done:
```bash
terraform destroy -auto-approve
```

Estimated AWS cost: **~$15-20/month** for a t3.small running 24/7

---

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon Linux 2023 User Guide](https://docs.aws.amazon.com/linux/al2023/ug/what-is-amazon-linux.html)

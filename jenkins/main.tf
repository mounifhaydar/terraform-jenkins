variable "ami_id" {}
variable "instance_type" {}
variable "tag_name" {}
variable "public_key" {}
variable "subnet_id" {}
variable "sg_for_jenkins" {}
variable "enable_public_ip_address" {}
variable "user_data_install_jenkins" {}

output "ssh_connection_string_for_ec2" {
  value = format("%s%s", "ssh -i ~/.ssh/aws_ec2_terraform ec2-user@", aws_instance.jenkins_ec2_instance_ip.public_ip)
}

output "jenkins_ec2_instance_ip" {
  value = aws_instance.jenkins_ec2_instance_ip.id
}

output "dev_proj_1_ec2_instance_public_ip" {
  value = aws_instance.jenkins_ec2_instance_ip.public_ip
}

output "jenkins_url" {
  value = format("%s%s%s", "http://", aws_instance.jenkins_ec2_instance_ip.public_ip, ":8080")
}

# IAM role so SSM Session Manager works (lets us run commands without SSH)
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_ec2_profile" {
  name = "jenkins-ec2-ssm-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}

resource "aws_instance" "jenkins_ec2_instance_ip" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.jenkins_ec2_profile.name
  disable_api_termination = true # enable Termination Protection on the EC2 instance so it cannot be terminated accidentally.

  tags = {
    Name = var.tag_name
  }
  key_name                    = "aws_ec2_terraform"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_for_jenkins
  associate_public_ip_address = var.enable_public_ip_address

  user_data = var.user_data_install_jenkins

  # 20GB gp3 root volume — Jenkins workspace + Docker image needs space
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"   # Enable IMDSv2 endpoint
    http_tokens   = "required"  # Require IMDSv2 tokens (security best practice)
  }

  # Wait for user_data to finish before Terraform marks instance ready
  user_data_replace_on_change = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_key_pair" "jenkins_ec2_instance_public_key" {
  key_name   = "aws_ec2_terraform"
  public_key = var.public_key
}

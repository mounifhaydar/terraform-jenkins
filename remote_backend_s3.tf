terraform {
  required_version = ">= 1.0"
  
  # Provider temporarily removed due to regional restrictions
  # Install manually when available or use VPN/proxy
  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #   }
  # }
  
  # Backend commented out for initial setup
  # Uncomment after provider is available
  # backend "s3" {
  #   bucket = "jenkins-remote-state-527397543025"
  #   key    = "devops-project-1/jenkins/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
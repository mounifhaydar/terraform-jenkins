output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins EC2 instance"
  value       = module.jenkins.dev_proj_1_ec2_instance_public_ip
}

output "jenkins_url" {
  description = "Direct URL to access Jenkins"
  value       = module.jenkins.jenkins_url
}

output "jenkins_alb_url" {
  description = "Load Balancer URL to access Jenkins (via HTTP port 80 -> 8080)"
  value       = format("%s%s", "http://", module.alb.aws_lb_dns_name)
}

output "ssh_connection_string" {
  description = "SSH command to connect to the Jenkins instance"
  value       = module.jenkins.ssh_connection_string_for_ec2
}

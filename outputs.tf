output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = aws_lb.app_lb.dns_name
}
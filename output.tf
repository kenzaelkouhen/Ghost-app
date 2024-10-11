output "load_balancer_dns" {
  value = aws_lb.my_lb.dns_name
  description = "Introduce this as the url to access the ghost app"
}

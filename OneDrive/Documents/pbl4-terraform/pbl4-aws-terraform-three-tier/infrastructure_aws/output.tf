output "lb_dns_name" {
  description = "DNS of Loadbalancer"
  value       = module.alb.alb_dns_name
}
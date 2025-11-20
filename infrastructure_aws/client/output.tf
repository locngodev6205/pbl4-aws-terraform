# ------- listener Outputs -------

output "alb_web_dns_name" {
  value = module.alb.alb_web_dns_name
}
  
output "alb_zone_web_id" {
  value = module.alb.alb_zone_web_id
}

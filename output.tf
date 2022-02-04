output "external_ip_address_bal" {
  value = one(one(yandex_lb_network_load_balancer.bal.listener).external_address_spec).address
}

output "external_ip_address_vm1" {
  value = module.vm1.external_ip_address_vm
}

output "external_ip_address_vm2" {
  value = module.vm2.external_ip_address_vm
}
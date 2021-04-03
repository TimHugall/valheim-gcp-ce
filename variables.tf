variable "ssh_source_cidr" {

}

variable "hosted_zone_name" {

}

variable "use_route53" {
  default = false
}

variable "server_name" {
  default = "my_server"
}

variable "world_name" {
  default = "Dedicated"
}

variable "server_password" {
  sensitive = true
}

variable "region" {
  default = "australia-southeast1"
}
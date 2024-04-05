variable "group_name" {
  description = "Akamai group to use this resource in"
  type        = string
  default     = "group-1"
}

variable "hostname" {
  description = "Name of the hostname but also user for property and edgehostname"
  type        = string
}

variable "origin_hostname" {
  description = "Name of you origin hostname"
  type        = string
}

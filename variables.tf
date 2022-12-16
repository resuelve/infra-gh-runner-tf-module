// Required values to be set in terraform.tfvars
variable "project" {
  description = "The project in which to hold the components"
  type        = string
}

variable "region" {
  description = "The region in which to create the VPC network"
  type        = string
}

variable "zone" {
  description = "Zone of the machine from the gh-runner"
}

variable "network_name" {
  description = "The name of network"
  type        = string
}

variable "subnetwork_name" {
  description = "The name of subnetwork"
  type        = string
}

variable "subnetwork_range" {
  description = "The number range of the subnetwork"
  type        = string
}

variable "ssh_iap_range" {
  description = "The number range of the iap"
  type        = string
}

variable "vm_name_prefix" {
  description = "Name of the vm"
  type        = string
}

variable "vm_machine_type" {
  description = "Type of machine from the gh-runner"
}

variable "image_os" {
  description = "Is the version of OS of the VM to gh-runners"
}

variable "disk_type" {
  description = "Type of disk to VM"
}

variable "disk_size" {
  description = "Size of disk to VM"
}

variable "label_business" {
  description = "label_business"
}

variable "label_project" {
  description = "label_project"
}

variable "label_environment" {
  description = "label_environment"
}

variable "label_owner" {
  description = "label_owner"
}

variable "label_datadog" {
  description = "label_datadog"
}

variable "label_gh_actions" {
  description = "label_gh_actions"
}

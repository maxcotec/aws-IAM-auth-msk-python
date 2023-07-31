variable "account_id" {
  type        = string
  description = "The AWS Account ID this Terraform is being run against"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "namespace" {
  type        = string
  description = "Project namespace"
  default     = "bar"
}

variable "stage" {
  type        = string
  description = "AWS account"
}

variable "name" {
  type        = string
  description = "Unique name for resources. Keep it short (~4 chars) to aviod long-resource name exception."
}

variable "kafka_cluster_name" {
  type        = string
  description = "kafka cluster name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}
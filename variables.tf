variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
#  default     = "ami-0502e817a62226e03" 
}
variable "subnets" {
    type = list
    default = ["10.20.1.0/24", "10.20.10.0/24"]
}

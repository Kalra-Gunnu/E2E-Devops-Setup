variable "repositories" {
  type = list(string)
  default = ["g5-slabai-payment-service","g5-slabai-project-service","g5-slabai-user-service","g5-slabai-frontend"]
}

variable "image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "tags" { 
    type = map(string)
    default = {} 
}
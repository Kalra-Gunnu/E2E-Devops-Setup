variable "repositories" {
  type = list(string)
  default = ["g5-slabai-payment","g5-slabai-project","g5-slabai-user","g5-slabai-frontend"]
}

variable "image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "tags" { 
    type = map(string)
    default = {} 
}
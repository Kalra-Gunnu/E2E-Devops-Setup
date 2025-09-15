variable "repositories" {
  type = list(string)
  default = ["slabai_payment","slabai_project","slabai_user","slabai_frontend"]
}

variable "image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "tags" { 
    type = map(string)
    default = {} 
}
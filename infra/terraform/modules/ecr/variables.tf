variable "repositories" {
  type = list(string)
  default = ["g5_slabai_payment","g5_slabai_project","g5_slabai_user","g5_slabai_frontend"]
}

variable "image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "tags" { 
    type = map(string)
    default = {} 
}
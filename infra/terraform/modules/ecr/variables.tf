variable "repositories" {
  type = list(string)
  default = ["payment","project","user","frontend"]
}

variable "image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "tags" { 
    type = map(string)
    default = {} 
}
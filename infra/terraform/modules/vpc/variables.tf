variable "name" { 
    type = string
}

variable "cidr_block" { 
    type = string 
    default = "10.0.0.0/16" 
}

variable "azs" { 
    type = list(string)
    default = [] 
}

variable "public_subnet_count" { 
    type = number 
    default = 2 
}

variable "private_subnet_count" { 
    type = number
    default = 2
}

variable "tags" {
    type = map(string)
    default = {} 
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
}
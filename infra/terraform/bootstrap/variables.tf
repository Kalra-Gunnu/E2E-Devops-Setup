variable "aws_region" { 
    type = string 
}

variable "aws_profile" { 
    type = string
    default = "" 
}

variable "tfstate_bucket" { 
    type = string 
}

variable "tfstate_lock_table" { 
    type = string 
}

variable "tags" { 
    type = map(string)
    default = {} 
}

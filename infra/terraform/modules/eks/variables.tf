variable "cluster_name" { 
    type = string 
}

variable "cluster_version" { 
    type = string
    default = "1.33"
}

variable "vpc_id" { 
    type = string 
}

variable "private_subnet_ids" { 
    type = list(string) 
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "environment" { 
    type = string
    default = "dev" 
}

variable "tags" { 
    type = map(string) 
    default = {} 
}

variable "eks_managed_node_groups" {
  description = "Configuration map for EKS managed node groups."
  type        = map(any)
  default = {
    general_purpose = {
      # Instance sizing
      min_size     = 2
      max_size     = 7
      desired_size = 4

      # Instance type
      instance_types = ["t3.small"]

      # Optional: Add custom tags to nodes
      tags = {
        "NodeType" = "general-purpose"
      }
    }
  }
}


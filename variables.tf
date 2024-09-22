################################################################################
# Variables used with the terraform template
################################################################################

variable "key_name" {
    type = string
    default = "terraform_key"
    description = "The name of the key pair to be used"
}

variable "public_key" {
    type = string
    default = "<YOUR_PUBLIC_KEY>"
    description = "The name of the key pair to be used"
}

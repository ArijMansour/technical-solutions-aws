provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.copy_region
  alias  = "copy_region"
}
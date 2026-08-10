# ==========VPC==========
env        = "dev"
vpc_name   = "yrpark-test-vpc"
vpc_cidr   = "10.0.0.0/16"

subnet_newbits = 8
subnet_azs = ["a", "c", "b"]

subnet_lists = {
  "pub-nat" = [0, 1]
  "pri-app" = [2, 3]
  "pri-eks" = [4, 5]
  "pri-db"  = [6, 7, 8]
}

nat = {
  create = true
  subnet = "pub-nat"
  per_az = true
}

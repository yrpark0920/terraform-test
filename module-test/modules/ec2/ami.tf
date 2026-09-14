data "aws_ami" "ubuntu_2404" {
    most_recent = true 
    owners = ["099720109477"] # Canonical 공식 계정 지정

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  # AL2023 x86_64(64bit) 기본 AMI 검색 패턴
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"] 
  }
}

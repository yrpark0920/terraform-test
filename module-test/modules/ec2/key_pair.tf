## 키 생성
resource "tls_private_key" "this" {
    algorithm = "RSA"
}

## 키페어 생성
resource "aws_key_pair" "this" {
    key_name = "${var.key_pair_name}-key-pair"
    public_key = tls_private_key.this.public_key_openssh
}

## 개인키를 PC에 저장
resource "local_file" "this" {
    content = tls_private_key.this.private_key_pem
    filename = "${path.module}/${var.key_pair_name}.pem"
}
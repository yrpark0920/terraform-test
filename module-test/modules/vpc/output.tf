output "vpc_id" {
    description = "생성한 VPC의 ID 출력"
    value = aws_vpc.this.id
}

output "subnet_id" {
    description = "생성한 모든 서브넷의 ID"
    value = {
        for k,v in aws_subnet.this : k => v.id
    }
}
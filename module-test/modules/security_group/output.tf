output "sg_id" {
    description = "생성된 보안 그룹 ID"
    value = aws_security_group.this.id
}
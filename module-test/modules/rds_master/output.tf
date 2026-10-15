output "identifier" {
  description = "생성한 RDS의 Identifier"
  value = aws_db_instance.master.identifier
}
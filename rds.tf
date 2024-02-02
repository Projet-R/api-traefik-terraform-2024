# Création d'une instance RDS MySQL
resource "aws_db_instance" "rds_main" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  db_name              = "mydb"
  username             = "user"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot  = true
}

# Création d'un groupe de sous-réseaux pour l'instance RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "my_db_2_subnet_group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

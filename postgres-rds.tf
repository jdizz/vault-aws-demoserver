resource "aws_db_subnet_group" "postgres" {
  name       = "main"
  subnet_ids = ["${aws_subnet.public_subnet.id}"]

  tags = {
    Name = "Postgres DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.5"
  instance_class       = "db.t2.micro"
  name                 = "proddb"
  username             = "dbadmin"
  password             = "!4me2know!"
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.vault.id]
  db_subnet_group_name = aws_db_subnet_group.postgres.subnet_ids
}
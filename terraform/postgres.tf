// POSTGRES Subnet Group
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name        = "postgres-subnet-group"
  description = "Subnet group for PostgreSQL"
  subnet_ids  = module.vpc.public_subnets
  tags = {
    Name = "postgres-subnet-group"
  }
}

// POSTGRES Security Group
resource "aws_security_group" "postgres_sg" {
  name        = "postgres_sg"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# POSTGRES Instance
resource "aws_db_instance" "postgres" {
  identifier        = "shodapp-postgres"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "16.3"
  instance_class    = "db.t4g.micro"
  #name                 = "postgres"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres16"
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  tags = {
    Name = "postgres"
  }
}
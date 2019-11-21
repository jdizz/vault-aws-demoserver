resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.namespace}-${random_pet.env.id}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vault" {
  ami           = "data.aws_ami.ubuntu.id"
  instance_type = "t2.medium"
  count         = "1"
  subnet_id     = "aws_subnet.public_subnet.id"
  key_name      = "jdavis-aws"

  security_groups = [
    "aws_security_group.vault.id"
  ]

  associate_public_ip_address = "true"
  ebs_optimized               = "false"
  iam_instance_profile        = "aws_iam_instance_profile.vault-kms-unseal.id"

  tags = {
    Name = "${var.namespace}-${random_pet.env.id}"
  }

  user_data = "data.template_file.vault.rendered"
}

data "template_file" "vault" {
  
  template = file("userdata.tpl")

  vars = {
    kms_key    = "aws_kms_key.vault.id"
    vault_url  = "var.vault_url"
    aws_region = "var.aws_region"
    vault_db_address = "aws_db_instance.vault.address"
    db_address = "aws_db_instance.proddb.address"
    proddb_username = "var.proddb_username"
    proddb_password = "var.proddb_password"
    vaultdb_username = "var.vaultdb_username"
    vaultdb_password = "var.vaultdb_password"
  }
}

data "template_file" "format_ssh" {
  template = "Connect to host with following command: ssh ubuntu@$${admin} -i private.key"

  vars = {
    admin = "aws_instance.vault[0].public_ip"
  }
}



resource "aws_security_group" "vault" {
  name        = "${var.namespace}-${random_pet.env.id}"
  description = "vault access"
  vpc_id      = "aws_vpc.vpc.id"

  tags = {
    Name = "${var.namespace}-${random_pet.env.id}"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NGINX
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # POSTGRES
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault Client Traffic
  ingress {
    from_port   = 8200
    to_port     = 8200
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

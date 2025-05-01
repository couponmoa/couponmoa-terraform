// ec2
resource "aws_instance" "elasticsearch" {
  ami                         = var.ubuntu_ami_id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.private_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.elasticsearch_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  user_data = file("scripts/install-elasticsearch.sh")

  tags = {
    Name = "elasticsearch-node"
  }
}
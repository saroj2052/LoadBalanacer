data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

}

resource "tls_private_key" "ec2-key" {
  algorithm   = "RSA"
}
resource "aws_key_pair" "ec2-instance-key" {
  key_name   = "ec2-key"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "local_file" "ec2-key" {
    content     = tls_private_key.ec2-key.private_key_pem
    filename = "ec2-key.pem"
}
resource "aws_security_group" "ec2-sg" {
  name        = "ec2-sg"
  description = "EC2 sg "
# #   vpc_id      = aws_vpc.myvpc.id

#   ingress {
#     description      = "for users outsider"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = []
#   }
  ingress {
    description      = "for administrartor"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  key_name = "ec2-key"
  security_groups = toset([aws_security_group.ec2-sg.name])
  iam_instance_profile = aws_iam_instance_profile.s3-iam-role-instance-profile.name


  tags = {
    Name = "ec2-saroj"
  }
}
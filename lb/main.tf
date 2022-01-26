resource "aws_instance" "base" {
  ami                    = "ami-08e4e35cccc6189f4"
  instance_type          = "t2.micro"
  count                  = 2
  key_name               = "skey"
  # subnets            = [data.aws_subnet_ids.subnet_id.ids]
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  user_data              = <<-EOF
  #!/bin/bash
  yum install httpd -y
  echo "hey, i am $(hostname -f)" > /var/www/html/index.html
  service httpd start
  chkconfig httpd on

  EOF

  tags = {
    Name = "HelloWorld-${count.index}"
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "skey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0Fh/9e1V6meD9hKaJH6WfQr/e1Gy90WYAbOy7gLn7SHmuaEiq1LUn9uZCjC6TWB2zX7BHagxlPuDGVTF2h7betxN5lcgjomDvMR2BsHdJi+ytgGmh5S4MHMNFNUedgzkn6/E4te+KuNkKL7YP/oa+4ClY6w9dFZLkzu3MP5QPyeIQlEb0AWn84b7AmmTHTH2MKPtGxRujzrhQWzXUsp0JCIhHyzrmD8/r2p2q3BGflYSNxqXIsO3AMF+7WFerUuW3iI02Az+l92aww8gv9/IoH1fMvz6ScRa13o69GEjmfu9IWFdAU8VcuOOrfQQxI+wVPxO6ECWy8lnsQwpyq1xl saroj@saroj-Inspiron-3576"
}

resource "aws_eip" "lb" {
  #   instance = aws_instance.web.id
  count    = length(aws_instance.base)
  vpc      = true
  instance = "${element(aws_instance.base.*.id, count.index)}"
  tags = {
    Name = "saroj-eip${count.index + 1}"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

data "aws_subnet_ids" "subnet_id" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_lb_target_group" "my-tg" {

  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name     = "my-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb" "test" {
  name               = "test-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_tls.id]
  subnets            = data.aws_subnet_ids.subnet_id.ids
  ip_address_type    = "ipv4"
  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-tg.arn
  }
}
resource "aws_lb_target_group_attachment" "my-tg-attatch" {
  count            = length(aws_instance.base)
  target_group_arn = aws_lb_target_group.my-tg.arn
  target_id        = aws_instance.base[count.index].id
  port             = 80
}
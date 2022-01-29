provider "aws" {
  region = "ap-southeast-1"
}

### AMI/OS ###
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"] # Canonical
}

### EC2 ### 
resource "aws_iam_role" "test_role" {
  name = "ssm_test_role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": {
"Effect": "Allow",
"Principal": {"Service": "ec2.amazonaws.com"},
"Action": "sts:AssumeRole"
}
}
EOF
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name
}

resource "aws_instance" "ec2_instance" {
  user_data = file("install_site.sh")
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = "subnet-d369c08a"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  tags = {
    Name = "new-ec2-instance-1-tf"
  }
}

resource "aws_instance" "ec2_instance_2" {
  user_data = file("install_site.sh")
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id = "subnet-4e03f128"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  tags = {
    Name = "new-ec2-instance-2-tf"
  }
}

## Load Balancer ##
resource "aws_lb_target_group" "test" {
  name        = "tf-example-lb-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = "vpc-1e787179"
}

resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.ec2_instance_2.id
  port             = 443
}

resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.ec2_instance.id
  port             = 443
}

resource "aws_lb" "public_lb" {
  name                       = "test-lb-tf"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_ports.id]
  subnets                    = ["subnet-d369c08a", "subnet-4e03f128", "subnet-a5fa18ed"]
  ip_address_type            = "ipv4"
  drop_invalid_header_fields = true
  enable_deletion_protection = false #False if for testing

  tags = {
    Environment = "production"
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}


resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.public_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

### Security Group ###
resource "aws_security_group" "allow_ports" {
  name        = "allow_ports"
  description = "Allow ports 80, 443"

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ports"
  }
}
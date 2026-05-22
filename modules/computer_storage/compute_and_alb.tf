# Fetch latest Amazon Linux 2023 AMI dynamically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 1. Security Group for ALB (Allows internet traffic in)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# 2. Security Group for EC2 (Only allows traffic originating from the ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-private-security-group"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Application Load Balancer
resource "aws_lb" "external_alb" {
  name               = "web-architecture-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

# 4. ALB Target Group
resource "aws_lb_target_group" "alb_tg" {
  name     = "asg-web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# 5. ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# 6. EC2 Launch Template (with Nginx Installation script)
resource "aws_launch_template" "web_template" {
  name_prefix   = "nginx-launch-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              # Create a custom landing page showing the unique hostname to verify balancing works
              echo "<h1>Hello from Web Server running on $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 7. Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name_prefix         = "web-asg-"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  force_delete          = true
  health_check_type     = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}
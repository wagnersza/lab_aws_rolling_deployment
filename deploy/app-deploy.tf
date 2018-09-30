provider "aws" {
  region     = "us-east-1"
}

data "aws_ami" "flask_app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["flask-example*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["637541989224"]
}

resource "aws_launch_configuration" "flask_app_lc" {
  image_id      = "${data.aws_ami.flask_app_ami.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.flask_app_websg.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "flask_app_asg" {
  name                 = "terraform-asg-flask-app-${aws_launch_configuration.flask_app_lc.name}"
  launch_configuration = "${aws_launch_configuration.flask_app_lc.name}"
  availability_zones = ["${data.aws_availability_zones.allzones.names}"]
  min_size             = 1
  max_size             = 2

  load_balancers = ["${aws_elb.elb1.id}"]
  health_check_type = "ELB"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "flask_app_websg" {
  name = "security_group_for_flask_app_websg"
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elbsg" {
  name = "security_group_for_elb"
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "allzones" {}

resource "aws_elb" "elb1" {
  name = "terraform-elb-flask-app"
  availability_zones = ["${data.aws_availability_zones.allzones.names}"]
  security_groups = ["${aws_security_group.elbsg.id}"]

  listener {
    instance_port = 5000
    instance_protocol = "http"
    lb_port = 5000
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:5000/health"
      interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "terraform - elb - flask-app"
  }
}

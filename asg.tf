resource "aws_launch_template" "asg" {
  name                      = "${var.COMPONENT}-${var.ENV}-template"
  image_id                  = data.aws_ami.ami.id
  instance_type             = var.INSTANCE_TYPE
  vpc_security_group_ids    = [aws_security_group.allow-component.id]
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.COMPONENT}-${var.ENV}-asg"
  max_size                  = var.ASG_MAX_INSTANCES
  min_size                  = 1
  desired_capacity          = 1
  force_delete              = true
  launch_template {
    id                      = aws_launch_template.asg.id
    version                 = "$Latest"
  }
  vpc_zone_identifier       = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS
  target_group_arns         = [aws_lb_target_group.tg.arn]

  tag {
    key                     = "Name"
    value                   = "${var.COMPONENT}-${var.ENV}"
    propagate_at_launch     = true
  }

}

resource "aws_autoscaling_policy" "bat" {
  name                      = "cpu-based"
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = "120"
  autoscaling_group_name    = aws_autoscaling_group.asg.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value            = var.ASG_LOAD_AVERAGE
  }
}

resource "aws_lb_target_group" "tg" {
  name                      = "${var.COMPONENT}-${var.ENV}-tg"
  port                      = var.PORT
  protocol                  = "HTTP"
  vpc_id                    = data.terraform_remote_state.vpc.outputs.VPC_ID
  health_check {
    path                    = var.HEALTH
  }
}

resource "aws_security_group" "allow-component" {
  name                      = "allow-${var.COMPONENT}-${var.ENV}-sg"
  description               = "allow-${var.COMPONENT}-${var.ENV}-sg"
  vpc_id                    = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description             = "SSH"
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    cidr_blocks             = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description             = "PROMETHEUS"
    from_port               = 9100
    to_port                 = 9100
    protocol                = "tcp"
    cidr_blocks             = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }

  ingress {
    description             = "HTTP"
    from_port               = var.PORT
    to_port                 = var.PORT
    protocol                = "tcp"
    cidr_blocks             = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port               = 0
    to_port                 = 0
    protocol                = "-1"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  tags                      = {
    Name                    = "allow-${var.COMPONENT}-${var.ENV}-sg"
  }
}
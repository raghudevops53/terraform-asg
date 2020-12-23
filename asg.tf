resource "aws_launch_template" "asg" {
  name                    = "${var.COMPONENT}-${var.ENV}"
  image_id                = data.aws_ami.ami.id
  instance_type           = var.INSTANCE_TYPE
}

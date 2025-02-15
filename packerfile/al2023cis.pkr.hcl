packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "REGION_ID" {
  type    = string
  default = "us-east-1"
}

variable "SECURITY_GROUP_ID" {
  type    = string
}

variable "SUBNET_ID" {
  type    = string
}

variable "VPC_ID" {
  type    = string
}

variable "PLAYBOOK" {
  type    = string
}

variable "AMI" {
  type    = string
}

variable "BUILDNUM" {
  type    = string
}

variable "INSTANCE_PROFILE" {
  type    = string
}

variable "PROJECT" {
  type    = string
}

data "amazon-ami" "source-ami" {
  filters = {
    name         = "${var.AMI}*"
    architecture = "x86_64"
  }
  most_recent = true
  owners      = ["137112412989"]
  region      = "${var.REGION_ID}"
}


# The "legacy_isotime" function has been provided for backwards compatability, but we recommend switching to the timestamp and formatdate functions.
source "amazon-ebs" "instance" {
  ami_name             = "${var.PROJECT}-build_num_${var.BUILDNUM}-${formatdate("YYYYMMDD",timestamp())}"
  communicator         = "ssh"
  iam_instance_profile = "${var.INSTANCE_PROFILE}"
  instance_type        = "t3.medium"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    volume_size           = 10
    volume_type           = "gp3"
  }
  region            = "${var.REGION_ID}"
  security_group_id = "${var.SECURITY_GROUP_ID}"
  source_ami        = "${data.amazon-ami.source-ami.id}"
  ssh_interface     = "private_ip"
  ssh_username      = "ec2-user"
  subnet_id         = "${var.SUBNET_ID}"
  run_tags = {
    packer = "${var.PROJECT}-buildnum-${var.BUILDNUM}"
  }
  tags = {
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
  }
  vpc_id         = "${var.VPC_ID}"
  aws_polling {
    delay_seconds = 60
    max_attempts  = 120
  }
}

build {
  name    = var.PROJECT
  sources = ["source.amazon-ebs.instance"]

  provisioner "ansible" {
    playbook_file   = "../playbooks/logicworks/al2023.yml"
    user            = "ec2-user"
    use_proxy       = false
  }

  provisioner "ansible" {
    playbook_file   = "${var.PLAYBOOK}"
    user            = "ec2-user"
    use_proxy       = false
    extra_arguments = [
      "--extra-vars",
      "@extra_vars_${var.PROJECT}.yml",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
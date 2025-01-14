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
    inspec = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/inspec"
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

variable "BUILDNUM" {
  type    = string
}

variable "INSTANCE_PROFILE" {
  type    = string
}

variable "PROJECT" {
  type    = string
}

variable "AMI_ID" {
  type    = string
}


# The "legacy_isotime" function has been provided for backwards compatability, but we recommend switching to the timestamp and formatdate functions.
source "amazon-ebs" "instance" {
  ami_name             = "INSPEC-${var.PROJECT}-build_num_${var.BUILDNUM}-${formatdate("YYYYMMDD",timestamp())}"
  communicator         = "winrm"
  iam_instance_profile = "${var.INSTANCE_PROFILE}"
  instance_type        = "m6a.xlarge"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 75
    volume_type           = "gp3"
  }
  region            = "${var.REGION_ID}"
  security_group_id = "${var.SECURITY_GROUP_ID}"
  skip_create_ami   = true
  source_ami        = "${var.AMI_ID}"
  ssh_interface     = "private_ip"
  subnet_id         = "${var.SUBNET_ID}"
  run_tags = {
    packer = "${var.PROJECT}-buildnum-${var.BUILDNUM}"
  }
  tags = {
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
  }
  user_data_file = "../scripts/packer-bootstrap.ps1"
  vpc_id         = "${var.VPC_ID}"
  winrm_insecure = true
  winrm_use_ssl  = true
  winrm_username = "Administrator"
  aws_polling {
    delay_seconds = 60
    max_attempts  = 120
  }
}

build {
  name    = var.PROJECT
  sources = ["source.amazon-ebs.instance"]

  provisioner "shell-local" {
    scripts = ["../scripts/inspector.sh"]
  }

  provisioner "shell-local" {
    inline = [
      "inspec exec https://github.com/dev-sec/windows-baseline/tree/2.1.7 -t winrm://${build.Host} --user 'Administrator' --password \"${build.Password}\" --chef-license=accept --reporter junit:results.xml --self-signed --ssl || true"
    ]
  }



}
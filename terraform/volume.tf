# Create EBS volumes and attach them to EC2 instances
resource "aws_volume_attachment" "ebs_attachment_data_plane" {
  count = 3
  device_name = "/dev/sdh" # Customize the device name as needed
  volume_id   = aws_ebs_volume.ebs_volume_k8s_computer[count.index].id
  instance_id = aws_instance.data_plane[count.index].id
}

resource "aws_volume_attachment" "ebs_attachment_control_plane" {
  device_name = "/dev/sdh" # Customize the device name as needed
  volume_id   = aws_ebs_volume.ebs_volume_k8s_computer[3].id
  instance_id = aws_instance.control_plane_1.id
}

resource "aws_volume_attachment" "ebs_attachment_master_ansible" {
  device_name = "/dev/sdh" # Customize the device name as needed
  volume_id   = aws_ebs_volume.ebs_volume_master_ansible.id
  instance_id = aws_instance.master_ansible.id
}

resource "aws_ebs_volume" "ebs_volume_k8s_computer" {
  count = 4
  availability_zone = "us-east-1a" # Customize as needed
  size              = 100
  tags = {
    Name = "EBS_Volume_${count.index + 1}"
  }
}

resource "aws_ebs_volume" "ebs_volume_master_ansible" {
  availability_zone = "us-east-1a" # Customize as needed
  size              = 50
  tags = {
    Name = "EBS_Volume_5"
  }
}



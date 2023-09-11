resource "aws_instance" "master_ansible" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.subnet1.id
  private_ip    = "10.240.0.4"

  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.http_sg.id]
  key_name               = aws_key_pair.my_key_pair.key_name # Use the key pair you created

  user_data = <<-EOF
              #!/bin/bash
              echo 'ssh-rsa YOUR_PUBLIC_KEY' >> /home/ec2-user/.ssh/authorized_keys
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
              sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
              sudo apt update
              sudo apt install -y python3-pip
              sudo apt install -y ansible
              sudo apt install -y git
              EOF

  tags = {
    Name = "master-ansible"
  }
}

resource "aws_instance" "control_plane_1" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.subnet1.id
  private_ip    = "10.240.0.5"

  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.http_sg.id]

  key_name = aws_key_pair.my_key_pair.key_name # Use the key pair you created

  user_data = <<-EOF
              #!/bin/bash
              echo 'ssh-rsa YOUR_PUBLIC_KEY' >> /home/ec2-user/.ssh/authorized_keys
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
              EOF

  tags = {
    Name = "control-plane-1"
  }
}

resource "aws_instance" "data_plane" {
  count         = 3
  ami           = "ami-053b0d53c279acc90"
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.subnet1.id
  private_ip    = "10.240.0.${count.index + 6}"

  key_name = aws_key_pair.my_key_pair.key_name # Use the key pair you created

  user_data = <<-EOF
              #!/bin/bash
              echo 'ssh-rsa YOUR_PUBLIC_KEY' >> /home/ec2-user/.ssh/authorized_keys
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
              EOF

  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.http_sg.id]

  tags = {
    Name = "data-plane-${count.index + 1}"
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
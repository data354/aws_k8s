
# Create a VPC
resource "aws_vpc" "k8s_network" {
  cidr_block = "10.240.0.0/24" # Replace with your desired CIDR block
}

# Create two subnets in the VPC (one for each availability zone)
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.k8s_network.id
  cidr_block              = "10.240.0.0/24" # Replace with your desired CIDR block
  availability_zone       = "us-east-1a"    # Replace with your desired availability zone
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.k8s_network.id
}

resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create security groups
resource "aws_security_group" "ssh_sg" {
  name        = "SSH_SG"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.k8s_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This allows SSH access from anywhere, restrict as needed
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This allows SSH access from anywhere, restrict as needed
  }
}

resource "aws_security_group" "http_sg" {
  name        = "HTTP_SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.k8s_network.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This allows HTTP access from anywhere, restrict as needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip_association" "eip_assoc_master_ansible" {
  instance_id   = aws_instance.master_ansible.id
  allocation_id = aws_eip.ipquery_master_ansible.id
}

resource "aws_eip_association" "eip_assoc_data_plane" {
  count = 3
  instance_id   = aws_instance.data_plane[count.index].id
  allocation_id = aws_eip.ipquery_data_plane[count.index].id
}

resource "aws_eip_association" "eip_assoc_control_plane" {
  instance_id   = aws_instance.control_plane_1.id
  allocation_id = aws_eip.ipquery_control_plane.id
}

resource "aws_eip" "ipquery_master_ansible" {}
resource "aws_eip" "ipquery_control_plane" {}
resource "aws_eip" "ipquery_data_plane" {
  count = 3
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.k8s_network.id
}

provider "aws" {
  secret_key =  ""
  access_key =  ""
  region = "us-east-1"
}
resource "aws_instance" "web" {
  ami = "ami-1df65f0b"
  count = 3
  instance_type = "t1.micro"
  tags {
    Name = "duy-testing"
  }
}

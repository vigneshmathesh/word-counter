output "public_ip" {
  value = aws_instance.wc_ec2.public_ip
  description = "Public IP of the Word Counter"
}

output "url" {
  value = "http://${aws_instance.wc_ec2.public_ip}"
  description = "Open this in your browser"
}

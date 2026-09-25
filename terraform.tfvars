aws_region         = "us-east-1"
environment        = "dev"

cluster_name       = "secure-cicd-cluster"

node_count         = 2
node_instance_type = "t3.micro"

vpc_cidr = "10.0.0.0/16"

app_name = "my-app"
app_port = 3000

project_name = "secure-cicd"
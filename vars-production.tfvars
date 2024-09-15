# Variable declarations

# Sample apply/destroy command
# terraform apply -var-file="vars-production.tfvars" -state="terraform-production.tfstate"
# terraform destroy -var-file="vars-production.tfvars" -state="terraform-production.tfstate"

aws_access_key = ""
aws_access_token = ""
aws_region = ""
aws_availability_zone = ""
aws_vpc_id = ""
aws_subnet_id = ""
agent_instance_type = "t3.micro"

acorns_environment = ["production"]
cpln_org = "acorns-production"
cpln_locations = ["aws-us-east-2"]
cpln_token = ""
cpln_gvc = "proxy"

external_apex_domain = "acorns.io"
external_domain = "graphql-internal.acorns.io"

proxy_fqdn = "graphql-internal.acorns.io"
firewall_external_inbound_allow_cidr = ["34.46.93.248", "34.71.20.115", "35.197.211.153", "35.242.171.149"]

min_scale = 1
max_scale = 3
suspend = false
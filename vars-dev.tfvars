# Variable declarations

# Sample apply/destroy command
# terraform apply -var-file="vars-dev.tfvars" -state="terraform-dev.tfstate"
# terraform destroy -var-file="vars-dev.tfvars" -state="terraform-dev.tfstate"

aws_access_key = ""
aws_access_token = ""
aws_region = ""
aws_availability_zone = ""
aws_vpc_id = ""
aws_subnet_id = ""
agent_instance_type = "t3.micro"

acorns_environment = ["dev"]
cpln_org = "acorns-dev"
cpln_locations = ["aws-us-east-2"]
cpln_token = ""
cpln_gvc = "proxy"

external_apex_domain = "acorns.io"
external_domain = "controlplane.dev.acorns.io"

proxy_fqdn = "graphql-internal.staging.acorns.io"
firewall_external_inbound_allow_cidr = ["104.198.30.251", "34.171.160.92", "35.246.9.137"]

min_scale = 1
max_scale = 3
suspend = false

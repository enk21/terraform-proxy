# Variable declarations

# Sample apply/destroy command
# terraform apply -var-file="vars-preproduction.tfvars" -state="terraform-preproduction.tfstate"
# terraform destroy -var-file="vars-preproduction.tfvars" -state="terraform-preproduction.tfstate"

aws_access_key = ""
aws_access_token = ""
aws_region = ""
aws_availability_zone = ""
aws_vpc_id = ""
aws_subnet_id = ""
agent_instance_type = "t3.micro"

acorns_environment = ["preproduction"]
cpln_org = "acorns-preproduction"
cpln_locations = ["aws-us-east-2"]
cpln_token = ""
cpln_gvc = "proxy"

external_apex_domain = "acorns.io"
external_domain = "controlplane.preproduction.acorns.io"

proxy_fqdn = ""
firewall_external_inbound_allow_cidr = []

min_scale = 1
max_scale = 3
suspend = false
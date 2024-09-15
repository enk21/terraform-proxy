terraform {
  required_providers {
    cpln = {
      # https://registry.terraform.io/providers/controlplane-com/cpln/latest
      source = "controlplane-com/cpln"
      # Install the latest version of the Terraform Provider
      # version = "~> 1"
    }

    aws = {
      # AWS provider
      source = "hashicorp/aws"
      # Optional: specify version
      # version = "~> 5.0"
    }
  }
}

variable "aws_access_key" {
  type = string
}

variable "aws_access_token" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_availability_zone" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

variable "agent_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "acorns_environment" {
  type = list(string)
}

variable "cpln_org" {
  type = string
}

variable "cpln_locations" {
  type = list(string)
}

variable "cpln_token" {
  type = string
}

variable "cpln_gvc" {
  type = string
}

variable "external_apex_domain" {
  type    = string
  default = "acorns.io"
}

variable "external_domain" {
  type = string
}

variable "proxy_fqdn" {
  type = string
}

variable "firewall_external_inbound_allow_cidr" {
  type = list(string)
}

variable "min_scale" {
  type    = number
  default = 1
}

variable "max_scale" {
  type    = number
  default = 3
}

variable "suspend" {
  type = bool
}

provider "cpln" {
  org   = var.cpln_org
  token = var.cpln_token
}

# Configure the AWS Provider
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_access_token
}

resource "cpln_agent" "acorns-aws-01-agent-resource" {
  name        = "acorns-aws-01"
  description = "acorns-aws-01"
}

module "aws_agent" {
  source = "./aws"

  vpc_id              = var.aws_vpc_id
  subnet_id           = var.aws_subnet_id
  agent_instance_type = var.agent_instance_type
  user_data           = cpln_agent.acorns-aws-01-agent-resource.user_data

  create_security_group = true
  security_group_id     = ""
}

module "aws_agent_production_passive" {
  source     = "./aws"
  count      = contains(var.acorns_environment, "production") ? 1 : 0
  depends_on = [module.aws_agent]

  vpc_id              = var.aws_vpc_id
  subnet_id           = var.aws_subnet_id
  agent_instance_type = var.agent_instance_type
  user_data           = cpln_agent.acorns-aws-01-agent-resource.user_data

  create_security_group = false
  security_group_id     = module.aws_agent.security_group_id
}

resource "cpln_secret" "acorns-proxy-nginx-conf-secret-resource" {
  name        = "acorns-proxy-nginx-conf"
  description = "acorns-proxy-nginx-conf"

  opaque {
    encoding = "plain"
    payload  = <<EOT
events { }

http {
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    server {
        listen 8080;

        location /graphql { 
            proxy_pass https://${var.proxy_fqdn}/;
            proxy_set_header Host graphql-internal.staging.acorns.io; 
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;  

            # SSL settings to handle HTTPS backend
            proxy_ssl_server_name on;
            proxy_ssl_verify off;  

            # Timeout settings
            proxy_connect_timeout 10s;
            proxy_send_timeout 20s;
            proxy_read_timeout 20s;

            # Ensure proper handling of protocol upgrade
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Keep-Alive "timeout=5, max=100";

            proxy_buffering on;
            proxy_buffers 16 4k;
            proxy_buffer_size 2k;
        
            gzip on;
            gzip_proxied any;
            gzip_types text/plain application/xml application/json;
        }
    }
}
EOT
  }
}

resource "cpln_gvc" "proxy-gvc-resource" {
  name        = var.cpln_gvc
  description = var.cpln_gvc
  locations   = var.cpln_locations
}

resource "cpln_identity" "proxy-acorns-identity-identity-resource" {
  name        = "acorns-identity"
  description = "acorns-identity"
  gvc         = cpln_gvc.proxy-gvc-resource.name

  network_resource {
    name       = "graphql-acorns-io"
    agent_link = cpln_agent.acorns-aws-01-agent-resource.self_link
    fqdn       = var.proxy_fqdn
    ports      = [443]
  }
}

resource "cpln_policy" "acorns-proxy-nginx-conf-policy-resource" {
  name        = "acorns-proxy-nginx-conf"
  description = "acorns-proxy-nginx-conf"
  target_kind = "secret"

  binding {
    permissions     = ["reveal"]
    principal_links = [cpln_identity.proxy-acorns-identity-identity-resource.self_link]
  }

  target_links = [cpln_secret.acorns-proxy-nginx-conf-secret-resource.name]
}

resource "cpln_workload" "proxy-acorns-proxy-workload-resource" {
  name                 = "acorns-proxy"
  description          = "acorns-proxy"
  gvc                  = "proxy"
  type                 = "serverless"
  support_dynamic_tags = false

  container {
    name       = "nginx"
    image      = "/org/${var.cpln_org}/image/nginx:1.27.0-alpine-slim"
    cpu        = "2"
    memory     = "1Gi"
    min_cpu    = "200m"
    min_memory = "256Mi"

    ports {
      number   = 8080
      protocol = "http"
    }

    volume {
      uri  = "cpln://secret/${cpln_secret.acorns-proxy-nginx-conf-secret-resource.name}"
      path = "/etc/nginx/nginx.conf"
    }
  }

  options {
    timeout_seconds = 60
    capacity_ai     = true
    suspend         = var.suspend

    autoscaling {
      metric              = "concurrency"
      target              = 100
      min_scale           = var.min_scale
      max_scale           = var.max_scale
      scale_to_zero_delay = 300
      max_concurrency     = 1000
    }
  }

  firewall_spec {
    external {
      inbound_allow_cidr  = var.firewall_external_inbound_allow_cidr
      outbound_allow_cidr = ["0.0.0.0/0"]
    }
    internal {
      inbound_allow_type = "none"
    }
  }

  identity_link = cpln_identity.proxy-acorns-identity-identity-resource.self_link
}

# resource "cpln_domain" "apex-domain" {

#   count = contains(var.acorns_environment, "production") ? 1 : 0

#   name        = var.external_apex_domain
#   description = var.external_apex_domain
#   spec {
#     dns_mode = "cname"
#     ports {
#       number   = 443
#       protocol = "http2"
#       tls {
#       }
#     }
#   }
# }

# resource "cpln_domain" "controlplane-acorns-io-domain-resource" {
#   name        = var.external_domain
#   description = var.external_domain
#   spec {
#     dns_mode = "cname"
#     ports {
#       number   = 443
#       protocol = "http2"
#       tls {
#       }
#     }
#   }
# }

# resource "cpln_domain_route" "route-0-domain-resource" {
#   depends_on    = [cpln_domain.controlplane-acorns-io-domain-resource]
#   domain_link   = cpln_domain.controlplane-acorns-io-domain-resource.self_link
#   domain_port   = 443
#   workload_link = cpln_workload.proxy-acorns-proxy-workload-resource.self_link
#   prefix        = "/graphql"
# }

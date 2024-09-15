# Control Plane - Acorns Proxy

Tested using Terraform `v1.9.5`.

This example project uses Terraform to deploy the proxy project to Control Plane.

As part of the `main.tf` HCL, there is an AWS module that manages the Control Plane agent, which is deployed as an EC2 instance within a private VPC to allow the internal endpoint to be called.

There are four environments and their cooresponding variable file:

- **dev**
  - `vars-dev.tfvar`
- **staging**
  - `vars-staging.tfvar`
- **preproduction**
  - `vars-preproduction.tfvar`
- **production**
  - `var-production.tfvar`

Each variable file requires the values to be entered that target the specific environment.

The `cpln_token` is a service account key that can be created using the Control Plane console UI. Initally, the service account can be added to the `super_users` group. Once the Terraform works as expected, the service account can be removed from that group, and
specific policies will be created with the minimum permissions.

**NOTE:** When targeting **production**:

1. The apex domain resource will be configured.
2. Another Control Plane agent will be installed (as an EC2 instance) acting as a
   passive instance.

This example will use a local state file for each environment
to store the Terraform state. Update each of the `*.tf` files to configure a different
state file target.

Below are example Terraform commands to deploy the project.

1. To initialize, run `terraform init`

2. Use the following command to target a specific environment:

- **dev**
  - `terraform apply -var-file="vars-dev.tfvars" -state="terraform-dev.tfstate"`
- **staging**
  - `terraform apply -var-file="vars-staging.tfvars" -state="terraform-staging.tfstate"`
- **preproduction**
  - `terraform apply -var-file="vars-preproduction.tfvars" -state="terraform-preproduction.tfstate"`
- **production**
  - `terraform apply -var-file="vars-production.tfvars" -state="terraform-production.tfstate"`

**NOTE**:
Terraform workspaces can be used instead of the above commands.

To initialize the workspaces, run the following:

```
terraform workspace new dev
terraform workspace new staging
terraform workspace new preproduction
terraform workspace new production
```

To apply a specific environment, first switch to the workspace then run the command.
For example:

```
terraform workspace select dev
terraform apply -var-file="vars-dev.tfvars"
```

**NOTE:** Regarding domains:

- The domain resources are currently commented out as to not affect the currently deployed domains. We can add resources to update DNS as necessary.

- The apex domain is configured within the production org at Control Plane. This requires
  a TXT record be added to DNS before applying the Terrafrom. This is already done and will only need to be updated if we change orgs within Control Plane.

- The subdomains that route to the proxy workload for each environment
  are CNAME records. This CNAME is based on the GVC alias. Currently, it is configured
  with the CNAME for the existing deployment. Any destruction / creation of the project
  might required the CNAME to be updated at DNS.

**NOTE:** AWS Policies:

The IAM user configured must have the following policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:RebootInstances",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeInstances",
                "ec2:DescribeImages",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstanceAttribute",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DescribeSecurityGroups",
                "ec2:ModifySecurityGroupRules",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*"
        }
    ]
}

```

# Shodapp Kubernetes Infrastructure

This repository contains the Terraform configuration files for setting up the infrastructure of the Shodapp project on AWS. The infrastructure includes an EKS cluster, PostgreSQL database, ACM certificates, Route 53 DNS records, and ArgoCD for continuous deployment.

This Terraform configuration is used to deploy the infrastructure on a CloudGuru sandbox account. It uses cross-account access to perform ACM validation and create the CNAME and A records for the ALB in a personal AWS account that hosts the domain.

Sensitive data such as AWS credentials, database passwords, and API keys are managed using GitHub repository secrets. If you fork this repository, make sure to update these secrets in your forked repository to match your environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Terraform Files](#terraform-files)
  - [main.tf](#maintf)
  - [route53_acm.tf](#route53-acmtf)
  - [postgres.tf](#postgrestf)
  - [outputs.tf](#outputstf)
  - [iam.tf](#iamtf)
  - [argocd.tf](#argocdtf)
  - [helm.tf](#helmtf)
  - [eks.tf](#ekstf)
  - [variables.tf](#variablestf)
- [GitHub Actions Workflows](#github-actions-workflows)
  - [01-terraform-infrastructure.yml](#01-terraform-infrastructureyml)
  - [02-argocd-deploy.yml](#02-argocd-deployyml)

## Prerequisites

- Terraform v1.3.7 or later
- AWS CLI configured with access to both CloudGuru (sandbox) and personal AWS accounts
- GitHub repository secrets configured for AWS credentials and other sensitive information

## Setup Instructions

1. **Clone the repository:**
   ```sh
   git clone https://github.com/batzsalmassi/shodapp-k8s-infra.git
   cd shodapp-k8s-infra
   ```

2. **Initialize Terraform:**
   ```sh
   terraform init
   ```

3. **Plan the infrastructure changes:**
   ```sh
   terraform plan
   ```

4. **Apply the infrastructure changes:**
   ```sh
   terraform apply
   ```

## Terraform Files

### main.tf

This file contains the main configuration for the Terraform project, including provider configurations and the VPC module.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/main.tf
// ...existing code...
```

### route53_acm.tf

This file sets up the ACM certificate and Route 53 DNS records for domain validation and ALB configuration.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/route53_acm.tf
// ...existing code...
```

### postgres.tf

This file configures the PostgreSQL database instance, including subnet and security group settings.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/postgres.tf
// ...existing code...
```

### outputs.tf

This file defines the outputs for the Terraform project, such as the PostgreSQL endpoint and ACM certificate ARN.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/outputs.tf
// ...existing code...
```

### iam.tf

This file sets up the IAM roles and policies required for the EKS cluster and AWS Load Balancer Controller.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/iam.tf
// ...existing code...
```

### argocd.tf

This file configures the ArgoCD deployment using Helm and sets up the necessary Route 53 DNS records.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/argocd.tf
// ...existing code...
```

### helm.tf

This file configures the Helm provider and installs the AWS Load Balancer Controller using Helm.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/helm.tf
// ...existing code...
```

### eks.tf

This file sets up the EKS cluster, including managed node groups and Kubernetes resources.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/eks.tf
// ...existing code...
```

### variables.tf

This file defines the variables used in the Terraform project, such as AWS region, VPC CIDR, and EKS cluster settings.

```terraform
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/terraform/variables.tf
// ...existing code...
```

## GitHub Actions Workflows

### 01-terraform-infrastructure.yml

This workflow handles the Terraform plan and apply process, triggered by pull requests and pushes to the main branch.

```yaml
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/.github/workflows/01-terraform-infrastructure.yml
// ...existing code...
```

### 02-argocd-deploy.yml

This workflow deploys the ArgoCD application after the Terraform infrastructure has been successfully applied.

```yaml
// filepath: /Users/sean.salmassi/github-Repos/shodapp-k8s-infra/.github/workflows/02-argocd-deploy.yml
// ...existing code...
```
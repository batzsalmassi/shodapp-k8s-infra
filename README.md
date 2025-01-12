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

### route53_acm.tf

This file sets up the ACM certificate and Route 53 DNS records for domain validation and ALB configuration.

### postgres.tf

This file configures the PostgreSQL database instance, including subnet and security group settings.

### outputs.tf

This file defines the outputs for the Terraform project, such as the PostgreSQL endpoint and ACM certificate ARN.

### iam.tf

This file sets up the IAM roles and policies required for the EKS cluster and AWS Load Balancer Controller.

### argocd.tf

This file configures the ArgoCD deployment using Helm and sets up the necessary Route 53 DNS records.

### helm.tf

This file configures the Helm provider and installs the AWS Load Balancer Controller using Helm.

### eks.tf

This file sets up the EKS cluster, including managed node groups and Kubernetes resources.

### variables.tf

This file defines the variables used in the Terraform project, such as AWS region, VPC CIDR, and EKS cluster settings.

## GitHub Actions Workflows

### 01-terraform-infrastructure.yml

This workflow handles the Terraform plan and apply process, triggered by pull requests and pushes to the main branch.

### 02-argocd-deploy.yml

This workflow deploys the ArgoCD application after the Terraform infrastructure has been successfully applied.

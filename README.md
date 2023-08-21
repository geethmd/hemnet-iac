# User visit counter web application

This repo contains all the Terraform configurations required to create the AWS infrastructure for the web app. Below is the list of infrastructure components created under this project.

- EKS cluster
- GitHub repo
- Bootstrapping of EKS cluster with Flux (to support CI/CD functions of the web app)
- IAM role (which will use by an EKS service-account to scan a private ECR repo)

## Architecture Diagram

![Screenshot](screenshot.png)

## High Availability

To make sure the web app maintains high availability,

- EKS cluster is setup across 2 AZs
- EKS cluster is configured with an EKS-managed node group of min, max and desired node settings
- web app is deployed in 2 pods across 2 nodes (initial version)


## CICD

From a developer releasing a new version of the web app (docker image) to provisioning pods with the new version, all the steps are automated and managed by Flux. The Flux repository which contains the flux components as well as manifest files related to the pods, services and ingress can be found at https://github.com/geethmd/fluxcd.

## Log Management

Below log types are enabled at the EKS cluster with a CloudWatch log retention period of 7 days.
- audit
- api
- authenticator
- controllerManager
- scheduler

## web app

Please refer https://github.com/geethmd/hemnet-app for the web app. A GitActions workflow is in place to build the docker image and update it to a private ECR repo.

### Prerequisites

Below components are required to run the project locally,
- GitHub account
- GitHub token
- AWS account and ECR private repo
- Terraform

### Terraform Plan and Apply

- terraform plan -var "github_org=github-user-name" -var "github-token"
- terraform apply -var "github_org=github-user-name" -var "github-token"

### Install the web app components

After completing the Terraform installation, add all the yaml files inside https://github.com/geethmd/fluxcd -> clusters -> my-cluster -> manifest to the new GitHub repository created by Terraform.

Update ecrpolicy.yaml, ecrscan.yaml, imageupdateautomation.yaml and deployment.yaml files with your ECR url and docker tag pattern.


### Authors

Geeth Madhusha

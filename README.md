
# Secure CI/CD Pipeline for Kubernetes Deployment on AWS EKS

## Project Overview

This capstone project demonstrates the design and implementation of a secure, automated CI/CD pipeline for deploying a containerized web application to Amazon Elastic Kubernetes Service (EKS).

The pipeline automates application building, vulnerability scanning, container image publishing, and Kubernetes deployment whenever changes are pushed to the `main` branch of the GitHub repository.

The infrastructure is provisioned using Terraform, while GitHub Actions handles continuous integration and continuous deployment.

## Project Objectives

- Provision AWS infrastructure using Terraform.
- Containerize a Node.js application using Docker.
- Scan Docker images for vulnerabilities using Trivy.
- Store container images in Amazon Elastic Container Registry (ECR).
- Deploy the application to Amazon EKS using Kubernetes.
- Automate deployments using GitHub Actions.
- Implement secure AWS authentication using GitHub OIDC.
- Achieve zero-downtime rolling updates and Kubernetes self-healing.

## Technology Stack

| Technology | Purpose |
|---|---|
| AWS | Cloud infrastructure |
| Terraform | Infrastructure as Code |
| Amazon EKS | Managed Kubernetes |
| Amazon ECR | Container image registry |
| Docker | Application containerization |
| Kubernetes | Container orchestration |
| GitHub Actions | CI/CD automation |
| Trivy | Container vulnerability scanning |
| Node.js and Express | Application backend |
| Git and GitHub | Version control |

## Architecture

```text
Developer
    |
    | Git push to main
    v
GitHub Repository
    |
    v
GitHub Actions Workflow
    |
    +--> Checkout Source Code
    |
    +--> Build Docker Image
    |
    +--> Trivy Security Scan
    |       |
    |       +--> Fail on HIGH/CRITICAL vulnerabilities
    |
    +--> Authenticate to AWS using OIDC
    |
    +--> Push Image to Amazon ECR
    |       |
    |       +--> Tag with Git Commit SHA
    |
    +--> Update Kubernetes Deployment
            |
            v
       Amazon EKS
            |
            v
     Kubernetes Service
            |
            v
       Web Application
```

## Project Structure

```text
secure-cicd-capstone/
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── secret.yaml
│
├── public/
│   └── index.html
│
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
├── server.js
├── package.json
├── package-lock.json
│
├── Dockerfile
├── .dockerignore
├── .gitignore
└── README.md
```

**Note:** Do not commit actual credentials, `.env` files, Terraform state files, or Kubernetes secrets containing sensitive values.

## Application Details

The application is built using Node.js and Express.

### Main endpoints

| Endpoint | Description |
|---|---|
| `/` | Displays the application homepage |
| `/health` | Returns the application's health status |

The application runs on port `3000`.

Example health response:

```json
{
  "status": "healthy"
}
```

Kubernetes uses the `/health` endpoint for readiness and liveness probes.

## Infrastructure Provisioning

Terraform provisions the AWS infrastructure required for the application.

### Infrastructure components

- Amazon VPC with public and private subnets.
- Internet Gateway and NAT Gateway for network connectivity.
- Security groups for network access control.
- Amazon EKS cluster.
- EKS managed worker node group.
- Amazon ECR repository for container images.

### Configuration

The project uses the following configuration:

| Parameter | Value |
|---|---|
| AWS Region | us-east-1 |
| EKS Cluster | secure-cicd-cluster |
| ECR Repository | my-app |
| Environment | dev |
| Worker Node Count | 2 |
| Node Instance Type | t3.medium |
| Application Port | 3000 |

These values can be adjusted in `variables.tf` and `terraform.tfvars`.

### Deploy infrastructure

Configure the AWS CLI:

```bash
aws configure
```

Initialize Terraform:

```bash
terraform init
```

Format and validate the configuration:

```bash
terraform fmt
terraform validate
```

Review the infrastructure plan:

```bash
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

Confirm the operation when prompted.

## Docker Containerization

The application is packaged into a Docker image using the Dockerfile.

### Build the image

```bash
docker build -t my-app:1.0.0 .
```

Verify the image:

```bash
docker images
```

### Run the container locally

```bash
docker run -d \
  --name my-app-container \
  -p 3000:3000 \
  my-app:1.0.0
```

Test the application:

```text
http://localhost:3000
http://localhost:3000/health
```

Stop the container:

```bash
docker stop my-app-container
docker rm my-app-container
```

## Amazon ECR Configuration

Amazon ECR stores the Docker images used by the EKS cluster.

Create the repository if it does not already exist:

```bash
aws ecr create-repository \
  --repository-name my-app \
  --region us-east-1
```

Get the AWS account ID:

```bash
aws sts get-caller-identity \
  --query Account \
  --output text
```

Authenticate Docker to ECR:

```bash
aws ecr get-login-password \
  --region us-east-1 | docker login \
  --username AWS \
  --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

Replace `ACCOUNT_ID` with the AWS account ID.

Tag the image:

```bash
docker tag my-app:1.0.0 \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-app:1.0.0
```

Push the image:

```bash
docker push \
  ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-app:1.0.0
```

In the automated pipeline, GitHub Actions builds and pushes images tagged with the Git commit SHA.

## Connecting to Amazon EKS

Configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name secure-cicd-cluster
```

Verify the cluster connection:

```bash
kubectl cluster-info
kubectl get nodes
```

Check the running workloads:

```bash
kubectl get pods -A
```

The IAM identity used for access must have the required EKS and Kubernetes permissions.

## Kubernetes Deployment

The application is deployed using Kubernetes manifests in the `k8s/` directory.

### Deployment configuration

The Kubernetes Deployment is configured with:

- Two application replicas.
- Rolling updates.
- Readiness and liveness probes.
- CPU and memory resource requests and limits.
- ConfigMap and Secret environment variables.

The rolling update strategy uses:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```

This configuration allows Kubernetes to create a replacement pod before removing an existing available pod, subject to the readiness checks and available cluster resources.

### Apply Kubernetes resources

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Check the deployment:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Wait for the rollout:

```bash
kubectl rollout status deployment/my-app
```

The Service exposes port `80` and forwards traffic to container port `3000`.

The AWS LoadBalancer provides external access once it has been provisioned and assigned an address.

## GitHub Actions CI/CD Pipeline

The workflow is located at:

`.github/workflows/deploy.yml`

It is triggered when code is pushed to the `main` branch.

### Pipeline stages

1. Check out the source code.
2. Authenticate to AWS using GitHub OIDC.
3. Log in to Amazon ECR.
4. Build the Docker image.
5. Scan the image using Trivy.
6. Stop the pipeline if HIGH or CRITICAL vulnerabilities are detected.
7. Push the image to Amazon ECR using the Git commit SHA as its tag.
8. Configure kubectl to connect to EKS.
9. Deploy the new image to Kubernetes.
10. Verify the rollout status.

### GitHub repository secret

Configure the following GitHub Actions secret:

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | ARN of the IAM role assumed by GitHub Actions |

Navigate to:

GitHub Repository → Settings → Secrets and variables → Actions → New repository secret.

The secret value should be the ARN of the dedicated GitHub Actions IAM role.

AWS authentication uses OpenID Connect (OIDC) rather than long-lived AWS access keys.

The IAM role's trust policy should restrict access to the intended GitHub repository and branch.

The role must also have the necessary ECR permissions and EKS deployment authorization.

## Security Implementation

The project incorporates the following security controls:

| Security Control | Implementation |
|---|---|
| Container scanning | Trivy vulnerability scanning |
| AWS authentication | GitHub OIDC |
| Image traceability | Git commit SHA image tags |
| Secret management | GitHub Secrets and Kubernetes Secrets |
| Network security | AWS security groups and VPC |
| Container security | Non-root execution and restricted privileges |
| Deployment health | Kubernetes readiness and liveness probes |

Real credentials and API keys should never be committed to the repository.

For production environments, integrate AWS Secrets Manager or another managed secret solution and use a least-privilege IAM policy.

## Testing and Validation

The following tests can be used to validate the deployment.

### 1. Application health

```bash
kubectl get pods
kubectl get services
kubectl rollout status deployment/my-app
```

Verify that the pods are Ready and the rollout completes successfully.

### 2. Kubernetes self-healing

Delete an application pod:

```bash
kubectl delete pod POD_NAME
```

Replace `POD_NAME` with an actual pod name.

Verify that Kubernetes creates a replacement pod:

```bash
kubectl get pods -w
```

### 3. Rolling update

Push an application change to the `main` branch.

Monitor the deployment:

```bash
kubectl rollout status deployment/my-app
```

Verify the new image:

```bash
kubectl describe deployment my-app
```

### 4. CI/CD security validation

Confirm that the GitHub Actions workflow:

- Builds the application successfully.
- Scans the container image.
- Stops when configured vulnerability thresholds are exceeded.
- Pushes successful images to ECR.
- Deploys the correct image to EKS.

## Cleanup and Resource Deletion

AWS resources may incur charges, including EKS worker nodes, NAT Gateways, load balancers, and EBS volumes.

Before deleting infrastructure, remove Kubernetes resources created by the project:

```bash
kubectl delete -f k8s/
```

Then, from the Terraform directory:

```bash
terraform destroy
```

Review the destruction plan and confirm when prompted.

If Terraform reports that an Internet Gateway cannot be detached, check for remaining resources, network interfaces, or dependencies in the VPC before retrying.

Delete any remaining ECR images or repositories separately if they are no longer required.

## Conclusion

This capstone project demonstrates an automated and security-focused approach to deploying a containerized application on AWS.

By combining Terraform, Docker, Amazon ECR, Amazon EKS, Kubernetes, GitHub Actions, and Trivy, the project establishes a repeatable deployment workflow with automated image scanning, infrastructure provisioning, container orchestration, and rolling application updates.

The implementation provides a foundation for extending the deployment with managed secrets, HTTPS through AWS Load Balancer Controller and ACM, monitoring, logging, and production-grade access controls.

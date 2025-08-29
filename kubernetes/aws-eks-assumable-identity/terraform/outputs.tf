output "usage" {
  value = <<EOT
# Update kubeconfig
aws eks update-kubeconfig \
  --region=${var.region} \
  --name=${module.eks.cluster_name}

# Login to AWS ECR
aws ecr get-login-password --region ${var.region} \
  | docker login \
    --username AWS \
    --password-stdin "${aws_ecr_repository.pull_secret_updater.repository_url}"

# Build and push the image
docker buildx build ${abspath("${path.module}/..")} \
  --push \
  --platform=linux/amd64,linux/arm64 \
  -t ${aws_ecr_repository.pull_secret_updater.repository_url}

# Install the Helm chart
helm upgrade pull-secret-updater ${abspath("${path.module}/../helm")} \
  --namespace=pull-secret-updater \
  --install \
  --create-namespace \
  --set=image=${aws_ecr_repository.pull_secret_updater.repository_url} \
  --set=roleArn=${aws_iam_role.pull_secret_updater.arn} \
  --set=identity=${chainguard_identity.pull_secret_updater.id} \
  --set=orgName=${var.chainguard_org_name} \
  --set=imageName=${var.chainguard_image_name}
EOT
}

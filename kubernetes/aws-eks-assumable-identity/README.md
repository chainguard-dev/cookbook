# aws-eks-assumable-identity

This example demonstrates generating short-lived pull secrets in an AWS EKS
cluster for `cgr.dev` using the identity of an AWS IAM role.

It runs a `pull-secret-updater` job that uses an AWS IAM role to assume an
identity in the Chainguard platform, generate a token and then save it to pull
secrets across the cluster.

## AWS Role vs OIDC Issuer

Typically you would use the OIDC issuer of the Kubernetes cluster when using
assumable identities on Kubernetes, as described by
[this article](https://edu.chainguard.dev/chainguard/administration/assumable-ids/identity-examples/kubernetes-identity/).

However, the issuer URL for each AWS EKS cluster is a unique value with a random
ID:

```
https://oidc.eks.us-west-2.amazonaws.com/id/E6E3BED54BXXXXXXXXXXXXXXXXXXXXX
```

This means you would need to register each of your clusters with Chainguard
individually.

Whereas, you can use the same AWS IAM role across multiple AWS EKS clusters in
the same account, with one binding in the Chainguard platform.

```json
{
  "awsIdentity": {
    "aws_account": "<account-id>",
    "arnPattern": "^arn:aws:sts::<account-id>:assumed-role/pull-secret-updater/(.*)$",
    "userIdPattern": "^AROA(.*):(.*)$"
  }
}

```

## Requirements

- `aws`
- `docker`
- `helm`
- `kubectl`
- `terraform`

## Usage

Use the provided Terraform module to deploy an AWS EKS cluster and set up the
required resources in the Chainguard platform.

```
cd terraform/

cat <<EOF > terraform.tfvars
# Required. A name for the cluster and associated resources.
cluster_name = "your-name"

# Required. Your Chainguard organization.
chainguard_org_name = "your.org"

# Required. The name of an image in your organization. The test workload will
# pull the :latest-dev tag of this image. 
chainguard_image_name = "python"
EOF

aws sso login
terraform init
terraform apply -var-file terraform.tfvars
```

The `usage` output will describe the commands you need to run next to deploy the
rest of the example.

```
terraform output usage
```

Once the chart has been deployed. You should be able to see that the
`pull-secret-updater` has created the pull secrets.

```
kubectl -n pull-secret-updater logs job/pull-secret-updater
```

And the pod from the `test-workload` deployment should have started
successfully and been able to pull an image from your organization with the
generated pull secret.

```
kubectl -n pull-secret-updater get pods -l app=test-workload
```

## How it Works

This is effectively what the Terraform module and the other commands are doing.

Firstly, we create an AWS role called `pull-secret-updater` and configure
it so that it can be assumed by the `pull-secret-updater` service account in the
AWS EKS cluster.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pull-secret-updater
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/pull-secret-updater
```

Then, we configure an assumable identity in the Chainguard platform which can be
assumed by pods using the role. The identity has the `registry.pull` role.

This is what the equivalent `chainctl` command would look like:

```shell
cat > id.json <<EOF
{
  "awsIdentity": {
    "aws_account": "<account-id>",
    "arnPattern": "^arn:aws:sts::<account-id>:assumed-role/pull-secret-updater/(.*)$",
    "userIdPattern": "^AROA(.*):(.*)$"
  }
}
EOF

chainctl iam id create pull-secret-updater \
    -f id.json \
    --role=registry.pull
```

We then run a scheduled `CronJob` that:

1. Assumes the Chainguard identity, using the AWS role.
2. Generates a short-lived token for `cgr.dev`.
3. Writes the token into pull secrets across every namespace in the cluster.

Workloads in those clusters can now use those pull secrets to pull images from
`cgr.dev`.

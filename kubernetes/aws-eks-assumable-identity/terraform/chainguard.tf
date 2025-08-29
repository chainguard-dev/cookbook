data "chainguard_group" "parent" {
  name = var.chainguard_org_name
}

data "chainguard_role" "puller" {
  name = "registry.pull"
}

resource "chainguard_identity" "pull_secret_updater" {
  parent_id   = data.chainguard_group.parent.id
  name        = "${var.cluster_name}-pull-secret-updater"
  description = "Identity for AWS Assumable Identities demo on EKS."

  aws_identity {
    aws_account         = data.aws_caller_identity.current.account_id
    aws_user_id_pattern = "^AROA(.*):(.*)$"
    aws_arn_pattern     = "^arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.pull_secret_updater.name}/(.*)$"
  }
}

resource "chainguard_rolebinding" "pull_secret_updater_puller" {
  identity = chainguard_identity.pull_secret_updater.id
  role     = data.chainguard_role.puller.items[0].id
  group    = data.chainguard_group.parent.id
}

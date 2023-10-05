################################################################################
# Create IAM role and instance profile w/ SSM and Secrets Manager access policies
################################################################################

################################################################################
# Define AssumeRole access for EC2
################################################################################
data "aws_iam_policy_document" "instance_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


################################################################################
# Define AssumeRole access for CC callhome trust feature
################################################################################
data "aws_iam_policy_document" "cc_callhome_policy_document" {
  version = "2012-10-17"
  statement {
    sid       = "AllowDelegationForCallhome"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::223544365242:role/callhome-delegation-role"]
  }
}


################################################################################
# Create IAM Policy for CC callhome
################################################################################
resource "aws_iam_policy" "cc_callhome_policy" {
  count       = var.byo_iam == false && var.cc_callhome_enabled ? var.iam_count : 0
  description = "Policy which allows STS AssumeRole when attached to a user or role. Used for CC callhome"
  name        = "${var.name_prefix}-cc-${count.index + 1}-callhome-policy-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc_callhome_policy_document.json
}

# Attach CC callhome policy to CC IAM Role

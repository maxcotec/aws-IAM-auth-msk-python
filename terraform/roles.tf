provider "aws" {
  alias  = "ireland"
  region = var.region
}

data "aws_msk_cluster" "msk_cluster" {
  cluster_name = var.kafka_cluster_name
}

locals {
  kafka_cluster_name     = data.aws_msk_cluster.msk_cluster.cluster_name
  read_only_topic        = "test-topic"
  read_consumer_group    = "reader-group"
}

########################################################################
# IAM role for to read from IAM-enabled kafka cluster
########################################################################
resource "aws_iam_policy" "read_kafka_topic" {
  name        = "${data.aws_msk_cluster.msk_cluster.cluster_name}-read-only"
  description = "Policy to read from specific kafka topics"
  policy      = data.aws_iam_policy_document.read_kafka_topic_policy_document.json
}

data "aws_iam_policy_document" "read_kafka_topic_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:ReadData",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeTransactionalId",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
      "kafka-cluster:Connect"
    ]
    resources = [
      "arn:aws:kafka:${var.region}:${var.account_id}:cluster/${local.kafka_cluster_name}/*",
      "arn:aws:kafka:${var.region}:${var.account_id}:topic/${local.kafka_cluster_name}/*/${local.read_only_topic}",
      "arn:aws:kafka:${var.region}:${var.account_id}:group/${local.kafka_cluster_name}/*/${local.read_consumer_group}*",
      "arn:aws:kafka:${var.region}:${var.account_id}:transactional-id/${local.kafka_cluster_name}/*/*",
    ]
  }
}

data "aws_iam_policy_document" "read_assume_policy" {
  // trust relationship, such that this role can be assumed from EC2 instances.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "read_role" {
  name               = "${local.kafka_cluster_name}-read-role"
  assume_role_policy = data.aws_iam_policy_document.read_assume_policy.json
  tags               = module.label.tags
}

resource "aws_iam_role_policy_attachment" "read_policy_attachment" {
  role       = aws_iam_role.read_role.name
  policy_arn = aws_iam_policy.read_kafka_topic.arn
}

resource "aws_iam_user" "read_user" {
  name = "${local.kafka_cluster_name}-read-user"
  tags = module.label.tags
}

resource "aws_iam_user_policy" "read_user_policy" {
  name   = "${local.kafka_cluster_name}-read-user-policy"
  user   = aws_iam_user.read_user.name
  policy = data.aws_iam_policy_document.read_kafka_topic_policy_document.json
}

########################################################################
# IAM role to read/write from IAM-enabled kafka cluster
########################################################################
resource "aws_iam_policy" "readwrite_kafka" {
  name        = "${data.aws_msk_cluster.msk_cluster.cluster_name}-read-write"
  description = "Policy to read & write from iam-enabled kafka (MSK) cluster"
  policy      = data.aws_iam_policy_document.read_write_kafka_policy_document.json
}

data "aws_iam_policy_document" "read_write_kafka_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:*"
    ]
    resources = [
      "arn:aws:kafka:${var.region}:${var.account_id}:cluster/${local.kafka_cluster_name}/*",
      "arn:aws:kafka:${var.region}:${var.account_id}:topic/${local.kafka_cluster_name}/*/*",
      "arn:aws:kafka:${var.region}:${var.account_id}:group/${local.kafka_cluster_name}/*/*",
      "arn:aws:kafka:${var.region}:${var.account_id}:transactional-id/${local.kafka_cluster_name}/*/*",
    ]
  }
}

data "aws_iam_policy_document" "readwrite_assume_policy" {
  // trust relationship, such that this role can be assumed from EC2 instances.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "read_write_role" {
  name               = "${local.kafka_cluster_name}-read-write-role"
  assume_role_policy = data.aws_iam_policy_document.readwrite_assume_policy.json
  tags               = module.label.tags
}

resource "aws_iam_role_policy_attachment" "read_write_policy_attachment" {
  role       = aws_iam_role.read_write_role.name
  policy_arn = aws_iam_policy.readwrite_kafka.arn
}

resource "aws_iam_user" "readwrite_user" {
  name = "${local.kafka_cluster_name}-read-write-user"
  tags = module.label.tags
}

resource "aws_iam_user_policy" "readwrite_user_policy" {
  name   = "${local.kafka_cluster_name}-read-write-user-policy"
  user   = aws_iam_user.readwrite_user.name
  policy = data.aws_iam_policy_document.read_write_kafka_policy_document.json
}
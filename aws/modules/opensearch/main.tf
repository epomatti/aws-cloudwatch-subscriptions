resource "aws_opensearchserverless_security_policy" "example" {
  name = "aos-prod-logs-secpol"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/prod-logs"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_collection" "prod_logs" {
  name = "prod-logs"
  depends_on = [
    aws_opensearchserverless_security_policy.example,
    aws_opensearchserverless_access_policy.test
  ]
}

data "aws_partition" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_opensearchserverless_access_policy" "test" {
  name = "prod-access"
  type = "data"
  policy = jsonencode([
    {
      "Rules" : [
        {
          "ResourceType" : "collection",
          "Resource" : [
            "collection/prod-logs",
          ],
          "Permission" : [
            "aoss:*",
          ]
        }
      ],
      "Principal" : [
        "arn:aws:iam::${local.aws_account_id}:user/Evandro"
      ]
    }
  ])
}

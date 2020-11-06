resource "aws_subnet" "public_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = format("public_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = format("private_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_eip" "eip" {
  vpc      = true

  tags = {
    Name = format("eip_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = format("nat_gw_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_route_table" "nat_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = format("nat_route_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_route_table" "igw_route" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = format("igw_route_%s", var.tag_owner)
    owner = var.tag_owner
  }
}

resource "aws_route_table_association" "private_subnet" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.nat_route.id
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.igw_route.id
}

resource "aws_security_group" "lambda_security_group" {
  name        = format("lambda_%s", var.tag_owner)
  description = "Security group for lambda"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_dynamodb_table" "dynamodb" {
  name           = format("%s_lambda_db", var.tag_owner)
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "N"
  }

  tags = {
    Name = format("dynamodb_%s", var.tag_owner)
    owner = var.tag_owner
  }
}
resource "aws_ses_email_identity" "blevk_email" {
  email = "blevk@softserveinc.com"
}
resource "aws_iam_role" "iam_for_lambda" {
  name = format("%s_lambda_role", var.tag_owner)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = format("%s_dynamodb_policy", var.tag_owner)
  role = aws_iam_role.iam_for_lambda.id
  policy = <<EOF
{  
  "Version": "2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Action": [
     "dynamodb:BatchGetItem",
     "dynamodb:GetItem",
     "dynamodb:Query",
     "dynamodb:Scan",
     "dynamodb:BatchWriteItem",
     "dynamodb:PutItem",
     "dynamodb:UpdateItem",
     "dynamodb:DescribeTable"
    ],
    "Resource": "${aws_dynamodb_table.dynamodb.arn}"
   }
  ]
}
EOF
}
resource "aws_iam_role_policy" "lambda_ses_and_ec2_policy" {
  name = format("%s_ec2_and_ses_policy", var.tag_owner)
  role = aws_iam_role.iam_for_lambda.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
/* resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.function.output_path
  function_name = "blevk_function" #or var.function_name if i could create lambda
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "exports.test"
  timeout = 10

   vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  } 

  source_code_hash = filebase64sha256(data.archive_file.function.output_path)

  runtime = var.runtime

  environment {
    variables = {
      foo = "bar"
    }
  }
} */
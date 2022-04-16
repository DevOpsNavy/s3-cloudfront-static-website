#AWS user ID
data "aws_caller_identity" "current" {}

locals {
  tags = {
    Environment = "${var.Environment}"
    Application = "${var.Application}"
  }
}

#-----------------------------------------------------------------------------------------------
#S3 bucket to host all website files.
#-----------------------------------------------------------------------------------------------

resource "random_id" "bucket_append" {
  keepers = {
    ami_id = "${var.resource_uid}"
  }
  byte_length = 8
}

resource "aws_s3_bucket" "website_files" {
  bucket        = lower("${var.resource_uid}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_append.id}")
  force_destroy = "true"
  tags          = local.tags
}

# Private S3 bucket preferred for security
resource "aws_s3_bucket_acl" "website_files" {
  bucket = aws_s3_bucket.website_files.id
  acl    = "private"
}

# Versioning enabled to allow recovery of accidentally over written files
resource "aws_s3_bucket_versioning" "website_files" {
  bucket = aws_s3_bucket.website_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

#-----------------------------------------------------------------------------------------------
# Create SSL Certificate, route53 records for validation and then validate the certificate
#-----------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "ssl_certificate" {
  provider = aws.useast1

  domain_name = var.domain_name

  # DNS validation requires the domain nameservers to already be pointing to AWS
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "ssl_certificate_validation" {
  provider = aws.useast1

  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# -----------------------------------------------------------------------------------------------
# Cloudfront distribution for main www.s3 site. HTTP requests automatically redirected to HTTPS.
# -----------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "${var.resource_uid}_OAI"
}

locals {
  origin_id = "${var.resource_uid}_origin_id"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  provider = aws.useast1

  origin {
    domain_name = aws_s3_bucket.website_files.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.resource_uid}-CloudfrontDistribution"
  default_root_object = "index.html"

  # Default cache behaviour
  default_cache_behavior {

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0 - takes priority over the Default cache behaviour
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    # TTL value for the period of time that a packet/data should exist before being discarded.
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }

  }

  # Custom error messages
  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 403
    response_code         = 200
    response_page_path    = "/"
  }

  aliases = ["${var.domain_name}", "www.${var.domain_name}"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.ssl_certificate_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

}

#-----------------------------------------------------------------------------------------------
# Provide Permissions to allow the Cloudfront distribution to access the S3 bucket
#-----------------------------------------------------------------------------------------------
locals {

  cloudfront_website_bucket_access = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "CloudfrontAccess to Website Files",
    "Statement" : [
      {
        "Sid" : "1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.cloudfront_oai.id}"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.website_files.id}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "website_files" {

  bucket = aws_s3_bucket.website_files.id
  policy = local.cloudfront_website_bucket_access
}

resource "aws_route53_record" "root-a" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-a" {
  zone_id = var.hosted_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
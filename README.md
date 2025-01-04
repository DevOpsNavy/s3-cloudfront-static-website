# AWS S3 CloudFront Static Website Terraform Module

This module provisions the infrasructure required for a static website hosted on AWS S3 and CloudFront and optionally allows syncronisation of the website content with a local directory.

## Key Features

 -  [S3 Bucket](https://aws.amazon.com/s3/) to store website content.
 -  [CloudFront Distribution](https://aws.amazon.com/cloudfront/) to serve the website at edge locations at a low cost and high performance.
 -  [Route 53](https://aws.amazon.com/route53/) A records to utilise custom domain on website.
 -  Security First - S3 Bucket is private with IAM policies to provide permissions to CloudFront.
 -  Utilises `aws S3 sync` command to upload website content to S3 Bucket.

![image](https://raw.githubusercontent.com/DevOpsNavy/terraform-aws-s3-cloudfront-static-website/v0.0.0/diagrams/Architecture.drawio.png)

## Pre-quisites

 - Domain Name
 -  [Route 53 Hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html) which is the DNS provider for the domain. [Making Amazon Route 53 the DNS service for an existing domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html). Note: the hosted zone only needs to manage the DNS service, domain registration does not need to be migrated!
 - [A second aws provider configured in us-east-1](https://www.terraform.io/language/providers/configuration) as CloudFront and SSL certificates are only available in `us-east-1`.

For syncronisation of the website content with a local directory, the following is required:
 -  [AWS CLI](https://aws.amazon.com/cli/) installed locally - [installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
 -  [Configure a named profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) using `aws configure --profile NAME` command. This is used for the `aws s3 sync` command which is executed locally. Profiles are preferred over keys and secrets.


## Usage
[Example available here](https://github.com/DevOpsNavy/s3-cloudfront-static-website/tree/main/examples/static_website_with_sync)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.10.0"
    }
  }
}

# Default provider for resource creation
provider "aws" {
  region  = ""
  profile = ""
}

# Provider required in useast1 for cloudfront, SSLM Certificate
provider "aws" {
  alias   = "useast1"
  region  = "us-east-1"
  profile = ""
}

module "website" {
  source = "XXX"

  resource_uid   = "DevOpsNavy"
  domain_name    = "XXX"
  hosted_zone_id = "XXX"
  profile        = "XXX"

  sync_directories = [{
    local_source_directory = "./website_content"
    s3_target_directory    = ""
  }]

  providers = {
    aws.useast1 = aws.useast1
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.10.0 |
| <a name="provider_aws.useast1"></a> [aws.useast1](#provider\_aws.useast1) | 4.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.ssl_certificate](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.ssl_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.s3_distribution](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.cloudfront_oai](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/route53_record) | resource |
| [aws_route53_record.root-a](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/route53_record) | resource |
| [aws_route53_record.www-a](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/route53_record) | resource |
| [aws_s3_bucket.website_files](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.website_files](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_policy.website_files](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_versioning.website_files](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/resources/s3_bucket_versioning) | resource |
| [null_resource.sync_remote_website_content](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.website_content_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/4.10.0/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Application"></a> [Application](#input\_Application) | Environment to tag all resources created by this module | `string` | `"S3 Static Website"` | no |
| <a name="input_Environment"></a> [Environment](#input\_Environment) | Environment to tag all resources created by this module | `string` | `"Automation"` | no |
| <a name="input_bucket_versioning"></a> [bucket\_versioning](#input\_bucket\_versioning) | Enable bucket versioning | `bool` | `false` | no |
| <a name="input_cloudfront_geo_restriction_locations"></a> [cloudfront\_geo\_restriction\_locations](#input\_cloudfront\_geo\_restriction\_locations) | The ISO 3166-1-alpha-2 codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist). | `list(string)` | `[]` | no |
| <a name="input_cloudfront_geo_restriction_type"></a> [cloudfront\_geo\_restriction\_type](#input\_cloudfront\_geo\_restriction\_type) | The method that you want to use to restrict distribution of your content by country: none, whitelist, or blacklist. | `string` | `"none"` | no |
| <a name="input_cloudfront_minimum_protocol_version"></a> [cloudfront\_minimum\_protocol\_version](#input\_cloudfront\_minimum\_protocol\_version) | The minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections. | `string` | `"TLSv1.1_2016"` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | The price class for this distribution. One of PriceClass\_All, PriceClass\_200, PriceClass\_100 | `string` | `"PriceClass_200"` | no |
| <a name="input_cloudfront_ssl_support_method"></a> [cloudfront\_ssl\_support\_method](#input\_cloudfront\_ssl\_support\_method) | Specifies how you want CloudFront to serve HTTPS requests. One of vip or sni-only. | `string` | `"sni-only"` | no |
| <a name="input_default_cache_allowed_methods"></a> [default\_cache\_allowed\_methods](#input\_default\_cache\_allowed\_methods) | Controls which HTTP methods CloudFront processes and forwards to your Amazon S3 bucket or your custom origin. | `list(string)` | <pre>[<br>  "GET",<br>  "HEAD",<br>  "OPTIONS",<br>  "PUT",<br>  "POST",<br>  "PATCH",<br>  "DELETE"<br>]</pre> | no |
| <a name="input_default_cache_default_ttl"></a> [default\_cache\_default\_ttl](#input\_default\_cache\_default\_ttl) | The default amount of time (in seconds) that an object is in a CloudFront cache before CloudFront forwards another request in the absence of an Cache-Control max-age or Expires header. | `number` | `3600` | no |
| <a name="input_default_cache_forward_query_string"></a> [default\_cache\_forward\_query\_string](#input\_default\_cache\_forward\_query\_string) | Indicates whether you want CloudFront to forward query strings to the origin that is associated with this cache behavior. | `bool` | `false` | no |
| <a name="input_default_cache_max_ttl"></a> [default\_cache\_max\_ttl](#input\_default\_cache\_max\_ttl) | The maximum amount of time (in seconds) that an object is in a CloudFront cache before CloudFront forwards another request to your origin to determine whether the object has been updated. Only effective in the presence of Cache-Control max-age, Cache-Control s-maxage, and Expires headers | `number` | `86400` | no |
| <a name="input_default_cache_methods"></a> [default\_cache\_methods](#input\_default\_cache\_methods) | Controls whether CloudFront caches the response to requests using the specified HTTP methods. | `list(string)` | <pre>[<br>  "GET",<br>  "HEAD",<br>  "OPTIONS"<br>]</pre> | no |
| <a name="input_default_cache_min_ttl"></a> [default\_cache\_min\_ttl](#input\_default\_cache\_min\_ttl) | The minimum amount of time that you want objects to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated. | `number` | `0` | no |
| <a name="input_default_cache_viewer_protocol_policy"></a> [default\_cache\_viewer\_protocol\_policy](#input\_default\_cache\_viewer\_protocol\_policy) | Use this element to specify the protocol that users can use to access the files in the origin specified by TargetOriginId when a request matches the path pattern in PathPattern. One of allow-all, https-only, or redirect-to-https. | `string` | `"redirect-to-https"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The object that you want CloudFront to return (for example, `index.html`) when an end user requests the root URL. | `string` | `"index.html"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for the website. | `string` | n/a | yes |
| <a name="input_enable_cloudfront_distribution"></a> [enable\_cloudfront\_distribution](#input\_enable\_cloudfront\_distribution) | Whether the distribution is enabled to accept end user requests for content. | `bool` | `true` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | The Hosted Zone ID. This is automatically generated and can be referenced by zone records. | `string` | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | Credentials profile to use for `aws s3 sync command` | `string` | n/a | yes |
| <a name="input_resource_uid"></a> [resource\_uid](#input\_resource\_uid) | UID which will be prepended to resources created by this module | `string` | n/a | yes |
| <a name="input_sync_directories"></a> [sync\_directories](#input\_sync\_directories) | Directories to sync with S3 | <pre>list(object({<br>    local_source_directory = string<br>    s3_target_directory    = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | The ARN of the certificate |
| <a name="output_acm_certificate_domain_name"></a> [acm\_certificate\_domain\_name](#output\_acm\_certificate\_domain\_name) | The domain name for which the certificate is issued |
| <a name="output_acm_certificate_status"></a> [acm\_certificate\_status](#output\_acm\_certificate\_status) | Status of the certificate. |
| <a name="output_acm_certificate_validation_id"></a> [acm\_certificate\_validation\_id](#output\_acm\_certificate\_validation\_id) | The time at which the certificate was issued |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | The ARN (Amazon Resource Name) for the distribution. For example: `arn:aws:cloudfront::123456789012:distribution/EDFDVBD632BHDS5`, where 123456789012 is your AWS account ID. |
| <a name="output_cloudfront_distribution_caller_reference"></a> [cloudfront\_distribution\_caller\_reference](#output\_cloudfront\_distribution\_caller\_reference) | Internal value used by CloudFront to allow future updates to the distribution configuration. |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | The domain name corresponding to the distribution. For example: `d604721fxaaqy9.cloudfront.net`. |
| <a name="output_cloudfront_distribution_etag"></a> [cloudfront\_distribution\_etag](#output\_cloudfront\_distribution\_etag) | The current version of the distribution's information. For example: `E2QWRUHAPOMQZL`. |
| <a name="output_cloudfront_distribution_hosted_zone_id"></a> [cloudfront\_distribution\_hosted\_zone\_id](#output\_cloudfront\_distribution\_hosted\_zone\_id) | The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to. This attribute is simply an alias for the zone ID `Z2FDTNDATAQYW2`. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | The identifier for the distribution. For example: `EDFDVBD632BHDS5`. |
| <a name="output_cloudfront_distribution_in_progress_validation_batches"></a> [cloudfront\_distribution\_in\_progress\_validation\_batches](#output\_cloudfront\_distribution\_in\_progress\_validation\_batches) | The number of invalidation batches currently in progress. |
| <a name="output_cloudfront_distribution_last_modified_time"></a> [cloudfront\_distribution\_last\_modified\_time](#output\_cloudfront\_distribution\_last\_modified\_time) | The date and time the distribution was last modified. |
| <a name="output_cloudfront_distribution_status"></a> [cloudfront\_distribution\_status](#output\_cloudfront\_distribution\_status) | The current status of the distribution. Deployed if the distribution's information is fully propagated throughout the Amazon CloudFront system. |
| <a name="output_cloudfront_distribution_tags_all"></a> [cloudfront\_distribution\_tags\_all](#output\_cloudfront\_distribution\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider `default\_tags` configuration block. |
| <a name="output_cloudfront_distribution_trusted_key_groups"></a> [cloudfront\_distribution\_trusted\_key\_groups](#output\_cloudfront\_distribution\_trusted\_key\_groups) | List of nested attributes for active trusted key groups, if the distribution is set up to serve private content with signed URLs |
| <a name="output_cloudfront_distribution_trusted_signers"></a> [cloudfront\_distribution\_trusted\_signers](#output\_cloudfront\_distribution\_trusted\_signers) | List of nested attributes for active trusted signers, if the distribution is set up to serve private content with signed URLs |
| <a name="output_cloudfront_origin_access_identity_caller_reference"></a> [cloudfront\_origin\_access\_identity\_caller\_reference](#output\_cloudfront\_origin\_access\_identity\_caller\_reference) | Internal value used by CloudFront to allow future updates to the origin access identity. |
| <a name="output_cloudfront_origin_access_identity_cloudfront_access_identity_path"></a> [cloudfront\_origin\_access\_identity\_cloudfront\_access\_identity\_path](#output\_cloudfront\_origin\_access\_identity\_cloudfront\_access\_identity\_path) | A shortcut to the full path for the origin access identity to use in CloudFront, see below. |
| <a name="output_cloudfront_origin_access_identity_etag"></a> [cloudfront\_origin\_access\_identity\_etag](#output\_cloudfront\_origin\_access\_identity\_etag) | The current version of the origin access identity's information. For example: `E2QWRUHAPOMQZL`. |
| <a name="output_cloudfront_origin_access_identity_iam_arn"></a> [cloudfront\_origin\_access\_identity\_iam\_arn](#output\_cloudfront\_origin\_access\_identity\_iam\_arn) | A pre-generated ARN for use in S3 bucket policies (see below). Example: arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2QWRUHAPOMQZL. |
| <a name="output_cloudfront_origin_access_identity_id"></a> [cloudfront\_origin\_access\_identity\_id](#output\_cloudfront\_origin\_access\_identity\_id) | The identifier for the distribution. For example: `EDFDVBD632BHDS5`. |
| <a name="output_cloudfront_origin_access_identity_s3_canonical_user_id"></a> [cloudfront\_origin\_access\_identity\_s3\_canonical\_user\_id](#output\_cloudfront\_origin\_access\_identity\_s3\_canonical\_user\_id) | The Amazon S3 canonical user ID for the origin access identity, which you use when giving the origin access identity read permission to an object in Amazon S3. |
| <a name="output_route53_acm_certificate_validation_records"></a> [route53\_acm\_certificate\_validation\_records](#output\_route53\_acm\_certificate\_validation\_records) | Route 53 validation records for the ACM certificate. |
| <a name="output_route53_root_a_record_name"></a> [route53\_root\_a\_record\_name](#output\_route53\_root\_a\_record\_name) | The name of the root A record. |
| <a name="output_route53_root_www_record_name"></a> [route53\_root\_www\_record\_name](#output\_route53\_root\_www\_record\_name) | The name of the `www` A record. |
| <a name="output_s3_bucket_access_policy"></a> [s3\_bucket\_access\_policy](#output\_s3\_bucket\_access\_policy) | Bucket policy to allow CloudFront to access the S3 bucket. |
| <a name="output_s3_bucket_access_policy_json"></a> [s3\_bucket\_access\_policy\_json](#output\_s3\_bucket\_access\_policy\_json) | JSON bucket policy to allow CloudFront to access the S3 bucket. |
| <a name="output_s3_bucket_acl"></a> [s3\_bucket\_acl](#output\_s3\_bucket\_acl) | The ACL of the bucket. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The name of the bucket. |
| <a name="output_s3_bucket_region"></a> [s3\_bucket\_region](#output\_s3\_bucket\_region) | The AWS region this bucket resides in. |
| <a name="output_s3_bucket_versioning"></a> [s3\_bucket\_versioning](#output\_s3\_bucket\_versioning) | The bucket versioning status. |


Bug Reports & Feature Requests
Please use the issue tracker to report any bugs or file feature requests.

Developing
If you are interested in being a contributor and want to get involved in developing this project or help out with our other projects, we would love to hear from you! Shoot us an email.

In general, PRs are welcome. We follow the typical **"fork-and-pull"** Git workflow.

Fork the repo on GitHub
Clone the project to your own machine
Commit changes to your own branch
Push your work back up to your fork
Submit a Pull Request so that we can review your changes
NOTE: Be sure to merge the latest changes from **"upstream"** before making a pull request!

## To Do

To dos are documented in the [project associated](https://github.com/DevOpsNavy/s3-cloudfront-static-website/projects/1) with this repo.

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/DevOpsNavy/s3-cloudfront-static-website/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or with our other projects, we would love to hear from you! Shoot us an [email](mailto:Admin@devopsnavy.co.uk).

In general, PRs are welcome. We follow the typical **"fork-and-pull"** Git workflow.

 1. [**Fork**](https://github.com/InterweaveCloud/terraform-aws-s3-cloudfront-static-website/fork) the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from **"upstream"** before making a pull request!

## Contributors

| Name | Role |
|------|---------|
| [Faizan Raza](https://www.linkedin.com/in/faizan-raza-997808206/) | Lead Developer |
| [Vic Hassan](https://www.linkedin.com/in/vic-prince-hassan-619505171/) | Developer |


## Resources Used

[Terraform Docs](https://terraform-docs.io/) used for generating documentation.
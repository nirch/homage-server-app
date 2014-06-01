require 'aws-sdk'

aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "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"}
AWS.config(aws_config)
s3 = AWS::S3.new
HOMAGE_S3_BUCKET = s3.buckets['homageapp']
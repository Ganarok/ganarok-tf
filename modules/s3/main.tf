resource "aws_s3_bucket" "b" {
    bucket = "${var.bucket_name}-bucket"

    tags = {
        Name = "Bucket ${var.bucket_name}"
        Environment = "Production"
    }
}

resource "aws_s3_bucket_public_access_block" "b_access" {
    bucket = aws_s3_bucket.b.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = true
    restrict_public_buckets = false
}
require File.expand_path '../mongo_helper.rb', __FILE__
require File.expand_path '../aws_helper.rb', __FILE__

remake_id = BSON::ObjectId.from_string("5380834b0be044412f000039")
download_folder = "C:/Development/Homage/Remakes"

remake = PROD_REMAKES.find_one(remake_id)
#puts remake

remake_s3_prefix = "Remakes/" + remake["_id"].to_s
remake_s3_objects = S3_BUCKET.objects.with_prefix(remake_s3_prefix)
for reamake_s3_object in remake_s3_objects do
	puts remake_s3_object
end


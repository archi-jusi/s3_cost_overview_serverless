CREATE OR REPLACE VIEW s3_cost_and_bucket_info 
AS SELECT aws_account_number, bucket_name, aws_region, storage_class, metric_name, metric_value, a.line_item_resource_id, cost 

FROM s3_billing a, s3_storagelensbucket b
WHERE a.line_item_resource_id=b.bucket_name;

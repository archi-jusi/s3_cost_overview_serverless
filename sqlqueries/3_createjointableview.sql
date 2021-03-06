CREATE OR REPLACE VIEW globalview 
AS SELECT aws_account_number, bucket_name, aws_region, storage_class, metric_name, metric_value, a.line_item_resource_id, cost 
FROM cost_light a, lens_light b
WHERE a.line_item_resource_id=b.bucket_name;

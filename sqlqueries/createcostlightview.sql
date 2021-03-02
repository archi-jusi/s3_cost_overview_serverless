CREATE OR REPLACE VIEW S3_cost_explorer_light AS
SELECT line_item_product_code, line_item_resource_id, 
round(sum(line_item_blended_cost)) AS cost
FROM storagelensanalytic.costreport_daily_partition
WHERE MONTH = CAST(MONTH(CURRENT_DATE) AS varchar(4))
AND YEAR = CAST(YEAR(CURRENT_DATE) AS varchar(4))
AND line_item_product_code = 'AmazonS3'
GROUP BY  line_item_product_code, line_item_resource_id
ORDER BY  line_item_resource_id;

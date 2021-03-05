# replace the FROM with your databasename and table name for cost and usage report (variable costreportname from module )

CREATE OR REPLACE VIEW cost_light AS
SELECT line_item_product_code, line_item_resource_id, 
round(sum(line_item_unblended_cost)) AS cost
FROM storagelensanalytic.costreport_daily_partition
WHERE MONTH = CAST(MONTH(CURRENT_DATE) AS varchar(4))
AND YEAR = CAST(YEAR(CURRENT_DATE) AS varchar(4))
AND line_item_product_code = 'AmazonS3'
GROUP BY  line_item_product_code, line_item_resource_id
ORDER BY  line_item_resource_id;

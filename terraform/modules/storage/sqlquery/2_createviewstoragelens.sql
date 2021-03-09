CREATE OR REPLACE VIEW lens_light AS 
SELECT aws_account_number, bucket_name, aws_region, storage_class, metric_name, metric_value
from "${db}"."lensreports"
where record_type = 'BUCKET'
AND metric_name IN ( 'StorageBytes', 'ObjectCount' , 'ReplicatedStorageBytes', 'ReplicatedObjectCount', 'EncryptedStorageBytes', 'EncryptedObjectCount', 'CurrentVersionStorageBytes', 'CurrentVersionObjectCount', 'NonCurrentVersionStorageBytes', 'NonCurrentVersionObjectCount'  ); 

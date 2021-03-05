# s3_cost_overview_serverless
Tools to get cost and information for any bucket on AWS. 
All backend infrastructure has to be deployed with Terraform. 

## The challenge 

Find the most efficient way to get information about cost for each bucket in AWS.

The script or the tools will need to return these information : 

For each bucket:

• Name
• Creation date
• Number of files
• Total size of files
• Last modified date of the most recent file
• Type of storage
• Encryption type
• Extra like (life-cycle, cross-region replication, etc)
• **how much does it cost**


#### Display : 

- Ability to get the size results in bytes, kB, MB, ... 
- Ability to group buckets by regions
- Ability to group by encryption
- Ability to have full information as life cycle, cross-region replication, etc.
- Ability to get current and past version size in case of versioning

#### Filter:

- By bucket name
- By storage type (Standard, IA, RR).


## Requirement 

- Tools must work on each OS
- Easy to install and use 
- Fast and efficient, and simple
- Serverless if possible
- Infrastructure as to be deployed using Terraform

:warning: The tools need to still be efficient and get the result in seconds even with millions or billions of file.


### Architecture - evaluation of different solutions

The architecture step will be to evaluate the solution available and to analyse the pros and cons to see which direction will be the best to take.

1. Use aws CLI or boto3 and directly query S3 (S3 API get_objects_list_v2)
   This is the first solution everyone will think as it's the fastest and easiest way to implement but there is a lot of limitations. 
   The drawback is :
   - slow 
   - only get result of 1000 record in one run ( require pagination or collection )
   - expensive 
   - no information about the cost
   - need to list files to get number of files and encryption % information

    comment: 
    
    You can use large EC2 and parallelism to make the result faster but it will be costly and it will still return the result in few minutes for millions of files

2. Use aws CLI or boto3 and Cloudwatch
   
   Same solution 

   Using cloudwatch you will not need to list content of buckets to get information about number of files on each bucket and type of storage but this solution will still be slow and expensive. 
   
3. Using Cost Explorer from Aws CLI or boto3 

   Limitation : Impossible to get the price by bucket, you will need to tag all your bucket with their name and you will need to get bucket information from s3 listing.
   
   
4. S3 inventory 
   
   S3 inventory need to be activate on each bucket and the destination bucket has to be in the same region. This will cover a good way to have all bucket information but there is no information about cost

5. S3 Storage Lens 
   
   This is a very good solution to get all information about all bucket on all account on each region.

   This is the big benefit, if you have an organization, you can get information for your all your bucket for all your account.

   Cons and limitation : Impossible to implement with Terraform and require to wait around 48H to be active.
   
   It will not covers the cost.

6. Cost and Usage report

   This is the perfect solution to have the cost usage by bucket. 
   
   You will not get information about the bucket itself but you can have all you need for cost usage.

   Cons and limitation : Require until 24h to be active and you can use Terraform to implement it only in us-east-1 region.  

### Architecture 

My choice after analyse of the different solution will be to use **cost and usage report and s3 storage lens** with export to parquet file on S3.
Apache Parquet file support fast data processing and is compressed, it's a lot more  more efficient than row file like csv.

This solution will cover all the need for cost and bucket information and it will be entirely serverless and it will not be expensive. Moreover, this solution is flexible and it will be possible easily to cover storage of different resource on AWS.

[AWS Cost and Usage Reports](https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html) will create report periodically (hourly or daily) uploaded to an S3 bucket for the AWS Organizations master account.

[AWS storage lens](https://aws.amazon.com/blogs/aws/s3-storage-lens/) will create report daily uploaded to an S3 bucket for the AWS Organizations master account and 

When AWS put a new file in the cost and report or storage lens bucket an event is created that triggered a Lambda function which will run a Glue Crawler to update the database, a database to allow quick searches through AWS Athena.
  
A view will be create to join the 2 tables (cost and lens) based on the bucket id.
The view will be use to organize and have better performance for our queries.

Athena will be use to query the database to get the information about our bucket and cost.

Using Athena, we will only pay when we are using the command and everything will be fully serverless and automated. 

The tools will connect to [Athena](https://docs.aws.amazon.com/athena/latest/ug/what-is.html) to make the query and return the result based on the argument we provide. 
Athena is Serverless, so you don't have to manage any infrastructure.

Moreover Athena can integrate easily to QuickSight for easy data virtualization and BI. 


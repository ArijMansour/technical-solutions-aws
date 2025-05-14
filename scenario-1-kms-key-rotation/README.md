## Question 1 – What are the main challenges in applying key rotation and what are the potential impacts?

### Main challenges:

- **BYOK-specific rotation complexity**: Since your keys are managed in a dedicated security account with external origin (BYOK) generated from HSM, rotation requires secure material generation and transportation across security boundaries  which adds significant complexity compared to AWS-native KMS key rotation.

- **Environment and service segregation maintenance**: The architecture shows clear separation between Dev and Prod environments with each service (S3, RDS, DynamoDB) having its own dedicated key  making consistent rotation across all environments more difficult.

- **Alias management across multiple services**: The diagram shows specific key aliases (`dev-s3`, `int-s3`, `prod-s3`, `dev-rds`, etc.) that must be carefully managed during rotation as incorrect alias updates could result in services accessing the wrong keys.

- **Least privilege principle preservation**: In that senario case we’re implementing least privilege policies for key access but rotation often requires temporary elevated permissions which must be controlled to avoid policy violations.

- **Cross-account key material transport**: Moving key material from the on-prem HSM to the dedicated security account requires secure transport channels and proper encryption during transit increasing operational and security overhead.

- **Service-specific encryption requirements**: Each AWS service (S3, RDS, DynamoDB) has different encryption behaviors  which means the rotation process must adapt per service.

### Potential impacts:

- **Service disruption risk**: If rotation isn't coordinated properly between the security account and Dev/Prod environments services may temporarily lose access to encrypted data especially in long-running processes.

- **Data accessibility issues**: RDS resources (`dev-rds`, `int-rds`, `prod-rds`) could experience decryption failures if rotation isn’t handled carefully particularly during key alias transitions.


- **Operational complexity increase**: The multi-environment, multi-service setup involves at least 9 key aliases significantly increasing the scope of operational work during rotation.

- **Security account overload**: The centralized security account that manages all keys could become a bottleneck during rotation potentially affecting all downstream services across environments.

---

## Question 2 – What are the high-level steps to rotate a KMS key manually?

For The BYOK setup with segregated environments and a centralized security account, I recommend the following structured rotation process:

### Plan and schedule the rotation:

- Document all keys requiring rotation (`dev-s3`, `int-s3`, `prod-s3`, `dev-rds`, etc..)
- Schedule maintenance windows for each environment (Dev → Int → Prod)
- Notify stakeholders who rely on these services

### Generate new key material in the on-premises HSM:

- Follow the HSM procedures and ensure compliance with internal standards
- Generate separate key materials per service and environment to maintain logical isolation

### Prepare the security account:

- Download AWS wrapping keys for each KMS key requiring rotation
- Temporarily elevate IAM permissions to perform `import-key-material` while maintaining least privilege

###  Rotate keys per environment (start with Dev):

- Import the encrypted key material using `aws kms import-key-material`
- Optionally create temporary new KMS keys (`temp-dev-s3`, `temp-dev-rds`) for test validation

### Test before production switch:

- Validate encryption/decryption operations with sample data
- Ensure new keys respect expected IAM boundaries and policies

### Update aliases in sequence:

- Start with Dev: update `dev-s3`, `dev-rds`, and `dev-dynamodb` aliases to point to new keys
- Monitor usage, validate services, then repeat the process for Int and Prod

---
## Question 3 – After applying the rotation on keys, we're required to monitor the resources to identify at any given time which resources (RDS, DynamoDB, S3) are not compliant (i.e., resources where rotation has not been applied). How could we achieve this requirement using AWS managed services?

To effectively monitor resources that haven't yet adopted the newly rotated keys, I recommend building a centralized monitoring strategy using native AWS services — designed to support your multi-environment architecture (Dev, Int, Prod).

---

###  Monitoring Solution Architecture

#### 1. AWS Config with Custom Rules

- Implement custom **AWS Config rules** to evaluate the encryption settings of S3 buckets, RDS instances, and DynamoDB tables.
- These rules should validate that the **KMS key ARN** or **alias** used by each resource matches the latest rotated key.
- Deploy the rules across all accounts and environments to maintain consistent compliance coverage.

#### 2. CloudTrail for Key Usage Tracking

- Enable **AWS CloudTrail** in the security account, focusing on key KMS API actions like `Decrypt` and `GenerateDataKey`.
- Use **CloudTrail filters** or Athena queries to detect continued use of deprecated key IDs.
- Trigger **AWS Lambda functions** on detection events to raise alerts or flag non-compliant resources automatically.

####  3. Resource Tagging Strategy

- Enforce a **tagging policy** using standardized tags such as:
  - `KeyRotationStatus = Rotated / Pending`
  - `LastKeyRotationDate = YYYY-MM-DD`
- Update these tags during key rotation pipelines to reflect the current state.


#### 4. Custom CloudWatch Dashboard

Build a CloudWatch dashboard to visualize key compliance KPIs:

- Number of resources per service (S3, RDS, DynamoDB) still using old keys.
- Time-series graph of rotation adoption across environments.
- Real-time compliance ratio (rotated vs total).

---
## Question 4 – What's the best way to secure key material during their transportation from HSM to AWS KMS?

When moving encryption keys from your on-premises HSM to AWS KMS, security is critical. Any compromise during this step could expose sensitive key material and compromise your data encryption strategy. Here's a simplified approach that balances strong security with operational practicality:

---

### Three Core Security Principles

#### 1. Use AWS's Built-in Security Features

- Always use the strongest wrapping algorithm AWS offers typically `RSA_AES_KEY_WRAP_SHA_256`.
- Request a secure import token and wrapping key from AWS KMS before starting the process.

- Encrypt the key material using the HSM or a secure cryptographic tool before uploading.

#### 2. Apply Physical Security measures 

- Use a dedicated workstation, ideally isolated or disconnected from the internet, to perform the key wrapping . 
- Require multi-person control: at least two authorized individuals should be present during the export and wrapping process. 
- If physical transport is necessary use encrypted USB devices with hardware write protection and tamper-evident seals.

#### 3. Enforce Process Security 

- Follow a step-by-step documented procedure for key export, wrapping, and import . 
- Perform hash-based verification before and after transfer to confirm the integrity of the key material.
- After a successful import into AWS KMS, securely delete all temporary files and storage media.

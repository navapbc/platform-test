# Threat Detection (AWS GuardDuty)

The infrastructure includes AWS GuardDuty for comprehensive threat detection and security monitoring across the AWS account. This document describes how GuardDuty is configured, its capabilities, and troubleshooting procedures.

## How threat detection works

GuardDuty analyzes tens of billions of events across multiple AWS data sources to detect malicious activity and unauthorized behavior:

- **AWS CloudTrail event logs** - API calls and user activities
- **Amazon VPC Flow Logs** - Network traffic patterns
- **DNS logs** - Domain name resolution requests
- **S3 data events** - Object-level operations for malware detection

GuardDuty uses machine learning, anomaly detection, and integrated threat intelligence to identify threats including:

- Compromised instances communicating with malicious IPs
- Cryptocurrency mining activities
- Data exfiltration attempts
- Malware in S3 objects
- Reconnaissance attacks
- Unusual API call patterns

## Malware detection for S3 storage

GuardDuty's malware detection feature continuously scans files uploaded to S3 buckets for malicious content. When malware is detected:

1. **File access is blocked** - Downloads of infected files are prevented
2. **Findings are generated** - Security findings are created in the GuardDuty service with detailed information including:
   - **Finding ID** - Unique identifier for the security event
   - **Severity level** - Low, Medium, High, Critical
   - **Finding type** - Specific threat classification (e.g., `Malware:S3/MaliciousFile`)
   - **Resource details** - Affected S3 bucket, object key, and account information
   - **Timestamp** - When the malware was detected
   - **Evidence** - Technical details about the malicious content
   - **Remediation** - Recommended actions to address the threat
3. **Tags are applied** - S3 objects are tagged with scan results for tracking:
   - **`GuardDutyMalwareScanStatus`** - Scan result status (`NO_THREATS_FOUND`, `THREATS_FOUND`)

### Checking S3 Object Tags for Malware Status

```bash
#!/bin/bash

for plan_id in $(aws guardduty list-malware-protection-plans \
    --query "MalwareProtectionPlans[*].MalwareProtectionPlanId" \
    --output text); do

    bucket=$(aws guardduty get-malware-protection-plan \
        --malware-protection-plan-id "$plan_id" \
        --query "ProtectedResource.S3Bucket.BucketName" \
        --output text 2>/dev/null)

    if [ "$bucket" != "None" ] && [ -n "$bucket" ]; then
        echo "Scanning protected bucket: $bucket ..."

        aws s3api list-objects-v2 --bucket "$bucket" \
            --query "Contents[*].Key" \
            --output text 2>/dev/null | tr '\t' '\n' | \
        while read -r key; do
            if [ -n "$key" ]; then
                tags=$(aws s3api get-object-tagging \
                    --bucket "$bucket" \
                    --key "$key" \
                    --query "TagSet[?Key=='GuardDutyMalwareScanStatus' && Value=='THREATS_FOUND'].Value" \
                    --output text 2>/dev/null)

                if [ "$tags" = "THREATS_FOUND" ]; then
                    echo "MALWARE DETECTED: s3://$bucket/$key"
                fi
            fi
        done
    fi
done
```

### Accessing GuardDuty Findings

**AWS Console:**
- Navigate to GuardDuty Console → Findings
- Filter by finding type, severity, or resource
- View detailed finding information and evidence

## Deployment

GuardDuty is deployed as part of the account layer infrastructure:

```bash
make infra-update-current-account
```

## Configuration

**Threat detection is enabled by default** for all environments. The configuration can be customized through Terraform variables in the accounts layer.

### Disabling Threat Detection

To disable GuardDuty threat detection entirely:

1. Edit your Terraform workspace configuration file for the account layer:
   ```bash
   # Example: infra/accounts/envs/dev.tfvars or the appropriate environment file
   ```

2. Set the threat detection variable to `false`:
   ```hcl
   enable_threatdetection = false
   ```

3. Apply the changes:
   ```bash
   cd infra/accounts
   make plan ENV=<your-environment>
   make apply ENV=<your-environment>
   ```

### Available Configuration Options

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `enable_threatdetection` | Enable/disable GuardDuty threat detection | `true` | `true`, `false` |
| `threatdetection_finding_publishing_frequency` | How often GuardDuty publishes findings to CloudWatch Events | `"FIFTEEN_MINUTES"` | `"FIFTEEN_MINUTES"`, `"ONE_HOUR"`, `"SIX_HOURS"` |

### Configuration Example

```hcl
# infra/accounts/envs/production.tfvars
enable_threatdetection = true
threatdetection_finding_publishing_frequency = "ONE_HOUR"
```

### Malware Detection Errors

When GuardDuty detects malware in uploaded files, users may encounter the following errors:

#### File Download Blocked

**Error Message:**
```
fatal error: An error occurred (403) when calling the HeadObject operation: Forbidden
```

**Cause:** GuardDuty's malware detection has identified the file as containing malware or suspicious content, and AWS S3 is blocking access with a 403 Forbidden error.

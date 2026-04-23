#!/bin/bash

echo
echo "========================================================"
echo "=  Testing S3 bucket encryption: PUT, GET, DELETE      ="
echo "========================================================"
echo

BUCKET_NAME="s3-kms-platform-test-app-flask-dev"
PROFILE="platform-test"

# check bucket encryption
echo "$ aws s3api get-bucket-encryption --bucket $BUCKET_NAME --profile $PROFILE --no-cli-pager"
ENCRYPTION_OUTPUT=$(aws s3api get-bucket-encryption --bucket $BUCKET_NAME --profile $PROFILE --no-cli-pager)

# parse and display encryption type (KMS vs. AWS-managed)
if echo "$ENCRYPTION_OUTPUT" | grep -q "aws:kms"; then
    echo "✅ Bucket using customer-managed KMS encryption"
    KMS_KEY_ID=$(echo "$ENCRYPTION_OUTPUT" | grep -o 'arn:aws:kms:[^"]*' | head -1)
    echo "   KMS Key: $KMS_KEY_ID"
elif echo "$ENCRYPTION_OUTPUT" | grep -q "AES256"; then
    echo "❌ Bucket using AWS-managed encryption (AES256) - expected KMS"
    exit 1
else
    echo "⚠️  Unknown encryption type"
    exit 1
fi
echo

# verify KMS key policy allows service principals
if [ -n "$KMS_KEY_ID" ]; then
    echo "$ aws kms get-key-policy --key-id $KMS_KEY_ID --policy-name default --profile $PROFILE"
    KMS_POLICY=$(aws kms get-key-policy --key-id "$KMS_KEY_ID" --policy-name default --profile $PROFILE --output text)
    
    if echo "$KMS_POLICY" | grep -q "kms:ViaService"; then
        echo "✅ KMS key policy includes service principal access via S3"
    else
        echo "⚠️  KMS key policy does not include service principal access"
    fi
    echo
fi

# create test file
echo "$ echo 'test content' > test.txt"
echo "test content" > test.txt
echo "✅ Test file created"
echo

# upload
echo "$ aws s3 cp test.txt s3://$BUCKET_NAME/test.txt --profile $PROFILE"
if aws s3 cp test.txt s3://$BUCKET_NAME/test.txt --profile $PROFILE; then
    echo "✅ Upload successful"
else
    echo "❌ Upload failed"
    exit 1
fi
echo

# download file from s3
echo "$ aws s3 cp s3://$BUCKET_NAME/test.txt test-downloaded.txt --profile $PROFILE"
if aws s3 cp s3://$BUCKET_NAME/test.txt test-downloaded.txt --profile $PROFILE; then
    echo "✅ Download successful"
else
    echo "❌ Download failed"
    exit 1
fi
echo

# verify files match - which they should
echo "$ diff test.txt test-downloaded.txt > /dev/null"
if diff test.txt test-downloaded.txt > /dev/null; then
    echo "✅ Content verified - files match"
else
    echo "❌ Content mismatch"
    exit 1
fi
echo

# cleanup files - remove from s3, remove from local
echo "$ aws s3 rm s3://$BUCKET_NAME/test.txt --profile $PROFILE"
if aws s3 rm s3://$BUCKET_NAME/test.txt --profile $PROFILE; then
    echo "✅ Cleanup successful"
else
    echo "❌ Cleanup failed"
fi

rm -f test.txt test-downloaded.txt
echo

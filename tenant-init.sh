#!/bin/bash
echo "Listing custom domains for app $AWS_APP_ID"
aws amplify list-domain-associations --app-id $AWS_APP_ID --query 'domainAssociations[].domainName' --output text

#!/bin/bash

# Ensure AWS_APP_ID and DOMAIN environment variables are set
if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME and REGION environment variables must be set."
  exit 1
fi

# Retrieve the list of custom domains
domains=$(aws amplify list-domain-associations --app-id $AWS_APP_ID --query 'domainAssociations[].domainName' --output text)

# Check if the command succeeded
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to retrieve custom domains."
  exit 1
fi

# Initialize an array to hold subdomains
subdomains=()

# Process each domain to extract the subdomain
for domain in $domains; do
  # Remove the DOMAIN suffix from each domain
  if [[ $domain == *.$DOMAIN ]]; then
    subdomain=${domain%.$DOMAIN}
  else
    # If the domain does not end with $DOMAIN, handle accordingly
    subdomain=$domain
  fi
  subdomains+=("$subdomain")
done

# Initialize an array to hold the final list
pool_list=()

# Create the final list
echo "Final list:"
for subdomain in "${subdomains[@]}"; do
  pool_name=$(echo "$APP_NAME" | sed "s/{domain}/$subdomain/g")
  pool_name=$(echo "pool_name" | sed "s/{region}/$REGION/g")
  pool_list+=("$pool_name")
done

# Print the final list
for pool_name in "${pool_list[@]}"; do
  echo "$pool_name"
done
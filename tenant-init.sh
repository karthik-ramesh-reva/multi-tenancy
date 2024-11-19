#!/bin/bash

# Ensure required environment variables are set
if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME, and REGION environment variables must be set."
  exit 1
fi

# Retrieve the list of custom domains from AWS Amplify
domains=$(aws amplify list-domain-associations --app-id "$AWS_APP_ID" --query 'domainAssociations[].domainName' --output text --region "$REGION")

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

# Initialize an array to hold the pool names
pool_list=()

# Create the pool names by replacing placeholders in APP_NAME
echo "Final list of pool names:"
for subdomain in "${subdomains[@]}"; do
  pool_name=$(echo "$APP_NAME" | sed "s/{domain}/$subdomain/g")
  pool_name=$(echo "$pool_name" | sed "s/{region}/$REGION/g")
  pool_list+=("$pool_name")
  echo "$pool_name"
done

# For each pool_name, get the user_pool_id from Cognito and print it
echo -e "\nUser Pool IDs:"
for pool_name in "${pool_list[@]}"; do
  # Use AWS CLI to list user pools and filter by pool_name
  user_pool_id=$(aws cognito-idp list-user-pools --max-results 60 --region "$REGION" \
    --query "UserPools[?Name=='$pool_name'].Id" --output text)

  if [[ -z "$user_pool_id" || "$user_pool_id" == "None" ]]; then
    echo "User pool not found for pool name: $pool_name"
  else
    echo "Pool Name: $pool_name, User Pool ID: $user_pool_id"
  fi
done

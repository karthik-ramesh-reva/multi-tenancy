#!/bin/bash

# Ensure AWS_APP_ID and DOMAIN environment variables are set
if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME and REGION environment variables must be set."
  exit 1
fi

echo "Listing custom domains for app $AWS_APP_ID"

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

# Create the final list
echo "Final list:"
for subdomain in "${subdomains[@]}"; do
  modified_subdomain=$(echo "$APP_NAME" | sed "s/{domain}/$subdomain/g")
  modified_subdomain=$(echo "$modified_subdomain" | sed "s/{region}/$REGION/g")
  echo "Cognito Pool : $modified_subdomain"
done

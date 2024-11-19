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
    # List app clients for the user pool
        app_clients=$(aws cognito-idp list-user-pool-clients --user-pool-id "$user_pool_id" --region "$REGION" --query 'UserPoolClients[].{ClientId:ClientId,ClientName:ClientName}' --output json)
        # Check if app clients are found
        if [[ -z "$app_clients" || "$app_clients" == "[]" ]]; then
          echo "No app clients found for user pool: $user_pool_id"
        else
          echo "App Clients for User Pool ID $user_pool_id:"
          echo "$app_clients" | jq -r '.[] | "  Client Name: \(.ClientName), Client ID: \(.ClientId)"'

          # For each app client, get the client secret securely
          echo "$app_clients" | jq -r '.[] | .ClientId' | while read client_id; do
            # Get the app client details
            app_client_details=$(aws cognito-idp describe-user-pool-client --user-pool-id "$user_pool_id" --client-id "$client_id" --region "$REGION" --query 'UserPoolClient.{ClientName:ClientName,ClientId:ClientId,ClientSecret:ClientSecret}' --output json)

            # Extract client name and client secret
            client_name=$(echo "$app_client_details" | jq -r '.ClientName')
            client_secret=$(echo "$app_client_details" | jq -r '.ClientSecret')

            # Handle the client secret securely
            # For demonstration, we're printing the client ID and client name only
            # Avoid printing the client secret in logs
            echo "  Client Name: $client_name, Client ID: $client_id, Client Secret: $client_secret"

            # If you need to use the client secret, store it securely, e.g., in AWS Secrets Manager
            # Example (do not run in production without proper security measures):
            # aws secretsmanager create-secret --name "${pool_name}_${client_name}_client_secret" --secret-string "$client_secret" --region "$REGION"
          done
        fi
  fi
done

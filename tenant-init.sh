#!/bin/bash

# Ensure required environment variables are set
if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME, and REGION environment variables must be set."
  exit 1
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo yum install -y jq
fi

# Define the path to your customerConfig.ts file
CUSTOMER_CONFIG_FILE="utils/customerConfig.ts"

# Start building the customerConfigs string
customer_configs_content="export const customerConfigs: { [key: string]: CustomerConfig } = {\n"

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
echo "Generating customerConfigs for subdomains:"
for subdomain in "${subdomains[@]}"; do
  pool_name=$(echo "$APP_NAME" | sed "s/{domain}/$subdomain/g")
  pool_name=$(echo "$pool_name" | sed "s/{region}/$REGION/g")
  pool_list+=("$pool_name")
  echo "Subdomain: $subdomain, Pool Name: $pool_name"

  # Find the user pool ID
  user_pool_id=$(aws cognito-idp list-user-pools --max-results 60 --region "$REGION" \
    --query "UserPools[?Name=='$pool_name'].Id" --output text)

  if [[ -z "$user_pool_id" || "$user_pool_id" == "None" ]]; then
    echo "User pool not found for pool name: $pool_name"
    continue
  fi

  # Get Cognito domain (assuming it's consistent with the pool name)
  cognito_domain="${pool_name}.auth.${REGION}.amazoncognito.com"

  # List app clients for the user pool
  app_clients=$(aws cognito-idp list-user-pool-clients --user-pool-id "$user_pool_id" --region "$REGION" --query 'UserPoolClients[?ClientName==`app_client`]' --output json)

  # Check if app clients are found
  if [[ -z "$app_clients" || "$app_clients" == "[]" ]]; then
    echo "No app clients found for user pool: $user_pool_id"
    continue
  fi

  # Get the first app client
  client_id=$(echo "$app_clients" | jq -r '.[0].ClientId')

  # Get the client secret
  app_client_details=$(aws cognito-idp describe-user-pool-client --user-pool-id "$user_pool_id" --client-id "$client_id" --region "$REGION" --query 'UserPoolClient.{ClientSecret:ClientSecret}' --output json)
  client_secret=$(echo "$app_client_details" | jq -r '.ClientSecret')

  # Construct redirectUri and logoutUri
  protocol="https"
  redirect_uri="${protocol}://${subdomain}.${DOMAIN}/callback"
  logout_uri="${protocol}://${subdomain}.${DOMAIN}"

  # Build the customerConfig entry
  customer_configs_content+="    ${subdomain}: {\n"
  customer_configs_content+="        cognitoDomain: '${cognito_domain}',\n"
  customer_configs_content+="        clientId: '${client_id}',\n"
  customer_configs_content+="        clientSecret: '${client_secret}',\n"
  customer_configs_content+="        userPoolId: '${user_pool_id}',\n"
  customer_configs_content+="        region: '${REGION}',\n"
  customer_configs_content+="        redirectUri: '${redirect_uri}',\n"
  customer_configs_content+="        logoutUri: '${logout_uri}'\n"
  customer_configs_content+="    },\n"
done

# Close the customerConfigs object
customer_configs_content+="};\n"

# Build the full content of customerConfig.ts
customer_config_ts_content="// utils/customerConfig.ts\n\n"
customer_config_ts_content+="export interface CustomerConfig {\n"
customer_config_ts_content+="    cognitoDomain: string;\n"
customer_config_ts_content+="    clientId: string;\n"
customer_config_ts_content+="    clientSecret: string;\n"
customer_config_ts_content+="    userPoolId: string;\n"
customer_config_ts_content+="    region: string;\n"
customer_config_ts_content+="    redirectUri: string;\n"
customer_config_ts_content+="    logoutUri: string;\n"
customer_config_ts_content+="}\n\n"
customer_config_ts_content+="$customer_configs_content"

# Write the content to customerConfig.ts
#echo -e "$customer_config_ts_content" > "$CUSTOMER_CONFIG_FILE"
echo "$customer_config_ts_content"
echo "customerConfig.ts has been updated."

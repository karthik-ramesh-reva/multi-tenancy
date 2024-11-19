#!/bin/bash

if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME, and REGION environment variables must be set."
  exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo yum install -y jq
fi

CUSTOMER_CONFIG_FILE="utils/customerConfig.ts"

customer_configs_content="export const customerConfigs: { [key: string]: CustomerConfig } = {\n"

domains=$(aws amplify list-domain-associations --app-id "$AWS_APP_ID" --query 'domainAssociations[].domainName' --output text --region "$REGION")

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to retrieve custom domains."
  exit 1
fi

subdomains=()

for domain in $domains; do
  if [[ $domain == *.$DOMAIN ]]; then
    subdomain=${domain%.$DOMAIN}
  else
    subdomain=$domain
  fi
  subdomains+=("$subdomain")
done

pool_list=()

echo "Generating customerConfigs for subdomains:"
for subdomain in "${subdomains[@]}"; do
  pool_name=$(echo "$APP_NAME" | sed "s/{domain}/$subdomain/g")
  pool_name=$(echo "$pool_name" | sed "s/{region}/$REGION/g")
  pool_list+=("$pool_name")

  user_pool_id=$(aws cognito-idp list-user-pools --max-results 60 --region "$REGION" \
    --query "UserPools[?Name=='$pool_name'].Id" --output text)

  if [[ -z "$user_pool_id" || "$user_pool_id" == "None" ]]; then
    continue
  fi

  cognito_domain="${pool_name}.auth.${REGION}.amazoncognito.com"

  app_clients=$(aws cognito-idp list-user-pool-clients --user-pool-id "$user_pool_id" --region "$REGION" --query 'UserPoolClients[].{ClientId:ClientId,ClientName:ClientName}' --output json)

  if [[ -z "$app_clients" || "$app_clients" == "[]" ]]; then
    continue
  fi

  client_id=$(echo "$app_clients" | jq -r '.[0].ClientId')

  app_client_details=$(aws cognito-idp describe-user-pool-client --user-pool-id "$user_pool_id" --client-id "$client_id" --region "$REGION" --query 'UserPoolClient.{ClientSecret:ClientSecret}' --output json)
  client_secret=$(echo "$app_client_details" | jq -r '.ClientSecret')

  protocol="https"
  redirect_uri="${protocol}://${subdomain}.${DOMAIN}/callback"
  logout_uri="${protocol}://${subdomain}.${DOMAIN}"

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

customer_configs_content+="};\n"

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

echo -e "$customer_config_ts_content" > "$CUSTOMER_CONFIG_FILE"
echo "customerConfig.ts has been updated."

cat utils/customerConfig.ts

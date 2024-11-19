#!/bin/bash

# Ensure required environment variables are set
if [[ -z "$AWS_APP_ID" || -z "$DOMAIN" || -z "$APP_NAME" || -z "$REGION" ]]; then
  echo "Error: AWS_APP_ID, DOMAIN, APP_NAME, and REGION environment variables must be set."
  exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo yum install -y jq
fi

CUSTOMER_CONFIG_FILE="utils/customerConfig.ts"

customer_configs_content=""

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

  cognito_domain="reva-auth-${subdomain}.auth.${REGION}.amazoncognito.com"

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

if [[ -n "$customer_configs_content" ]]; then
  customer_configs_content="${customer_configs_content%,\n}"
fi

existing_content=$(cat "$CUSTOMER_CONFIG_FILE")

updated_content=$(echo "$existing_content" | awk -v configs="$customer_configs_content" '
  BEGIN {found=0}
  {
    if ($0 ~ /\/\/ Add your customer configurations here/) {
      print configs
      found=1
    } else {
      print $0
    }
  }
  END {
    if (found == 0) {
      print "Error: Placeholder line not found in customerConfig.ts" > "/dev/stderr"
      exit 1
    }
  }
')

if [[ $? -ne 0 ]]; then
  echo "Error updating customerConfig.ts. Placeholder line not found."
  exit 1
fi

echo "$updated_content" > "$CUSTOMER_CONFIG_FILE"

echo "customerConfig.ts has been updated."

cat "$CUSTOMER_CONFIG_FILE"

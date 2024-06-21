#!/bin/sh

set -eu -o pipefail
export DEBIAN_FRONTEND=noninteractive

export API_URL=http://polymesh-private-rest-api:3000

# Install prerequisites
apk add --no-cache \
    curl \
    jq \
    postgresql16-client

# Function to set status in psql db
set_status() {
  psql -c "INSERT INTO status (service_name, service_available) VALUES ('rest-api-init', $1) ON CONFLICT (service_name) DO UPDATE SET service_available = EXCLUDED.service_available" > /dev/null
}

set_status "false"

# Function to get address
get_address() {
  local address=$(curl -sf -X 'GET' \
    "$API_URL/signer/$1" \
    -H 'accept: application/json' \
    | jq -r .address)

  if [ -z "$address" ]; then
    echo "Failed to get the address for $1" >&2
    exit 1
  fi

  echo "$address"
}

# Create on chain identities for the non-admin users
create_identity() {
  local user_address=$1
  local user_role=$2

  response=$(curl -s -X "POST" \
    "$API_URL/developer-testing/create-test-accounts" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
    \"signer\": \"ppadmin-1\",
    \"accounts\": [
      {
        \"address\": \"$user_address\",
        \"initialPolyx\": 100000
      }
    ]
  }" | jq -r .results[0].did )

  if [ -z "response" ]; then
    echo "Failed to create an identity for the $user_role user" >&2
    exit 1
  fi

  echo "${user_role}_did: $response"
  echo "$response" > /opt/polymesh-private-rest-api/status/$user_role"_did"
}



# check if setup has already been completed
if [ -f /opt/polymesh-private-rest-api/status/.setup-complete ]; then

  for file in /opt/polymesh-private-rest-api/status/*_address; do
    echo "$(basename $file): $(cat $file)"
  done

  for file in /opt/polymesh-private-rest-api/status/*_did; do
    echo "$(basename $file): $(cat $file)"
  done

  set_status "true"

  echo "Setup has already been completed"

  exit 0
fi

###############################################################
# Get the addresses of the admin and sender, receiver and mediator users
echo "Getting the admin user"
ppadmin_address=$(get_address ppadmin-1)
echo $ppadmin_address > /opt/polymesh-private-rest-api/status/ppadmin_address
echo "Admin user address: $ppadmin_address"
echo "Getting the sender, receiver, mediator and venue-owner users addresses"
sender_address=$(get_address sender-1)
echo $sender_address > /opt/polymesh-private-rest-api/status/sender_address
echo "Sender user address: $sender_address"
receiver_address=$(get_address receiver-1)
echo $receiver_address > /opt/polymesh-private-rest-api/status/receiver_address
echo "Receiver user address: $receiver_address"
mediator_address=$(get_address mediator-1)
echo $mediator_address > /opt/polymesh-private-rest-api/status/mediator_address
echo "Mediator user address: $mediator_address"
venue_owner_address=$(get_address venue-owner-1)
echo $venue_owner_address > /opt/polymesh-private-rest-api/status/venue_owner_address
echo "Venue owner user address: $venue_owner_address"

###############################################################
# Make the admin user a CDD Provider

echo "Making the admin user a CDD Provider"

response=$(curl -s -X "POST" \
  "$API_URL/developer-testing/create-test-admins" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
  \"accounts\": [
    {
      \"address\": \"$ppadmin_address\",
      \"initialPolyx\": 10000000
    }
  ]
}" | jq -r .results[0].did )

if [ -z "response" ]; then
  echo "Failed to make the admin user a CDD Provider"
  exit 1
fi

echo "Admin user DiD: $response"

###############################################################
# Create an identities for sender, receiver and mediator

create_identity "$sender_address" "Sender"
create_identity "$receiver_address" "Receiver"
create_identity "$mediator_address" "Mediator"
create_identity "$venue_owner_address" "Venue_Owner"

###############################################################
# Create a file to mark the setup has been completed
touch /opt/polymesh-private-rest-api/status/.setup-complete

set_status "true"

echo "Setup has been completed"

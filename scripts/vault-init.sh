#!/bin/bash
set -eu -o pipefail
export DEBIAN_FRONTEND=noninteractive
export BASHOPTS # copy options to subshells

export VAULT_ADDR=http://vault:8200

###############################################################

: "${TIMEOUT_SECONDS:=60}" # env var with default fallback

###############################################################

initialize_vault() {
    echo "Initializing Vault"
    INIT=$(vault operator init \
                  -key-shares 1 \
                  -key-threshold 1 \
                  -format=json)
    echo "Saving Vault unseal and root keys to files"
    echo "$(echo "$INIT" | jq -r .unseal_keys_b64[0])" > /opt/vault/.unseal_key
    echo "$(echo "$INIT" | jq -r .root_token)" > /vault-token/token
}

unseal_vault() {
    local key
    key=$(cat /opt/vault/.unseal_key)
    vault operator unseal $key

    check_transit_engine
}

check_transit_engine() {
    export VAULT_TOKEN=$(cat /vault-token/token)

    if echo $(vault secrets list -format=json) | jq -e 'paths | join("/") | test("transit/") | not' > /dev/null; then
        vault secrets enable -path=transit transit
        # This will add an admin user who can be granted CDD authority 
        vault write transit/keys/ppadmin type=ed25519

        # These users will be used in the examples to demonstrate the use of polymesh private transactions
        vault write transit/keys/sender type=ed25519
        vault write transit/keys/receiver type=ed25519
        vault write transit/keys/mediator type=ed25519
        vault write transit/keys/venue-owner type=ed25519
    else
        echo "Transit engine already enabled"
    fi
}

# wait for Vault to be ready
READY=false
SECONDS_DELTA=$SECONDS
while [[ $(($SECONDS - $SECONDS_DELTA)) -lt "$TIMEOUT_SECONDS" ]]; do

    STATUS=$(vault status \
                  -format=json 2>/dev/null || true)

    if [ ${#STATUS} -gt 0 ]; then

      if [ $(echo "$STATUS" | jq -r .initialized) = false ]; then
          initialize_vault
      elif [ $(echo "$STATUS" | jq -r .sealed) = true ]; then
          echo "Vault is sealed, unsealing"
          unseal_vault
      fi

      CRITERIA=(
        '.type == "shamir"'
        'and .sealed == false'
        'and .storage_type == "file"'
        'and .initialized == true'
      )
      if [ $(echo "$STATUS" | jq -r "${CRITERIA[*]}") = true ]; then
          READY=true
          echo "Vault is ready"
          break
      fi
      
    fi

    sleep 1
done

# Output Vault Root Token
echo "Vault Root Token: $(cat /vault-token/token)"

if [ "$READY" = false ]; then
    >&2 echo "Timed out waiting for Vault to become ready"
    exit 1
fi

###############################################################
#!/bin/bash

set -o pipefail
set -ex

CHAIN_ID="arkeo"
STAKE="50000000000000000uarkeo"
TOKEN="uarkeo"
USER="ark"

add_module() {
	jq --arg ADDRESS "$1" --arg ASSET "$2" --arg AMOUNT "$3" --arg NAME "$4" '.app_state.auth.accounts += [{
        "@type": "/cosmos.auth.v1beta1.ModuleAccount",
        "base_account": {
          "address": $ADDRESS,
          "pub_key": null,
          "sequence": "0"
        },
        "name": $NAME,
        "permissions": []
  }]' </root/.arkeo/config/genesis.json >/tmp/genesis.json
	mv /tmp/genesis.json /root/.arkeo/config/genesis.json

	jq --arg ADDRESS "$1" --arg ASSET "$2" --arg AMOUNT "$3" '.app_state.bank.balances += [{
        "address": $ADDRESS,
        "coins": [ { "denom": $ASSET, "amount": $AMOUNT } ],
    }]' </root/.arkeo/config/genesis.json >/tmp/genesis.json
	mv /tmp/genesis.json /root/.arkeo/config/genesis.json
}

add_account() {
	jq --arg ADDRESS "$1" --arg ASSET "$2" --arg AMOUNT "$3" '.app_state.auth.accounts += [{
        "@type": "/cosmos.auth.v1beta1.BaseAccount",
        "address": $ADDRESS,
        "pub_key": null,
        "account_number": "0",
        "sequence": "0"
    }]' </root/.arkeo/config/genesis.json >/tmp/genesis.json
	mv /tmp/genesis.json /root/.arkeo/config/genesis.json

	jq --arg ADDRESS "$1" --arg ASSET "$2" --arg AMOUNT "$3" '.app_state.bank.balances += [{
        "address": $ADDRESS,
        "coins": [ { "denom": $ASSET, "amount": $AMOUNT } ],
    }]' </root/.arkeo/config/genesis.json >/tmp/genesis.json
	mv /tmp/genesis.json /root/.arkeo/config/genesis.json
}

if [ ! -f /root/.arkeo/config/priv_validator_key.json ]; then
	# remove the original generate genesis file, as below will init chain again
	rm -rf /root/.arkeo/config/genesis.json
fi

if [ ! -f /root/.arkeo/config/genesis.json ]; then
	arkeod init local --staking-bond-denom $TOKEN --chain-id "$CHAIN_ID"
	arkeod keys add $USER --keyring-backend test
	arkeod add-genesis-account $USER $STAKE --keyring-backend test
	arkeod keys list --keyring-backend test
	arkeod gentx $USER $STAKE --chain-id $CHAIN_ID --keyring-backend test
	arkeod collect-gentxs

	arkeod keys add faucet --keyring-backend test
	FAUCET=$(arkeod keys show faucet -a --keyring-backend test)
	add_account "$FAUCET" $TOKEN 10000000000000000 # faucet, 100m

	if [ "$NET" = "mocknet" ] || [ "$NET" = "testnet" ]; then
		add_module tarkeo1d0m97ywk2y4vq58ud6q5e0r3q9khj9e3unfe4t $TOKEN 10000000000000000 'arkeo-reserve' # reserve, 100m

		echo "shoulder heavy loyal save patient deposit crew bag pull club escape eyebrow hip verify border into wire start pact faint fame festival solve shop" | arkeod keys add alice --keyring-backend test --recover
		ALICE=$(arkeod keys show alice -a --keyring-backend test)
		add_account "$ALICE" $TOKEN 1100000000000000 # alice, 11m

		echo "clog swear steak glide artwork glory solution short company borrow aerobic idle corn climb believe wink forum destroy miracle oak cover solid valve make" | arkeod keys add bob --keyring-backend test --recover
		BOB=$(arkeod keys show bob -a --keyring-backend test)
		add_account "$BOB" $TOKEN 1000000000000000 # bob, 10m
	fi

	sed -i 's/"stake"/"uarkeo"/g' /root/.arkeo/config/genesis.json
	sed -i 's/enable = false/enable = true/g' /root/.arkeo/config/app.toml
	sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' /root/.arkeo/config/config.toml

	set -e
	arkeod validate-genesis --trace
fi

arkeod start

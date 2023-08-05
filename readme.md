# Arkeo Protocol

Arkeo Protocol - Free Market Blockchain Data Infrastructure

[![Arkeo CI](https://github.com/arkeonetwork/arkeo/actions/workflows/ci.yml/badge.svg)](https://github.com/arkeonetwork/arkeo/actions/workflows/ci.yml)
[![Release](https://github.com/arkeonetwork/arkeo/actions/workflows/release.yml/badge.svg)](https://github.com/arkeonetwork/arkeo/actions/workflows/release.yml)

**arkeo** is a blockchain built using Cosmos SDK and Tendermint and created
with [Ignite CLI](https://ignite.com/cli).

## Setting up a node

Make sure your system is updated and set the system parameters correctly:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential curl wget jq make gcc chrony git
sudo su -c "echo 'fs.file-max = 65536' >> /etc/sysctl.conf"
sudo sysctl -p
```

### Install go

```bash
sudo rm -rf /usr/local/.go
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz
sudo cp /usr/local/go /usr/local/.go -r
sudo rm -rf /usr/local/go
```

### Update environment variables to include go

```bash
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/.go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/.go/bin:$HOME/go/bin
EOF
source $HOME/.profile
```

Check if go is correctly installed:

```bash
go version
```

This should return something like "go version go1.18.1 linux/amd64"

### Arkeo Binary

Install the Arkeo binary

```bash
git clone [https://github.com/arkeonetwork/arkeo](https://github.com/arkeonetwork/arkeo)
cd arkeo
git checkout <version hash, found at
https://github.com/arkeonetwork/infra/blob/master/arkeo-stack/mainnet.yaml#L3>
make proto-gen install
[binary] version
```

### Configure the binary

```bash
[binary] keys add <key-name>
[binary] config chain-id [chain-id]
[binary] init <your_custom_moniker> --chain-id [chain-id]
curl [insert link to raw version of genesis.json] > /root/.arkeo/config/genesis.json
sudo ufw allow 26656
```

Set the seed in the config.toml
(find seeds here: [insert link to file containing seeds]):

```bash
nano $HOME/.arkeo/config/config.toml
seeds="[put in seeds]"
indexer = "null"
```

Configure also the app.toml:

```toml
minimum-gas-prices = 0.001[denom]
pruning: "custom"
pruning-keep-recent = "100"
pruning-keep-every = "0"
pruning-interval ="10"
snapshot-interval = 1000
snapshot-keep-recent = 2
```

### Create the service file for Arkeo to make sure it remains running at all times

```bash
sudo tee /etc/systemd/system/arkeod.service > /dev/null <<EOF
[Unit]
Description=Arkeo Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which arkeod) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo mv /etc/systemd/system/arkeod.service /lib/systemd/system/
```

### Start the binary

```bash
sudo -S systemctl daemon-reload
sudo -S systemctl enable arkeod
sudo -S systemctl start arkeod
sudo systemctl enable arkeod.service && sudo systemctl start arkeod.service
```

Monitor using:

```bash
systemctl status arkeod
sudo journalctl -u arkeod -f
```

## Building the chain

### Get started

```bash
ignite chain serve
```

`serve` command installs dependencies, builds, initializes, and starts your
blockchain in development.

#### Configure

Your blockchain in development can be configured with `config.yml`. To learn
more, see the [Ignite CLI docs](https://docs.ignite.com).

### Release

To release a new version of your blockchain, create and push a new tag with
`v` prefix. A new draft release with the configured targets will be created.

```bash
git tag v0.1
git push origin v0.1
```

After a draft release is created, make your final changes from the release
page and publish it.

#### Install

To install the latest version of your blockchain node's binary, execute the
following command on your machine:

```bash
curl https://get.ignite.com/username/arkeo@latest! | sudo bash
```

`arkeonetwork/arkeo` should match the `username` and `repo_name` of the Github
repository to which the source code was pushed. Learn more about [the install
process](https://github.com/allinbits/starport-installer).

### Regression Tests

We expose a testing framework that allows the definition of test cases and suites using a DSL in YAML. Providing a regular expression to the `RUN` environment variable will match against files in `test/regression/suites` to filter tests to run.

```bash
make test-regression

# with more detailed logs
DEBUG=1 make test-regression

# with specific test filters
RUN=initialize make test-regression
RUN=free-query test-regression

# overwrite export state
EXPORT=1 make test-regression

# check last run coverage
make test-regression-coverager
```

See more detailed information in [test/regression/README.md](test/regression/README.md).

### Learn more

- [Ignite CLI](https://ignite.com/cli)
- [Tutorials](https://docs.ignite.com/guide)
- [Ignite CLI docs](https://docs.ignite.com)
- [Cosmos SDK docs](https://docs.cosmos.network)
- [Developer Chat](https://discord.gg/ignite)

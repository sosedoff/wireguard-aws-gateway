# wireguard-aws-gateway

Provisioning and configuration repository to manage Wireguard AWS VPN Gateway setup.

## Overview

This repository demonstrates how to setup a VPN gateway for an AWS VPC.

Key features:

- **Split tunnel setup**: Only Wireguard/VPC traffic is being forwarded to the gateway.
- **Custom DNS**: Resolve AWS private DNS entries locally. Setup `.private` records for wireguard hosts.

## Requirements

- Ansible 2.x
- Terraform 1.0.x
- Wireguard Tools
- AWS Account

We're setting up a brand new VPC in this repository, if you have an existing one
you will need to modify the terraform files accordingly.

You can check if you have all components installed:

```bash
ansible-playbook --version
terraform --version
wg --help
```

### Installation

On Mac:

```bash
brew install ansible
brew install terraform
brew install wireguard-tools
```

On Ubuntu:

```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update
sudo apt install -y ansible terraform wireguard resolveconf
```

## Defaults

This demo repository has a few defaults:

| Name | Value | Description
|------|-------|--------------
| Wireguard CIDR | `10.10.0.0/24` | VPN network range
| AWS Region | `us-east-1` | AWS Region
| AWS CIDR | `10.0.0.0/16` | AWS VPC network range

## Usage

Clone the source repository:

```bash
git clone https://github.com/sosedoff/wireguard-aws-gateway
cd wireguard-aws-gateway
```

Next, run the initialization script:

```bash
./scripts/init
```

Example output:

```text
Generating a new SSH key: ./ansible/keys/ssh
Generating public/private rsa key pair.
Your identification has been saved in ./ansible/keys/ssh.
Your public key has been saved in ./ansible/keys/ssh.pub.
Generating a new Wireguard key: ./ansible/keys/wireguard
Generating a new Wireguard client key: ./ansible/keys/wireguard_client
Creating Terraform variables file: ./terraform/terraform.tfvars
Creating Ansible variables file: ./ansible/vars.yml
```

The init script will create the following files that you can inspect and modify as needed:

| File                             | Description |
|----------------------------------|-------------|
|`./ansible/keys/wireguard`        | Server Wireguard private key (+ pubkey)
|`./ansible/keys/wireguard_client` | Client Wireguard private key (+ pubkey).
|`./ansible/keys/ssh`              | Server SSH private key (+ pubkey).
|`./terraform/terraform.tfvars`    | Terraform variables file.
|`./ansible/vars.yml`              | Ansible playbook variables.

**You must replace AWS credentials in the terraform.tfvars file before moving onto next step**

### Terraform

Terraform will create all required infrastructure components in AWS.

All required configuration has already been created for us by the init script, let's have a quick look:

```hcl
aws_access_key        = "XXX"
aws_secret_key        = "XXX"
region                = "us-east-1"
vpc_cidr              = "10.0.0.0/16"
vpc_public_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
gateway_network       = "10.10.0.0/24"
gateway_instance_type = "t3.micro"
```

It's time to provision the infrastructure, run the script:

```
./scripts/provision
```

If you have correctly configured Terraform and all variables look good, you'll be prompted to confirm the execution plan. Enter `yes` when ready.

Execution takes a minute and successful output might look something like:

```text
Initializing modules...
Initializing the backend...
Initializing provider plugins...
...

Apply complete! Resources: X added, 0 changed, 0 destroyed.
Outputs:

gateway_public_ip = "123.456.789.000"
```

Great! We have provisioned an EC2 instance, with public (persistent) IP seen above.

### Ansible

Ansible will configure all packages (Wireguard/CoreDNS) on our EC2 instance.

Example configuration has also been created by the init script. Let's have a look:

```yml
gateway:
  # Server private/public wireguard keys.
  private_key: "XXX"
  public_key: "XXX"

  # Name of the tunnel network interface.
  tunnel: "wg0"

  # Name of the network interface to forward traffic to.
  # Usually it's `eth0` but has a different default on AWS.
  interface: "ens5"

  # VPN network range. Should not overlap with VPC CIDR!
  network: "10.10.0.0/24"

  # Wireguard listen address. This is the default.
  listen_port: "51820"

  # Optional keepalive setting for sensitive clients.
  persistent_keepalive: "60"

  # List of client peers you would like to connect with.
  # These keys should be privded by clients or generated with `wg` toolkit.
  peers:
    - name: user1
      public_key: "XXX"
      addr: "10.10.0.1"

coredns:
  # Version of the coredns binary
  version: "1.8.1"

  # AWS provides a resolver on address equals to VPC base range + 2.
  # If the VPC CIDR is 10.0.0.0/16 then resolver is available at 10.0.0.2.
  forward_to: "10.0.0.2"

  # If private zone name is provided all peers from the section above will
  # get their own DNS entries, like `user1.private`, etc.
  private_zone: "private"
```

You should be able to continue by running the configuration command:

```
./scripts/configure
```

Configuration process might take a minute or two and should look like:

```text
PLAY [all] *****************************************************************************************************************************************************

TASK [setup] ***************************************************************************************************************************************************
ok: [wireguard]

TASK [Update package cache] ************************************************************************************************************************************
changed: [wireguard]

TASK [Install basic packages] **********************************************************************************************************************************
ok: [wireguard]

TASK [Enable IPV4 forwarding] **********************************************************************************************************************************
ok: [wireguard]

TASK [Check if CoreDNS is installed] ***************************************************************************************************************************
ok: [wireguard]
```

### Result

What we have as a result of all previous steps:

- VPN gateway running Wireguard at `123.456.789.000` on port `51820`.
- VPN network `10.10.0.0/24`
- DNS Server running on `10.10.0.0`
- Single client configured on `10.10.0.1`
- Forwarding traffic to AWS VPC `10.0.0.0/16`

### Configuring Clients

To test out our VPN gateway setup you'll need to configure your local Wireguard client.

Get the configuration with:

```bash
./scripts/client-config
```

You can use a Mac or a Linux client to test it out.

### Testing

Final step in this setup is to make sure our tunnel and configuration works.

Activate your Wireguard VPN connection. Now, let's verify private IP access / DNS resolution really works:

```bash
./scripts/verify
```

All the steps above should be successful and should always return the same ip: `10.0.x.x`. If you happen to have any other resources in your VPC, you can ping them (or resolve their names) similarly.

The script also verified that accessing domain records like `user1.private` works. Those will resolve to an address in the VPN range, like `10.10.0.1`.

# XRPL Validator Quick Start Guide

Deploy a Lucendex-branded XRPL validator in 15 minutes.

## Prerequisites

Install required tools on macOS:

```bash
# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Install direnv (optional but recommended)
brew install direnv
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc

# Verify installations
terraform --version
docker --version
```

## Step 1: Deploy Validator

From the `infra/validator/` directory:

```bash
cd infra/validator
./validator-deploy.sh
```

This will:
- ✓ Check prerequisites
- ✓ Generate SSH keys
- ✓ Plan infrastructure
- ✓ Ask for confirmation
- ✓ Deploy VM to Vultr
- ✓ Wait for SSH
- ✓ Install and harden system
- ✓ Install Docker
- ✓ Deploy rippled container
- ✓ Generate validator keys

**The deployment takes ~10-15 minutes.**

## Step 2: Save Validator Keys

During deployment, validator keys will be generated. **YOU MUST SAVE THESE:**

```
[validation_public_key]: nHUED...
[validator_token]: eyJ2YWxpZGF0aW9uX3NlY3JldCI6Ij...
```

**Critical:** Save both in a secure password manager!

## Step 3: Brand Your Validator (Automatic)

Brand your validator as "Lucendex" in XRPL network explorers:

**Run Update (Automatic Configuration):**

```bash
./validator-update.sh
# Select option 1: Update configuration
```

This automatically:
- ✅ Retrieves your validator public key
- ✅ Updates rippled.cfg with domain verification
- ✅ Applies changes and restarts validator

**DNS Setup (One-Time):**

Get your validator ID:
```bash
make validator-id
```

Add TXT record to `lucendex.com` DNS:

```
Name: xrpl-validator-public-key
Type: TXT
Value: <your-validator-public-key-from-above>
TTL: 3600
```

**Done!** The network will now display "Lucendex" as the validator operator.

## Step 4: Verify Deployment

```bash
# From infra/validator/ directory
make status    # Check validator status
make logs      # View rippled logs
make health    # Full health check
```

## Common Operations

```bash
# SSH into validator
make ssh

# View logs
make logs

# Check peers
make peers

# Check consensus participation  
make consensus

# Restart validator
make restart

# Backup configuration
make backup

# Show validator public key
make validator-keys
```

## Monitoring

Check validator status regularly:

```bash
# Quick status
make status

# Full health check
make health

# Resource usage
make resources
```

## Troubleshooting

### Validator not syncing
```bash
make peers      # Check peer connections
make ledger     # Check ledger status
make restart    # Restart if needed
```

### Can't connect via SSH
```bash
# Check IP from Terraform
cd terraform && terraform output validator_ip

# Test SSH manually
ssh -i terraform/validator_ssh_key root@<ip>
```

### Need to update configuration
```bash
# Edit local config
vim docker/rippled.cfg

# Upload to server
make update-config

# Restart to apply
make restart
```

## Security Reminders

✓ **Validator keys:** Backed up offline  
✓ **SSH key:** `infra/terraform/validator_ssh_key` (gitignored)  
✓ **API key:** In `.envrc` (gitignored)  
✓ **Firewall:** Only port 51235 and SSH exposed  
✓ **Updates:** Automatic security updates enabled  

## Costs

**Monthly:** ~$48/month (Vultr 4 vCPU, 8GB RAM, 160GB SSD + backups)

## Management Scripts

```bash
# Update validator (config, keys, Docker image)
./validator-update.sh

# Destroy validator (with backups)
./validator-destroy.sh
```

## Next Steps

1. ✓ Validator deployed and running
2. Set up DNS TXT record for Lucendex branding
3. Add validator public key to UNL (Unique Node List)
4. Monitor for 24-48 hours to ensure stability
5. Join XRPL validator community for UNL inclusion

## Support

- **XRPL Docs:** https://xrpl.org/run-rippled-as-a-validator.html
- **Validator Requirements:** https://xrpl.org/system-requirements.html
- **Community:** XRPLedger Discord, r/Ripple

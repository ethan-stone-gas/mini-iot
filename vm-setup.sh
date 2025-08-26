#!/usr/bin/env bash
set -euo pipefail

# === Inputs ===
if [[ $# -lt 4 ]]; then
  echo "❌ Usage: $0 <THING_NAME> <THING_GROUP> <AWS_REGION> <SSH_PUBLIC_KEY_FILE>"
  exit 1
fi

THING_NAME=$1
THING_GROUP=$2
AWS_REGION=$3
SSH_PUB_KEY=$4

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "❌ Must export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY before running"
  exit 1
fi

echo "📦 Installing required packages..."
sudo apt update
sudo apt install -y unzip zip openssh-server default-jdk curl

echo "🔑 Setting up SSH server..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "🔑 Adding provided SSH public key to authorized_keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$SSH_PUB_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "👤 Creating ggc_user and ggc_group..."
sudo useradd --system --create-home ggc_user || true
sudo groupadd --system ggc_group || true

echo "📥 Downloading Greengrass nucleus..."
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-nucleus-latest.zip -o greengrass-nucleus-latest.zip
unzip greengrass-nucleus-latest.zip -d GreengrassInstaller
rm greengrass-nucleus-latest.zip

echo "⚙️ Installing Greengrass..."
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE \
  -jar ./GreengrassInstaller/lib/Greengrass.jar \
  --aws-region $AWS_REGION \
  --thing-name $THING_NAME \
  --thing-group-name $THING_GROUP \
  --thing-policy-name GreengrassV2IoTThingPolicy \
  --tes-role-name GreengrassV2TokenExchangeRole \
  --tes-role-alias-name GreengrassCoreTokenExchangeRoleAlias \
  --component-default-user ggc_user:ggc_group \
  --provision true \
  --setup-system-service true

echo "✅ Greengrass installed and provisioned."
echo "👉 Next: In AWS Console, revise deployment to add aws.greengrass.LogManager and aws.greengrass.SecureTunneling."
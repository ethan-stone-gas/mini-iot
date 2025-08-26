1. Create a VM with multipass.
2. Install k3 on the VM.
3. Get the VM IP and the kubeconfig from the VM. Update the kubeconfig on local machine.
4. Install zip on the VM if it isn't already installed.
5. Install openssh-server on the VM if it isn't already installed.
6. Setup ssh server.
7. Add public key to authorized_keys.
8. Create an ecr secret so that flux can pull from the private ecr repo.
9. Install flux.
10. Create a gh personal access token.
11. Bootstrap flux.
12. Install java. sudo apt install default-jdk.
13. Setup gcc_user and gcc_group. sudo useradd --system --create-home ggc_user AND sudo groupadd --system ggc_group.
14. Create AWS credentials with minimum installer permissions.
15. Setup AWS credentials on device (export AWS_ACCESS_KEY_ID and export AWS_SECRET_ACCESS_KEy)
16. Download greengrass curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-nucleus-latest.zip > greengrass-nucleus-latest.zip
17. Unzip greengrass unzip greengrass-nucleus-latest.zip -d GreengrassInstaller && rm greengrass-nucleus-latest.zip
18. Install greengrass

```
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE \
  -jar ./GreengrassInstaller/lib/Greengrass.jar \
  --aws-region region \
  --thing-name MyGreengrassCore \
  --thing-group-name MyGreengrassCoreGroup \
  --thing-policy-name GreengrassV2IoTThingPolicy \
  --tes-role-name GreengrassV2TokenExchangeRole \
  --tes-role-alias-name GreengrassCoreTokenExchangeRoleAlias \
  --component-default-user ggc_user:ggc_group \
  --provision true \
  --setup-system-service true
```

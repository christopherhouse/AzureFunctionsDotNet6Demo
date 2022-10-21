# Set up an Azure DevOps Variable Groups

## Note: These pipelines needs a variable group named "FunctionDemo"

To create these variable groups, customize and run this command in the Azure Cloud Shell, once for each environment:

``` bash
   az login

   az pipelines variable-group create 
     --organization=https://dev.azure.com/<yourAzDOOrg>/ 
     --project='<yourAzDOProject>' 
     --name FunctionDemo 
     --variables 
         acrName='<bicep container registry name>'
         acrPassword='<bicep container admin password>'
         acrPrincipalId='<service principal id with access to bicep container registry>'
         acrTenantId='<service principal tenant id>'
         acrPrincipalSecret='<service principal client secret>'
         appPrefix='functiondemo' 
         appSuffix=''
         functionName='process'
         functionAppSku='Y1'
         functionAppSkuFamily='Y'
         functionAppSkuTier='Dynamic'
         keyVaultOwnerUserId1='owner1SID'
         keyVaultOwnerUserId2='owner1SID'
         location='eastus' 
         orgPrefix='<yourInitials>' 
         runSecurityDevOpScan='true'
         storageSku='Standard_LRS'
         serviceConnectionName='<yourServiceConnectionName>' 
         subscriptionId='<yourSubscriptionId>' 
         subscriptionName='<yourAzureSubscriptionName>' 
```

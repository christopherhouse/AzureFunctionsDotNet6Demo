# Set up GitHub Secrets

The GitHub workflows in this project require several secrets set at the repository level.

---

## Azure Credentials

You need to set up the Azure Credentials secret in the GitHub Secrets at the Repository level before you do anything else.

See https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions for more info.

It should look something like this:

AZURE_CREDENTIALS:

``` bash
{
  "clientId": "<GUID>", 
  "clientSecret": "<GUID>", 
  "subscriptionId": "<GUID>", 
  "tenantId": "<GUID>"
}
```

---

## Bicep Configuration Values

These secrets are used by the Bicep templates to configure the resource names that are deployed.  
Make sure the App_Name variable is unique to your deploy. It will be used as the basis for the function name and for all the other Azure resources, which must be globally unique.
To create these additional secrets, customize and run this command:

Required Values:

``` bash
gh secret set APP_NAME -b '<yourInitials>-functiong'
gh secret set AZURE_SUBSCRIPTION_ID -b '<yourAzureSubscriptionId>'
gh secret set KEYVAULT_OWNER_USERID -b '<owner1SID>'
```

Optional Values: (only needed if Twilio notification functions are expected to work!)

``` bash
gh secret set TWILIOACCOUNTSID -b '<twilioAccountSid>'
gh secret set TWILIOAUTHTOKEN -b '<twilioAuthToken>'
gh secret set TWILIOPHONENUMBER -b '<twilioPhoneNumber>'
```

<!-- 
---
Note: I thought this was needed, but the app seems to work fine with it...!
## Azure Application Publishing Credentials

Before you run the application build/deploy workflows, the AZURE_FUNCTION_PUBLISH_PROFILE needs to have initialized for EACH ENVIRONMENT you deploy to.  The value that can be found by going in the portal to the Function App -> Deployment Center -> Manage Publish Profile -> Download.  It will look like this:

AZURE_FUNCTION_PUBLISH_PROFILE:

``` bash
<publishData>
  <publishProfile profileName="your-function - Web Deploy" 
     publishMethod="MSDeploy" ...></publishProfile>
  <publishProfile profileName="your-function - FTP" 
     publishMethod="FTP" ...></publishProfile>
  <publishProfile profileName="your-function - Zip Deploy" 
     publishMethod="ZipDeploy" ...></publishProfile>
</publishData>
``` -->

---

## References

[Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)
[GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
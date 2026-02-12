# HubSpot CRM Create Read Associations

This example demonstrates how to create and read associations between HubSpot CRM objects, specifically between deals and companies, using both default and custom association types.

## Prerequisites

1. **HubSpot Setup**
   > Refer the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
clientId = "<Your Client ID>"
clientSecret = "<Your Client Secret>"
refreshToken = "<Your Refresh Token>"
```

## Run the example

Execute the following command to run the example. The script will create associations between deals and companies, then read and display the created associations.

```shell
bal run
```

The example will:
1. Create multiple default associations between deals and companies
2. Create multiple associations with custom labels between deals and companies  
3. Read and display all associations for the specified deals with companies
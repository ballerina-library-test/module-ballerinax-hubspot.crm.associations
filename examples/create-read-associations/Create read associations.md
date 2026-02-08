# HubSpot CRM Deal-Company Association Management

This example demonstrates how to create and read associations between deals and companies in HubSpot CRM, including both default associations and custom associations with specific labels.

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

Execute the following command to run the example. The script will create associations between deals and companies, then retrieve and display the created associations.

```shell
bal run
```

The example will:
1. Create default associations between specified deals and companies
2. Create custom associations with specific labels and categories
3. Read and display all associations for the created deal-company relationships
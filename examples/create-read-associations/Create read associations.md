# HubSpot CRM Associations Management

This example demonstrates how to create and read associations between HubSpot CRM objects, specifically showing how to establish both default and custom associations between deals and companies using batch operations.

## Prerequisites

1. **HubSpot Setup**
   > Refer the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest#setup-guide) here.

2. For this example, create a `Config.toml` file with your credentials:

```toml
clientId = "<Your Client ID>"
clientSecret = "<Your Client Secret>"
refreshToken = "<Your Refresh Token>"
```

## Run the Example

Execute the following command to run the example. The script will print its progress to the console.

```shell
bal run
```
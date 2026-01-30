# HubSpot CRM Associations Management

This example demonstrates how to create, read, and delete associations between HubSpot CRM objects (deals and companies), including both default associations and custom labeled associations.

## Prerequisites

1. **HubSpot Setup**
   > Refer to the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest#setup-guide) to obtain the OAuth2 credentials.

2. For this example, create a `Config.toml` file with your credentials:

```toml
clientId = "<Your Client ID>"
clientSecret = "<Your Client Secret>"
refreshToken = "<Your Refresh Token>"
```

## Run the Example

Execute the following command to run the example. The script will demonstrate creating default associations, creating labeled associations, reading associations, and deleting specific and all associations between deals and companies.

```bash
bal run
```

The script will print the progress and responses for each operation to the console, showing:
- Creation of default associations between a deal and company
- Creation of labeled associations with custom association types
- Reading existing associations
- Deletion of specific labeled associations
- Deletion of all associations between the objects
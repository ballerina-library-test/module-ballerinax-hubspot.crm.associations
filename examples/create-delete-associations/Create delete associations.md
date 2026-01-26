# HubSpot CRM Associations Management

This example demonstrates how to create, read, and delete associations between HubSpot CRM objects (deals and companies) using both default associations and custom labeled associations.

## Prerequisites

1. **HubSpot Setup**
   > Refer to the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest#setup-guide) to obtain the OAuth2 credentials.

2. For this example, create a `Config.toml` file with your OAuth2 credentials:

```toml
clientId = "<Your Client ID>"
clientSecret = "<Your Client Secret>"
refreshToken = "<Your Refresh Token>"
```

## Run the Example

Execute the following command to run the example. The script will demonstrate creating default associations, creating labeled associations, reading associations, and then deleting both specific and all associations between the specified deal and company objects.

```bash
bal run
```

The script will print the responses for each operation to the console, showing:
- Creation of default associations between a deal and company
- Creation of labeled associations with custom association types
- Reading of existing associations
- Deletion of specific labeled associations
- Reading associations after specific deletion
- Deletion of all associations between the objects
- Final reading of associations after complete deletion
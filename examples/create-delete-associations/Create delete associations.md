# HubSpot CRM Associations Management

This example demonstrates how to create, read, and delete associations between HubSpot CRM objects, specifically showing how to manage relationships between deals and companies using both default and custom labeled associations.

## Prerequisites

1. **HubSpot Setup**
   > Refer to the [HubSpot setup guide](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest#setup-guide) to obtain the OAuth2 credentials.

2. **Configuration**
   
   For this example, create a `Config.toml` file with your OAuth2 credentials:

   ```toml
   clientId = "<Your Client ID>"
   clientSecret = "<Your Client Secret>"
   refreshToken = "<Your Refresh Token>"
   ```

3. **Update Object IDs**
   
   Before running the example, update the `FROM_OBJECT_ID` and `TO_OBJECT_ID` constants in the code with valid deal and company IDs from your HubSpot account.

## Run the Example

Execute the following command to run the example. The script will demonstrate creating default associations, creating labeled associations, reading associations, and deleting specific and all associations between the specified deal and company.

```bash
bal run
```

The script will output the responses for each operation, showing:
- Creation of default associations between a deal and company
- Creation of labeled associations with custom association types
- Reading existing associations
- Deletion of specific labeled associations
- Deletion of all associations between the objects
## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer platform that provides software and support to help businesses grow better by connecting marketing, sales, content management, and customer service.

The `ballerinax/hubspot.crm.associations` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot CRM Associations API v4](https://developers.hubspot.com/docs/api/crm/associations).
## Setup guide

To use the HubSpot CRM Associations connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have access to HubSpot's API features. While basic API access is available on free accounts, some advanced features may require a paid plan (Starter, Professional, or Enterprise).

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. Click on the settings gear icon in the top navigation bar to access your account settings.

3. In the left sidebar, navigate to Integrations > Private Apps.

4. Click "Create a private app" and provide a name and description for your app.

5. In the Scopes tab, select the required scopes for CRM associations (typically "CRM" scopes including read/write permissions for contacts, companies, deals, and custom objects).

6. Click "Create app" and then copy the generated access token from the Auth tab.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `hubspot.crm.associations` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerina/oauth2;
import ballerinax/hubspot.crm.associations as crmAssociations;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with your credentials:

```toml
clientId = "<Your_Client_Id>"
clientSecret = "<Your_Client_Secret>"
refreshToken = "<Your_Refresh_Token>"
```

2. Create a `crmAssociations:ConnectionConfig` and initialize the client:

```ballerina
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;

final crmAssociations:Client crmAssociationsClient = check new({
    auth: {
        clientId,
        clientSecret,
        refreshToken
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create default associations in batch

```ballerina
public function main() returns error? {
    crmAssociations:BatchInputPublicDefaultAssociationMultiPost batchRequest = {
        inputs: [
            {
                'from: {
                    id: "12345"
                },
                to: {
                    id: "67890"
                }
            }
        ]
    };

    crmAssociations:BatchResponsePublicDefaultAssociation response = check crmAssociationsClient->/associations/["contacts"]/["companies"]/batch/associate/default.post(batchRequest);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.crm.associations` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples), covering the following use cases:

1. [Create delete associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-delete-associations) - Demonstrates how to create and delete associations between HubSpot CRM objects.
2. [Create read associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-read-associations) - Illustrates creating associations and reading existing associations between CRM objects.
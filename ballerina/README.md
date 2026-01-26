## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that provides tools for marketing, sales, customer service, and content management to help businesses grow and manage their customer relationships effectively.

The `ballerinax/hubspot.crm.associations` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot CRM Associations API v4](https://developers.hubspot.com/docs/api/crm/associations).
## Setup guide

To use the HubSpot CRM Associations connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have access to the HubSpot CRM, which is available in all HubSpot plans including the free tier, though API access and rate limits may vary by subscription level.

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. Click on the settings gear icon in the top right corner of your HubSpot dashboard.

3. In the left sidebar, navigate to Integrations > Private Apps.

4. Click "Create a private app" button.

5. Fill in the basic information for your app (name, description).

6. Go to the "Scopes" tab and select the required scopes for CRM associations (typically "crm.objects.contacts.read", "crm.objects.companies.read", and other relevant CRM scopes).

7. Click "Create app" and then "Continue creating" to generate your access token.

> **Tip:** You must copy and store this key somewhere safe. It won't be visible again in your account settings for security reasons.
## Quickstart

To use the `HubSpot CRM Associations` connector in your Ballerina application, update the `.bal` file as follows:

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

#### Create associations between objects

```ballerina
public function main() returns error? {
    crmAssociations:BatchInputPublicAssociationMultiPost associationRequest = {
        inputs: [
            {
                'from: {id: "12345"},
                to: {id: "67890"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };

    crmAssociations:BatchResponseLabelsBetweenObjectPair response = check crmAssociationsClient->/associations/contacts/companies/batch/create.post(associationRequest);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.crm.associations` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples), covering the following use cases:

1. [Create delete associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-delete-associations) - Demonstrates how to create and delete associations between HubSpot CRM objects.
2. [Create read associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-read-associations) - Illustrates creating associations and retrieving association data between CRM records.

# Ballerina hubspot.crm.associations connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-hubspot.crm.associations.svg)](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/hubspot.crm.associations.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%hubspot.crm.associations)

## Overview

[HubSpot](https://www.hubspot.com/) is a comprehensive customer relationship management (CRM) platform that helps businesses grow by providing tools for marketing, sales, customer service, and content management in one integrated solution.

The `ballerinax/hubspot.crm.associations` package offers APIs to connect and interact with [HubSpot API](https://developers.hubspot.com/docs/api/overview) endpoints, specifically based on [HubSpot CRM Associations API v4](https://developers.hubspot.com/docs/api/crm/associations).
## Setup guide

To use the HubSpot CRM Associations connector, you must have access to the HubSpot API through a [HubSpot developer account](https://developers.hubspot.com/) and obtain an API access token. If you do not have a HubSpot account, you can sign up for one [here](https://www.hubspot.com/products/get-started).

### Step 1: Create a HubSpot Account

1. Navigate to the [HubSpot website](https://www.hubspot.com/) and sign up for an account or log in if you already have one.

2. Ensure you have access to HubSpot's CRM features. While HubSpot offers free CRM access, some advanced API features may require paid plans (Starter, Professional, or Enterprise).

### Step 2: Generate an API Access Token

1. Log in to your HubSpot account.

2. Click on the settings gear icon in the top navigation bar to access your account settings.

3. In the left sidebar, navigate to Integrations > Private Apps.

4. Click "Create a private app" to generate a new application.

5. Configure your app by providing a name and description, then navigate to the "Scopes" tab.

6. Select the required scopes for CRM associations (such as `crm.objects.contacts.read`, `crm.objects.companies.read`, and `crm.associations.read`).

7. Click "Create app" and then copy the generated access token from the "Auth" tab.

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
    crmAssociations:BatchInputPublicAssociationMultiPost batchRequest = {
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

    crmAssociations:BatchResponseLabelsBetweenObjectPair response = check crmAssociationsClient->/associations/contacts/companies/batch/create.post(batchRequest);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```
## Examples

The `hubspot.crm.associations` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples), covering the following use cases:

1. [Create delete associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-delete-associations) - Demonstrates how to create and delete associations between HubSpot CRM objects.
2. [Create read associations](https://github.com/ballerina-platform/module-ballerinax-hubspot.crm.associations/tree/main/examples/create-read-associations) - Illustrates creating associations and retrieving association data between CRM objects.
## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

    > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

    > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

    ```bash
    ./gradlew clean build
    ```

2. To run the tests:

    ```bash
    ./gradlew clean test
    ```

3. To build the without the tests:

    ```bash
    ./gradlew clean build -x test
    ```

4. To run tests against different environments:

    ```bash
    ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
    ```

5. To debug the package with a remote debugger:

    ```bash
    ./gradlew clean build -Pdebug=<port>
    ```

6. To debug with the Ballerina language:

    ```bash
    ./gradlew clean build -PbalJavaDebug=<port>
    ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToCentral=true
    ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).


## Useful links

* For more information go to the [`hubspot.crm.associations` package](https://central.ballerina.io/ballerinax/hubspot.crm.associations/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.

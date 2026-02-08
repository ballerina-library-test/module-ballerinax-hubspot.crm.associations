// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/os;
import ballerina/test;
import ballerina/http;
import hubspot.crm.associations.mock.server as _;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string privateApp = isLiveServer ? os:getEnv("HUBSPOT_PRIVATE_APP") : "test_private_app";
configurable string serviceUrl = isLiveServer ? "https://api.hubapi.com/crm/v4" : "http://localhost:9090/crm/v4";

ConnectionConfig config = {
    auth: {
        privateApp: privateApp,
        privateAppLegacy: privateApp
    }
};
final Client hubspotClient = check new Client(config, serviceUrl);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteAssociation() returns error? {
    error? deleteResponse = check hubspotClient->/objects/contact/["123"]/associations/company/["456"].delete();
    test:assertTrue(deleteResponse is (), "Expected no error on successful delete");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testListAssociations() returns error? {
    CollectionResponseMultiAssociatedObjectWithLabel listResponse = check hubspotClient->/objects/contact/["123"]/associations/company.get();
    test:assertTrue(listResponse.results.length() > 0, "Expected a non-empty results array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchArchiveAssociations() returns error? {
    BatchInputPublicAssociationMultiArchive archivePayload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };
    http:Response archiveResponse = check hubspotClient->/associations/contact/company/batch/archive.post(archivePayload);
    test:assertEquals(archiveResponse.statusCode, 200, "Expected status code 200");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateDefaultAssociations() returns error? {
    BatchInputPublicDefaultAssociationMultiPost defaultPayload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"}
            }
        ]
    };
    BatchResponsePublicDefaultAssociation defaultResponse = check hubspotClient->/associations/contact/company/batch/associate/'default.post(defaultPayload);
    test:assertTrue(defaultResponse.results !is (), "Expected response body to be present");
    test:assertTrue(defaultResponse.results.length() > 0, "Expected a non-empty results array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateAssociations() returns error? {
    BatchInputPublicAssociationMultiPost createPayload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };
    BatchResponseLabelsBetweenObjectPair createResponse = check hubspotClient->/associations/contact/company/batch/create.post(createPayload);
    test:assertTrue(createResponse.results !is (), "Expected response body to be present");
    test:assertTrue(createResponse.results.length() > 0, "Expected a non-empty results array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchArchiveLabels() returns error? {
    BatchInputPublicAssociationMultiPost labelsPayload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };
    http:Response labelsResponse = check hubspotClient->/associations/contact/company/batch/labels/archive.post(labelsPayload);
    test:assertEquals(labelsResponse.statusCode, 200, "Expected status code 200");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchReadAssociations() returns error? {
    BatchInputPublicFetchAssociationsBatchRequest readPayload = {
        inputs: [
            {
                id: "123"
            }
        ]
    };
    BatchResponsePublicAssociationMultiWithLabel readResponse = check hubspotClient->/associations/contact/company/batch/read.post(readPayload);
    test:assertTrue(readResponse.results !is (), "Expected response body to be present");
    test:assertTrue(readResponse.results.length() > 0, "Expected a non-empty results array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateHighUsageReport() returns error? {
    ReportCreationResponse reportResponse = check hubspotClient->/associations/usage/high\-usage\-report/["12345"].post();
    test:assertTrue(reportResponse.userId !is (), "Expected userId to be present");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateDefaultAssociation() returns error? {
    BatchResponsePublicDefaultAssociation defaultAssocResponse = check hubspotClient->/objects/contact/["123"]/associations/'default/company/["456"].put();
    test:assertTrue(defaultAssocResponse.results.length() > 0, "Expected a non-empty results array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateAssociation() returns error? {
    AssociationSpec[] associationPayload = [
        {
            associationCategory: "HUBSPOT_DEFINED",
            associationTypeId: 1
        }
    ];
    CreatedResponseLabelsBetweenObjectPair associationResponse = check hubspotClient->/objects/contact/["123"]/associations/company/["456"].put(associationPayload);
    AssociationSpec[]? responseLabels = associationResponse.labels;
    test:assertTrue(responseLabels !is (), "Expected labels to be present");
    if responseLabels is AssociationSpec[] {
        test:assertTrue(responseLabels.length() > 0, "Expected a non-empty labels array");
    }
}
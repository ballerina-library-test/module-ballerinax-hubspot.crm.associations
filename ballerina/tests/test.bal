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

import ballerina/http;
import ballerina/os;
import ballerina/test;
import hubspot.crm.associations.mock.server as _;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string privateApp = isLiveServer ? os:getEnv("HUBSPOT_PRIVATE_APP") : "test_private_app";
configurable string serviceUrl = isLiveServer ? "https://api.hubapi.com/crm/v4" : "http://localhost:9090/crm/v4";

ConnectionConfig config = {
    auth: {
        privateApp: privateApp,
        privateAppLegacy: "test_legacy"
    }
};
final Client hubspotClient = check new Client(config, serviceUrl);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteAssociation() returns error? {
    http:Response|error response = hubspotClient->/objects/contacts/["123456"]/associations/companies/["789012"].delete();
    if response is http:Response {
        test:assertTrue(response.statusCode == 200 || response.statusCode == 204, "Expected successful deletion status");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testListAssociations() returns error? {
    CollectionResponseMultiAssociatedObjectWithLabel response = check hubspotClient->/objects/contacts/["123456"]/associations/companies.get();
    test:assertTrue(response.results.length() >= 0, "Expected a valid associations array");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchArchiveAssociations() returns error? {
    BatchInputPublicAssociationMultiArchive payload = {
        inputs: [
            {
                from: {id: "123456"},
                to: {id: "789012"}
            }
        ]
    };
    http:Response|error response = hubspotClient->/associations/contacts/companies/batch/archive.post(payload);
    if response is http:Response {
        test:assertTrue(response.statusCode == 200, "Expected successful archive operation");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateDefaultAssociations() returns error? {
    BatchInputPublicDefaultAssociationMultiPost payload = {
        inputs: [
            {
                from: {id: "123456"},
                to: {id: "789012"}
            }
        ]
    };
    BatchResponsePublicDefaultAssociation|error response = hubspotClient->/associations/contacts/companies/batch/associate/'default.post(payload);
    if response is BatchResponsePublicDefaultAssociation {
        test:assertTrue(response.results.length() >= 0, "Expected valid results field");
        string? status = response?.status;
        test:assertTrue(status !is (), "Expected status field to be present");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateAssociations() returns error? {
    BatchInputPublicAssociationMultiPost payload = {
        inputs: [
            {
                from: {id: "123456"},
                to: {id: "789012"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };
    BatchResponseLabelsBetweenObjectPair|error response = hubspotClient->/associations/contacts/companies/batch/create.post(payload);
    if response is BatchResponseLabelsBetweenObjectPair {
        test:assertTrue(response.results.length() >= 0, "Expected valid results field");
        string? status = response?.status;
        test:assertTrue(status !is (), "Expected status field to be present");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchArchiveLabels() returns error? {
    BatchInputPublicAssociationMultiPost payload = {
        inputs: [
            {
                from: {id: "123456"},
                to: {id: "789012"},
                types: [
                    {
                        associationCategory: "HUBSPOT_DEFINED",
                        associationTypeId: 1
                    }
                ]
            }
        ]
    };
    http:Response|error response = hubspotClient->/associations/contacts/companies/batch/labels/archive.post(payload);
    if response is http:Response {
        test:assertTrue(response.statusCode == 200, "Expected successful archive operation");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchReadAssociations() returns error? {
    BatchInputPublicFetchAssociationsBatchRequest payload = {
        inputs: [
            {
                id: "123456"
            }
        ]
    };
    BatchResponsePublicAssociationMultiWithLabel response = check hubspotClient->/associations/contacts/companies/batch/read.post(payload);
    test:assertTrue(response.results.length() >= 0, "Expected valid results field");
    string? status = response?.status;
    test:assertTrue(status !is (), "Expected status field to be present");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateUsageReport() returns error? {
    record {
        string usageEventType;
        string userId;
    } payload = {
        usageEventType: "high-usage-report",
        userId: "12345"
    };
    http:Response|error response = hubspotClient->/associations/usage/["high-usage-report"]/["12345"].post(payload);
    if response is http:Response {
        test:assertTrue(response.statusCode == 200, "Expected successful report creation");
    } else {
        test:assertFail("Expected successful response");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateDefaultAssociation() returns error? {
    BatchResponsePublicDefaultAssociation response = check hubspotClient->/objects/contacts/["123456"]/associations/'default/companies/["789012"].put();
    test:assertTrue(response.results.length() >= 0, "Expected a valid results array");
    string? status = response?.status;
    test:assertTrue(status !is (), "Expected status field to be present");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateAssociation() returns error? {
    AssociationSpec[] payload = [
        {
            associationCategory: "HUBSPOT_DEFINED",
            associationTypeId: 1
        }
    ];
    LabelsBetweenObjectPair response = check hubspotClient->/objects/contacts/["123456"]/associations/companies/["789012"].put(payload);
    anydata fromObjectIdValue = response["fromObjectId"];
    anydata toObjectIdValue = response["toObjectId"];
    string? fromObjectId = fromObjectIdValue is string ? fromObjectIdValue : ();
    string? toObjectId = toObjectIdValue is string ? toObjectIdValue : ();
    test:assertTrue(fromObjectId !is (), "Expected fromObjectId field to be present");
    test:assertTrue(toObjectId !is (), "Expected toObjectId field to be present");
}
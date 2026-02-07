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
import hubspot.crm.associations.mock.server as _;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string privateApp = isLiveServer ? os:getEnv("HUBSPOT_PRIVATE_APP") : "test_private_app";
configurable string privateAppLegacy = isLiveServer ? os:getEnv("HUBSPOT_PRIVATE_APP_LEGACY") : "test_private_app_legacy";
configurable string serviceUrl = isLiveServer ? "https://api.hubapi.com/crm/v4" : "http://localhost:9090/crm/v4";

ConnectionConfig config = {
    auth: {
        privateApp: privateApp,
        privateAppLegacy: privateAppLegacy
    }
};
final Client hubspotClient = check new Client(config, serviceUrl);

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testDeleteAssociation() returns error? {
    error? response = check hubspotClient->/objects/contacts/["123"]/associations/companies/["456"].delete();
    test:assertTrue(response is (), "Expected no error on successful deletion");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testListAssociations() returns error? {
    CollectionResponseMultiAssociatedObjectWithLabel|error responseResult = hubspotClient->/objects/contacts/["123"]/associations/companies.get();
    if responseResult is error {
        test:assertFail(string `Expected successful response but got error: ${responseResult.message()}`);
    } else {
        CollectionResponseMultiAssociatedObjectWithLabel response = responseResult;
        test:assertTrue(response?.results !is (), "Expected results field to not be nil");
        MultiAssociatedObjectWithLabel[]? results = response.results;
        if results is MultiAssociatedObjectWithLabel[] {
            test:assertTrue(results.length() > 0, "Expected a non-empty results array");
        } else {
            test:assertFail("Expected a non-empty results array");
        }
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchArchiveAssociations() returns error? {
    BatchInputPublicAssociationMultiArchive payload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"}
            }
        ]
    };
    BatchResponseVoid|error responseResult = hubspotClient->/associations/contacts/companies/batch/archive.post(payload);
    if responseResult is error {
        test:assertFail(string `Expected successful response but got error: ${responseResult.message()}`);
    } else {
        BatchResponseVoid response = responseResult;
        test:assertTrue(response?.status !is (), "Expected status field to not be nil");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateDefaultAssociations() returns error? {
    BatchInputPublicDefaultAssociationMultiPost payload = {
        inputs: [
            {
                from: {id: "123"},
                to: {id: "456"}
            }
        ]
    };
    BatchResponsePublicDefaultAssociation|error responseResult = hubspotClient->/associations/contacts/companies/batch/associate/'default.post(payload);
    if responseResult is error {
        test:assertFail(string `Expected successful response but got error: ${responseResult.message()}`);
    } else {
        BatchResponsePublicDefaultAssociation response = responseResult;
        test:assertTrue(response?.results !is (), "Expected results field to not be nil");
        PublicDefaultAssociation[]? results = response.results;
        if results is PublicDefaultAssociation[] {
            test:assertTrue(results.length() > 0, "Expected a non-empty results array");
        } else {
            test:assertFail("Expected a non-empty results array");
        }
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchCreateAssociations() returns error? {
    BatchInputPublicAssociationMultiPost payload = {
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
    BatchResponseLabelsBetweenObjectPair|error responseResult = hubspotClient->/associations/contacts/companies/batch/create.post(payload);
    if responseResult is error {
        test:assertFail(string `Expected successful response but got error: ${responseResult.message()}`);
    } else {
        BatchResponseLabelsBetweenObjectPair response = responseResult;
        test:assertTrue(response?.results !is (), "Expected results field to not be nil");
        LabelsBetweenObjectPair[]? results = response.results;
        if results is LabelsBetweenObjectPair[] {
            test:assertTrue(results.length() > 0, "Expected a non-empty results array");
        } else {
            test:assertFail("Expected a non-empty results array");
        }
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchDeleteSpecificLabels() returns error? {
    BatchInputPublicAssociationMultiPost payload = {
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
    BatchResponseVoid|error responseResult = hubspotClient->/associations/contacts/companies/batch/labels/archive.post(payload);
    if responseResult is error {
        test:assertFail(string `Expected successful response but got error: ${responseResult.message()}`);
    } else {
        BatchResponseVoid response = responseResult;
        test:assertTrue(response?.status !is (), "Expected status field to not be nil");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testBatchReadAssociations() returns error? {
    BatchInputPublicFetchAssociationsBatchRequest payload = {
        inputs: [
            {
                id: "123"
            }
        ]
    };
    BatchResponsePublicAssociationMultiWithLabel|error responseData = hubspotClient->/associations/contacts/companies/batch/read.post(payload);
    if responseData is error {
        test:assertFail(string `Expected successful response but got error: ${responseData.message()}`);
    } else {
        test:assertTrue(responseData?.results !is (), "Expected results field to not be nil");
        PublicAssociationMultiWithLabel[]? results = responseData.results;
        if results is PublicAssociationMultiWithLabel[] {
            test:assertTrue(results.length() > 0, "Expected a non-empty results array");
        } else {
            test:assertFail("Expected a non-empty results array");
        }
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateHighUsageReport() returns error? {
    ReportCreationResponse|error response = hubspotClient->/associations/usage/high\-usage\-report/["12345"].post();
    if response is error {
        test:assertFail(string `Expected successful response but got error: ${response.message()}`);
    } else {
        test:assertTrue(response?.userId !is (), "Expected userId field to not be nil");
    }
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testCreateDefaultAssociation() returns error? {
    BatchResponsePublicDefaultAssociation|error response = hubspotClient->/objects/contacts/["123"]/associations/'default/companies/["456"].put();
    if response is error {
        test:assertFail(string `Expected successful response but got error: ${response.message()}`);
    } else {
        test:assertTrue(response?.results !is (), "Expected results field to not be nil");
        PublicDefaultAssociation[]? results = response.results;
        if results is PublicDefaultAssociation[] {
            test:assertTrue(results.length() > 0, "Expected a non-empty results array");
        }
        test:assertTrue(response?.status !is (), "Expected status field to not be nil");
    }
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
    CreatedResponseLabelsBetweenObjectPair|error response = hubspotClient->/objects/contacts/["123"]/associations/companies/["456"].put(payload);
    if response is error {
        test:assertFail(string `Expected successful response but got error: ${response.message()}`);
    } else {
        test:assertTrue(response?.fromObjectTypeId !is (), "Expected fromObjectTypeId field to not be nil");
        test:assertTrue(response?.toObjectTypeId !is (), "Expected toObjectTypeId field to not be nil");
    }
}
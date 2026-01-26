import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/lang.value;
import ballerina/os;
import ballerina/regex;

const string ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const int MAX_RETRIES = 2;
const decimal RETRY_DELAY_SECONDS = 3.0;

type AnalysisResult record {
    string changeType;
    string[] breakingChanges;
    string[] newFeatures;
    string[] bugFixes;
    string summary;
    decimal confidence;
};

function analyzeWithAnthropic(string gitDiff) returns AnalysisResult|error {
    string apiKey = os:getEnv("ANTHROPIC_API_KEY");
    
    if apiKey == "" {
        return error("ANTHROPIC_API_KEY environment variable is not set");
    }
    
    io:println(string `🔑 Using Anthropic API (${apiKey.length()} chars)`);
    
    string prompt = string `You are analyzing git diff output for a Ballerina connector to determine the semantic version change needed.

GIT DIFF:
${gitDiff}

RULES FOR VERSION CLASSIFICATION:
- MAJOR: Breaking changes (removed/renamed methods, removed/renamed types, changed method signatures, changed field types, removed fields)
- MINOR: Backward-compatible additions (new methods, new types, new optional fields)
- PATCH: Documentation changes, internal refactoring, bug fixes with no API surface changes

Analyze the diff and respond with ONLY a JSON object (no markdown, no explanation):
{
  "changeType": "MAJOR|MINOR|PATCH",
  "breakingChanges": ["list specific breaking changes"],
  "newFeatures": ["list new features/additions"],
  "bugFixes": ["list bug fixes or improvements"],
  "summary": "concise summary of changes",
  "confidence": 0.95
}`;

    http:Client anthropicClient = check new ("https://api.anthropic.com", {
        httpVersion: http:HTTP_1_1,
        timeout: 60
    });
    
    json payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "temperature": 0.1,
        "messages": [{"role": "user", "content": prompt}]
    };
    
    http:Request req = new;
    req.setJsonPayload(payload);
    req.setHeader("anthropic-version", "2023-06-01");
    req.setHeader("x-api-key", apiKey);
    req.setHeader("content-type", "application/json");
    
    io:println("📤 Sending request to Anthropic API...");
    
    json response = {};
    int retryCount = 0;
    boolean success = false;
    
    while !success && retryCount < MAX_RETRIES {
        do {
            http:Response httpResponse = check anthropicClient->post("/v1/messages", req);
            int statusCode = httpResponse.statusCode;
            io:println(string `📥 Response status: ${statusCode}`);
            
            string textResult = check httpResponse.getTextPayload();
            
            if statusCode != 200 {
                io:println(string `⚠️ Response: ${textResult}`);
                if statusCode == 429 {
                    retryCount = retryCount + 1;
                    if retryCount < MAX_RETRIES {
                        io:println(string `⏳ Rate limited. Retry ${retryCount}/${MAX_RETRIES} in ${RETRY_DELAY_SECONDS}s...`);
                        runtime:sleep(RETRY_DELAY_SECONDS);
                        continue;
                    }
                }
                return error(string `Anthropic API returned status ${statusCode}: ${textResult}`);
            }
            
            response = check value:fromJsonString(textResult);
            
            // Check for API errors
            json|error errorCheck = response.'error;
            if errorCheck is json {
                string errorMsg = check errorCheck.message;
                return error(string `Anthropic API Error: ${errorMsg}`);
            }
            
            success = true;
            
        } on fail error e {
            retryCount = retryCount + 1;
            if retryCount < MAX_RETRIES {
                io:println(string `⏳ Request failed. Retry ${retryCount}/${MAX_RETRIES} in ${RETRY_DELAY_SECONDS}s...`);
                runtime:sleep(RETRY_DELAY_SECONDS);
            } else {
                return e;
            }
        }
    }
    
    json contentJson = check response.content;
    json[] content = check contentJson.ensureType();
    string text = check content[0].text;
    
    io:println(string `🔍 Extracted text: ${text}`);
    
    text = regex:replaceAll(text.trim(), "```json|```", "");
    return check value:fromJsonStringWithType(text.trim());
}

public function main(string gitDiffContent) returns error? {
    
    io:println("📊 Analyzing git diff...");
    io:println(string `📏 Diff size: ${gitDiffContent.length()} chars`);
    
    if gitDiffContent.length() == 0 {
        return error("Git diff content is empty");
    }
    
    io:println("🤖 Analyzing with Claude...");
    
    AnalysisResult analysis = check analyzeWithAnthropic(gitDiffContent);
    
    // Output results
    io:println("\n" + repeatString("=", 60));
    io:println("📋 VERSION CHANGE ANALYSIS");
    io:println(repeatString("=", 60));
    io:println(string `
🔖 Version Bump: ${analysis.changeType}
✅ Confidence: ${analysis.confidence}

📝 Summary:
${analysis.summary}`);
    
    if analysis.breakingChanges.length() > 0 {
        io:println("\n⚠️  BREAKING CHANGES:");
        foreach string change in analysis.breakingChanges {
            io:println(string `  - ${change}`);
        }
    }
    
    if analysis.newFeatures.length() > 0 {
        io:println("\n✨ NEW FEATURES:");
        foreach string feature in analysis.newFeatures {
            io:println(string `  - ${feature}`);
        }
    }
    
    if analysis.bugFixes.length() > 0 {
        io:println("\n🐛 IMPROVEMENTS:");
        foreach string fix in analysis.bugFixes {
            io:println(string `  - ${fix}`);
        }
    }
    
    io:println("\n" + repeatString("=", 60));
    
    json resultJson = check analysis.cloneWithType(json);
    check io:fileWriteJson("analysis_result.json", resultJson);
    io:println("\n💾 Saved to: analysis_result.json");
}

function repeatString(string s, int n) returns string {
    string result = "";
    foreach int i in 0 ..< n {
        result = result + s;
    }
    return result;
}
import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/lang.value;
import ballerina/os;
import ballerina/regex;

const string GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent";
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

type DiffResult record {
    string[] added;
    string[] removed;
    string[] unchanged;
};

// Compute diff between two arrays
function computeDiff(string[] oldItems, string[] newItems) returns DiffResult {
    string[] added = [];
    string[] removed = [];
    string[] unchanged = [];
    
    // Find removed items
    foreach string oldItem in oldItems {
        boolean found = false;
        foreach string newItem in newItems {
            if oldItem == newItem {
                found = true;
                break;
            }
        }
        if !found {
            removed.push(oldItem);
        } else {
            unchanged.push(oldItem);
        }
    }
    
    // Find added items
    foreach string newItem in newItems {
        boolean found = false;
        foreach string oldItem in oldItems {
            if newItem == oldItem {
                found = true;
                break;
            }
        }
        if !found {
            added.push(newItem);
        }
    }
    
    return {added, removed, unchanged};
}

// Extract only method names and paths (ultra minimal)
function extractMethodSignatures(string clientCode) returns string[] {
    string[] signatures = [];
    string[] lines = regex:split(clientCode, "\n");
    
    foreach string line in lines {
        if line.includes("resource isolated function") {
            string cleaned = regex:replaceAll(line.trim(), "\\s+", " ");
            string[] parts = regex:split(cleaned, " ");
            if parts.length() >= 5 {
                string method = parts[3];
                string pathPart = parts[4];
                string path = regex:split(pathPart, "\\(")[0];
                signatures.push(method + " " + path);
            }
        }
    }
    
    return signatures;
}

// Extract only type names and field names (no types, no docs)
function extractTypeSignatures(string typesCode) returns string[] {
    string[] signatures = [];
    string[] lines = regex:split(typesCode, "\n");
    boolean inType = false;
    string currentTypeName = "";
    string[] currentFields = [];
    
    foreach string line in lines {
        string trimmed = line.trim();
        
        if trimmed.startsWith("public type") {
            if currentTypeName != "" {
                signatures.push(currentTypeName + ":" + string:'join(",", ...currentFields));
            }
            string[] parts = regex:split(trimmed, "\\s+");
            if parts.length() >= 3 {
                currentTypeName = parts[2];
                currentFields = [];
                inType = true;
            }
        } 
        else if trimmed == "};" && inType {
            if currentTypeName != "" {
                signatures.push(currentTypeName + ":" + string:'join(",", ...currentFields));
                currentTypeName = "";
                currentFields = [];
            }
            inType = false;
        }
        else if inType && !trimmed.startsWith("#") && !trimmed.startsWith("//") && trimmed.length() > 0 {
            string[] fieldParts = regex:split(trimmed, "\\s+");
            if fieldParts.length() >= 2 {
                string fieldName = fieldParts[fieldParts.length() - 2];
                fieldName = regex:replaceAll(fieldName, "[?;:\\[\\]]", "");
                if fieldName.length() > 0 && fieldName != "record" && fieldName != "|}" {
                    currentFields.push(fieldName);
                }
            }
        }
    }
    
    if currentTypeName != "" {
        signatures.push(currentTypeName + ":" + string:'join(",", ...currentFields));
    }
    
    return signatures;
}

// NEW: Build ultra-compact diff summary with counts only for unchanged
function buildCompactDiff(DiffResult methodDiff, DiffResult typeDiff, 
                          int oldMethodCount, int newMethodCount,
                          int oldTypeCount, int newTypeCount) returns string {
    
    string summary = string `M:${oldMethodCount}→${newMethodCount} T:${oldTypeCount}→${newTypeCount}`;
    
    // Only show what changed (not unchanged items)
    if methodDiff.removed.length() > 0 {
        summary += string `
-M:${string:'join(",", ...methodDiff.removed)}`;
    }
    
    if methodDiff.added.length() > 0 {
        summary += string `
+M:${string:'join(",", ...methodDiff.added)}`;
    }
    
    if typeDiff.removed.length() > 0 {
        summary += string `
-T:${string:'join(",", ...typeDiff.removed)}`;
    }
    
    if typeDiff.added.length() > 0 {
        summary += string `
+T:${string:'join(",", ...typeDiff.added)}`;
    }
    
    return summary;
}

function analyzeWithGemini(string diffSummary) returns AnalysisResult|error {
    string apiKey = os:getEnv("GEMINI_API_KEY");
    
    string prompt = string `Analyze API changes. M=methods, T=types, -=removed, +=added.

${diffSummary}

Rules: MAJOR=removed/changed, MINOR=added, PATCH=docs only

JSON only:
{"changeType":"MAJOR|MINOR|PATCH","breakingChanges":[],"newFeatures":[],"bugFixes":[],"summary":"...","confidence":0.95}`;

    http:Client geminiClient = check new (GEMINI_API_URL);
    
    json payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 512}
    };
    
    json response = {};
    int retryCount = 0;
    boolean success = false;
    
    while !success && retryCount < MAX_RETRIES {
        do {
            response = check geminiClient->post(string `?key=${apiKey}`, payload);
            success = true;
        } on fail error e {
            retryCount = retryCount + 1;
            if retryCount < MAX_RETRIES {
                io:println(string `⏳ Rate limited. Retry ${retryCount}/${MAX_RETRIES} in ${RETRY_DELAY_SECONDS}s...`);
                runtime:sleep(RETRY_DELAY_SECONDS);
            } else {
                return e;
            }
        }
    }
    
    json candidatesJson = check response.candidates;
    json[] candidates = check candidatesJson.ensureType();
    json content = check candidates[0].content;
    json partsJson = check content.parts;
    json[] parts = check partsJson.ensureType();
    string text = check parts[0].text;
    
    text = regex:replaceAll(text.trim(), "```json|```", "");
    return check value:fromJsonStringWithType(text.trim());
}

function analyzeWithAnthropic(string diffSummary) returns AnalysisResult|error {
    string apiKey = os:getEnv("ANTHROPIC_API_KEY");
    
    string prompt = string `Analyze API changes. M=methods, T=types, -=removed, +=added.

${diffSummary}

Rules: MAJOR=removed/changed, MINOR=added, PATCH=docs only

JSON only:
{"changeType":"MAJOR|MINOR|PATCH","breakingChanges":[],"newFeatures":[],"bugFixes":[],"summary":"...","confidence":0.95}`;

    http:Client anthropicClient = check new (ANTHROPIC_API_URL);
    
    json payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 512,
        "temperature": 0.1,
        "messages": [{"role": "user", "content": prompt}]
    };
    
    map<string> headers = {
        "anthropic-version": "2023-06-01",
        "x-api-key": apiKey,
        "content-type": "application/json"
    };
    
    json response = {};
    int retryCount = 0;
    boolean success = false;
    
    while !success && retryCount < MAX_RETRIES {
        do {
            response = check anthropicClient->post("/", payload, headers);
            success = true;
        } on fail error e {
            retryCount = retryCount + 1;
            if retryCount < MAX_RETRIES {
                io:println(string `⏳ Rate limited. Retry ${retryCount}/${MAX_RETRIES} in ${RETRY_DELAY_SECONDS}s...`);
                runtime:sleep(RETRY_DELAY_SECONDS);
            } else {
                io:println(string `❌ API Error: ${e.message()}`);
                return e;
            }
        }
    }
    
    // Debug: Print the raw response
    io:println(string `🔍 Debug - Raw response: ${response.toJsonString()}`);
    
    // Check if there's an error in the response
    if response is map<json> && response.hasKey("error") {
        json errorJson = check response.'error;
        string errorMsg = check errorJson.message;
        return error(string `Anthropic API Error: ${errorMsg}`);
    }
    
    json contentJson = check response.content;
    json[] content = check contentJson.ensureType();
    string text = check content[0].text;
    
    io:println(string `🔍 Debug - Extracted text: ${text}`);
    
    text = regex:replaceAll(text.trim(), "```json|```", "");
    return check value:fromJsonStringWithType(text.trim());
}

public function main(string oldClientPath, string oldTypesPath, 
                      string newClientPath, string newTypesPath) returns error? {
    
    io:println("📝 Reading files...");
    string oldClient = check io:fileReadString(oldClientPath);
    string oldTypes = check io:fileReadString(oldTypesPath);
    string newClient = check io:fileReadString(newClientPath);
    string newTypes = check io:fileReadString(newTypesPath);
    
    io:println("🔍 Extracting signatures...");
    string[] oldMethods = extractMethodSignatures(oldClient);
    string[] newMethods = extractMethodSignatures(newClient);
    string[] oldTypesSigs = extractTypeSignatures(oldTypes);
    string[] newTypesSigs = extractTypeSignatures(newTypes);
    
    io:println("📊 Computing diff...");
    DiffResult methodDiff = computeDiff(oldMethods, newMethods);
    DiffResult typeDiff = computeDiff(oldTypesSigs, newTypesSigs);
    
    // Build ultra-compact diff summary
    string diffSummary = buildCompactDiff(
        methodDiff, typeDiff,
        oldMethods.length(), newMethods.length(),
        oldTypesSigs.length(), newTypesSigs.length()
    );
    
    io:println(string `📏 Diff size: ${diffSummary.length()} chars`);
    
    string envProvider = os:getEnv("LLM_PROVIDER");
    string llmProvider = envProvider == "" ? "gemini" : envProvider;
    io:println(string `🤖 Analyzing with ${llmProvider.toUpperAscii()}...`);
    
    AnalysisResult analysis;
    if llmProvider == "gemini" {
        analysis = check analyzeWithGemini(diffSummary);
    } else {
        analysis = check analyzeWithAnthropic(diffSummary);
    }
    
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
import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/lang.value;
import ballerina/os;
import ballerina/regex;

const string GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
const string ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const int MAX_RETRIES = 3;
const decimal RETRY_DELAY_SECONDS = 5.0;

type AnalysisResult record {
    string changeType;
    string[] breakingChanges;
    string[] newFeatures;
    string[] bugFixes;
    string summary;
    decimal confidence;
};

type ExtractedSignatures record {
    string[] methodSignatures;
    string[] typeSignatures;
};

// Extract minimal method signatures (just names and parameter types)
function extractMethodSignatures(string clientCode) returns string[] {
    string[] signatures = [];
    string[] lines = regex:split(clientCode, "\n");
    
    foreach string line in lines {
        string trimmed = line.trim();
        if trimmed.includes("resource isolated function") {
            // Extract just the method signature line
            // Example: "resource isolated function post associations/..."
            string signature = regex:replaceAll(trimmed, "\\s+", " ");
            // Remove comments and excess whitespace
            signature = regex:split(signature, "//")[0].trim();
            if signature.length() > 0 {
                signatures.push(signature);
            }
        }
    }
    
    return signatures;
}

// Extract minimal type signatures (just type names and field names, no docs)
function extractTypeSignatures(string typesCode) returns string[] {
    string[] signatures = [];
    string[] lines = regex:split(typesCode, "\n");
    boolean inType = false;
    string currentTypeName = "";
    string[] currentFields = [];
    
    foreach string line in lines {
        string trimmed = line.trim();
        
        // Start of a type definition
        if trimmed.startsWith("public type") || trimmed.startsWith("public record") {
            if currentTypeName != "" {
                // Save previous type
                signatures.push(currentTypeName + ": " + string:'join(", ", ...currentFields));
            }
            // Extract type name
            string[] parts = regex:split(trimmed, "\\s+");
            if parts.length() >= 3 {
                currentTypeName = parts[2];
                currentFields = [];
                inType = true;
            }
        } 
        // End of type definition
        else if trimmed == "};" && inType {
            if currentTypeName != "" {
                signatures.push(currentTypeName + ": " + string:'join(", ", ...currentFields));
                currentTypeName = "";
                currentFields = [];
            }
            inType = false;
        }
        // Field within type
        else if inType && !trimmed.startsWith("#") && !trimmed.startsWith("//") && trimmed.length() > 0 {
            // Extract field name (before the type)
            string[] fieldParts = regex:split(trimmed, "\\s+");
            if fieldParts.length() >= 2 {
                string fieldName = fieldParts[fieldParts.length() - 2];
                // Remove special characters
                fieldName = regex:replaceAll(fieldName, "[?;:]", "");
                if fieldName.length() > 0 && fieldName != "record" && fieldName != "|}" {
                    currentFields.push(fieldName);
                }
            }
        }
    }
    
    // Save last type if any
    if currentTypeName != "" {
        signatures.push(currentTypeName + ": " + string:'join(", ", ...currentFields));
    }
    
    return signatures;
}

function analyzeWithGemini(string oldCode, string newCode) returns AnalysisResult|error {
    string apiKey = os:getEnv("GEMINI_API_KEY");
    
    string prompt = string `Analyze changes between two versions of a Ballerina connector for semantic versioning.

RULES:
- MAJOR: Breaking changes (removed methods, removed fields, parameter changes)
- MINOR: New features (new methods, new types, new fields)
- PATCH: Bug fixes, docs, internal changes

OLD VERSION:
${oldCode}

NEW VERSION:
${newCode}

Respond with ONLY valid JSON (no markdown):
{
  "changeType": "MAJOR|MINOR|PATCH",
  "breakingChanges": [],
  "newFeatures": [],
  "bugFixes": [],
  "summary": "brief summary",
  "confidence": 0.95
}`;

    http:Client geminiClient = check new (GEMINI_API_URL);
    
    json payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 1024
        }
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
    
    text = text.trim();
    text = regex:replaceAll(text, "```json", "");
    text = regex:replaceAll(text, "```", "");
    text = text.trim();
    
    AnalysisResult result = check value:fromJsonStringWithType(text);
    return result;
}

function analyzeWithAnthropic(string oldCode, string newCode) returns AnalysisResult|error {
    string apiKey = os:getEnv("ANTHROPIC_API_KEY");
    
    string prompt = string `Analyze changes between two versions of a Ballerina connector for semantic versioning.

RULES:
- MAJOR: Breaking changes (removed methods, removed fields, parameter changes)
- MINOR: New features (new methods, new types, new fields)
- PATCH: Bug fixes, docs, internal changes

OLD VERSION:
${oldCode}

NEW VERSION:
${newCode}

Respond with ONLY valid JSON:
{
  "changeType": "MAJOR|MINOR|PATCH",
  "breakingChanges": [],
  "newFeatures": [],
  "bugFixes": [],
  "summary": "brief summary",
  "confidence": 0.95
}`;

    http:Client anthropicClient = check new (ANTHROPIC_API_URL, {
        auth: {token: apiKey}
    });
    
    json payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "temperature": 0.1,
        "messages": [{
            "role": "user",
            "content": prompt
        }]
    };
    
    map<string> headers = {
        "anthropic-version": "2023-06-01"
    };
    
    json response = check anthropicClient->post("/", payload, headers);
    json contentJson = check response.content;
    json[] content = check contentJson.ensureType();
    string text = check content[0].text;
    
    text = text.trim();
    text = regex:replaceAll(text, "```json", "");
    text = regex:replaceAll(text, "```", "");
    text = text.trim();
    
    AnalysisResult result = check value:fromJsonStringWithType(text);
    return result;
}

public function main(string oldClientPath, string oldTypesPath, 
                      string newClientPath, string newTypesPath) returns error? {
    
    io:println("📝 Reading files...");
    string oldClient = check io:fileReadString(oldClientPath);
    string oldTypes = check io:fileReadString(oldTypesPath);
    string newClient = check io:fileReadString(newClientPath);
    string newTypes = check io:fileReadString(newTypesPath);
    
    io:println("🔍 Extracting minimal signatures...");
    string[] oldMethods = extractMethodSignatures(oldClient);
    string[] newMethods = extractMethodSignatures(newClient);
    string[] oldTypesSigs = extractTypeSignatures(oldTypes);
    string[] newTypesSigs = extractTypeSignatures(newTypes);
    
    // Create compact comparison format
    string oldCode = string `METHODS (${oldMethods.length()}):
${string:'join("\n", ...oldMethods)}

TYPES (${oldTypesSigs.length()}):
${string:'join("\n", ...oldTypesSigs)}`;
    
    string newCode = string `METHODS (${newMethods.length()}):
${string:'join("\n", ...newMethods)}

TYPES (${newTypesSigs.length()}):
${string:'join("\n", ...newTypesSigs)}`;
    
    io:println(string `📊 Old: ${oldMethods.length()} methods, ${oldTypesSigs.length()} types`);
    io:println(string `📊 New: ${newMethods.length()} methods, ${newTypesSigs.length()} types`);
    io:println(string `📏 Payload size: ~${oldCode.length() + newCode.length()} chars`);
    
    string envProvider = os:getEnv("LLM_PROVIDER");
    string llmProvider = envProvider == "" ? "gemini" : envProvider;
    io:println(string `🤖 Analyzing with ${llmProvider.toUpperAscii()}...`);
    
    AnalysisResult analysis;
    if llmProvider == "gemini" {
        analysis = check analyzeWithGemini(oldCode, newCode);
    } else {
        analysis = check analyzeWithAnthropic(oldCode, newCode);
    }
    
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
    io:println("\n💾 Results saved to: analysis_result.json");
}

function repeatString(string s, int n) returns string {
    string result = "";
    foreach int i in 0 ..< n {
        result = result + s;
    }
    return result;
}
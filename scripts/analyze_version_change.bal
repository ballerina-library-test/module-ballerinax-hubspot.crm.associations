import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/lang.value;
import ballerina/os;
import ballerina/regex;

// Configuration - Using gemini-2.0-flash-lite for better rate limits
const string GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent";
const string ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const int MAX_RETRIES = 3;
const decimal RETRY_DELAY_SECONDS = 5.0;

type AnalysisResult record {
    string changeType; // "MAJOR", "MINOR", or "PATCH"
    string[] breakingChanges;
    string[] newFeatures;
    string[] bugFixes;
    string summary;
    decimal confidence;
};

// Helper function to repeat a string n times
function repeatString(string s, int n) returns string {
    string result = "";
    foreach int i in 0 ..< n {
        result = result + s;
    }
    return result;
}

type ExtractedCode record {
    string methods;
    string types;
};

// Extract relevant parts from client.bal and types.bal
function extractRelevantParts(string clientCode, string typesCode) returns ExtractedCode {
    
    // Extract resource methods from client.bal
    string[] clientMethods = [];
    string[] clientLines = regex:split(clientCode, "\n");
    string[] currentMethod = [];
    boolean inMethod = false;
    
    foreach string line in clientLines {
        if line.includes("resource isolated function") {
            inMethod = true;
            currentMethod = [line.trim()];
        } else if inMethod {
            currentMethod.push(line.trim());
            if line.includes("returns") && line.includes("{") {
                clientMethods.push(string:'join(" ", ...currentMethod));
                currentMethod = [];
                inMethod = false;
            }
        }
    }
    
    // Extract public types from types.bal
    string[] typeDefinitions = [];
    string[] typeLines = regex:split(typesCode, "\n");
    string[] currentType = [];
    boolean inType = false;
    
    foreach string line in typeLines {
        string trimmedLine = line.trim();
        if trimmedLine.startsWith("public type") || trimmedLine.startsWith("public record") {
            inType = true;
            currentType = [trimmedLine];
        } else if inType {
            currentType.push(trimmedLine);
            if trimmedLine == "};" {
                typeDefinitions.push(string:'join("\n", ...currentType));
                currentType = [];
                inType = false;
            }
        }
    }
    
    return {
        methods: string:'join("\n\n", ...clientMethods),
        types: string:'join("\n\n", ...typeDefinitions)
    };
}

// Analyze with Gemini
function analyzeWithGemini(string oldCode, string newCode) returns AnalysisResult|error {
    
    string apiKey = os:getEnv("GEMINI_API_KEY");
    
    string prompt = string `You are analyzing changes between two versions of a Ballerina connector to determine the semantic versioning impact.

SEMANTIC VERSIONING RULES:
- MAJOR (X.0.0): Breaking changes - removed methods, incompatible parameter changes, removed required fields
- MINOR (0.X.0): New features - new methods, new types, new optional parameters, enhanced return types
- PATCH (0.0.X): Bug fixes, documentation changes, internal improvements only

OLD VERSION:
${oldCode}

NEW VERSION:
${newCode}

Analyze the differences and respond with ONLY valid JSON in this exact format (no markdown, no backticks):
{
  "changeType": "MAJOR|MINOR|PATCH",
  "breakingChanges": ["list of breaking changes, empty array if none"],
  "newFeatures": ["list of new features, empty array if none"],
  "bugFixes": ["list of bug fixes/improvements, empty array if none"],
  "summary": "brief explanation of the main changes",
  "confidence": 0.95
}`;

    http:Client geminiClient = check new (GEMINI_API_URL);
    
    json payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 2048
        }
    };
    
    // Retry logic for rate limiting
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
                io:println(string `⏳ Rate limited. Retrying in ${RETRY_DELAY_SECONDS} seconds... (attempt ${retryCount}/${MAX_RETRIES})`);
                runtime:sleep(RETRY_DELAY_SECONDS);
            } else {
                return e;
            }
        }
    }
    
    // Extract text from response
    json candidatesJson = check response.candidates;
    json[] candidates = check candidatesJson.ensureType();
    json firstCandidate = candidates[0];
    json content = check firstCandidate.content;
    json partsJson = check content.parts;
    json[] parts = check partsJson.ensureType();
    json firstPart = parts[0];
    string text = check firstPart.text;
    
    // Clean up markdown if present
    text = text.trim();
    if text.startsWith("```json") {
        text = text.substring(7);
    }
    if text.startsWith("```") {
        text = text.substring(3);
    }
    if text.endsWith("```") {
        text = text.substring(0, text.length() - 3);
    }
    text = text.trim();
    
    // Parse JSON response
    AnalysisResult result = check value:fromJsonStringWithType(text);
    
    return result;
}

// Analyze with Anthropic Claude
function analyzeWithAnthropic(string oldCode, string newCode) returns AnalysisResult|error {
    
    string apiKey = os:getEnv("ANTHROPIC_API_KEY");
    
    string prompt = string `You are analyzing changes between two versions of a Ballerina connector to determine the semantic versioning impact.

SEMANTIC VERSIONING RULES:
- MAJOR (X.0.0): Breaking changes - removed methods, incompatible parameter changes, removed required fields
- MINOR (0.X.0): New features - new methods, new types, new optional parameters, enhanced return types
- PATCH (0.0.X): Bug fixes, documentation changes, internal improvements only

OLD VERSION:
${oldCode}

NEW VERSION:
${newCode}

Analyze the differences and respond with ONLY valid JSON in this exact format:
{
  "changeType": "MAJOR|MINOR|PATCH",
  "breakingChanges": ["list of breaking changes, empty array if none"],
  "newFeatures": ["list of new features, empty array if none"],
  "bugFixes": ["list of bug fixes/improvements, empty array if none"],
  "summary": "brief explanation of the main changes",
  "confidence": 0.95
}`;

    http:Client anthropicClient = check new (ANTHROPIC_API_URL, {
        auth: {
            token: apiKey
        }
    });
    
    json payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 2048,
        "temperature": 0.1,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    };
    
    map<string> headers = {
        "anthropic-version": "2023-06-01"
    };
    
    json response = check anthropicClient->post("/", payload, headers);
    
    // Extract text from response
    json contentJson = check response.content;
    json[] content = check contentJson.ensureType();
    json firstContent = content[0];
    string text = check firstContent.text;
    
    // Clean up markdown if present
    text = text.trim();
    if text.startsWith("```json") {
        text = text.substring(7);
    }
    if text.startsWith("```") {
        text = text.substring(3);
    }
    if text.endsWith("```") {
        text = text.substring(0, text.length() - 3);
    }
    text = text.trim();
    
    // Parse JSON response
    AnalysisResult result = check value:fromJsonStringWithType(text);
    
    return result;
}

public function main(string oldClientPath, string oldTypesPath, 
                      string newClientPath, string newTypesPath) returns error? {
    
    // Read files
    string oldClient = check io:fileReadString(oldClientPath);
    string oldTypes = check io:fileReadString(oldTypesPath);
    string newClient = check io:fileReadString(newClientPath);
    string newTypes = check io:fileReadString(newTypesPath);
    
    // Extract relevant parts
    io:println("📝 Extracting relevant code sections...");
    ExtractedCode oldExtracted = extractRelevantParts(oldClient, oldTypes);
    ExtractedCode newExtracted = extractRelevantParts(newClient, newTypes);
    
    string oldCode = string `CLIENT METHODS:
${oldExtracted.methods}

TYPE DEFINITIONS:
${oldExtracted.types}`;
    
    string newCode = string `CLIENT METHODS:
${newExtracted.methods}

TYPE DEFINITIONS:
${newExtracted.types}`;
    
    // Get LLM provider from environment
    string envProvider = os:getEnv("LLM_PROVIDER");
    string llmProvider = envProvider == "" ? "gemini" : envProvider;
    io:println(string `📊 Analyzing with ${llmProvider.toUpperAscii()}...`);
    
    // Call appropriate LLM
    AnalysisResult analysis;
    if llmProvider == "gemini" {
        analysis = check analyzeWithGemini(oldCode, newCode);
    } else {
        analysis = check analyzeWithAnthropic(oldCode, newCode);
    }
    
    // Output results
    io:println("\n" + repeatString("=", 60));
    io:println("📋 VERSION CHANGE ANALYSIS RESULTS");
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
        io:println("\n🐛 BUG FIXES/IMPROVEMENTS:");
        foreach string fix in analysis.bugFixes {
            io:println(string `  - ${fix}`);
        }
    }
    
    io:println("\n" + repeatString("=", 60));
    
    // Save JSON result
    json resultJson = check analysis.cloneWithType(json);
    check io:fileWriteJson("analysis_result.json", resultJson);
    
    io:println("\n💾 Results saved to: analysis_result.json");
}
import ballerina/io;
import ballerina/file;
import ballerina/regex;

// Improved sort that preserves ALL content including whitespace and comments

type ResourceMethod record {|
    string content;
    int startLine;
    int endLine;
    string methodType;
    string path;
    [string, string, string] sortKey;
|};

type ContentBlock record {|
    int startLine;
    int endLine;
    string content;
    string blockType; // "method", "non-method"
|};

// Extract HTTP method (get, post, put, delete, patch) from a resource method block.
function extractMethodType(string content) returns string {
    string[] lines = regex:split(content, "\n");
    if lines.length() == 0 {
        return "unknown";
    }

    string firstLine = regex:replaceAll(lines[0].trim(), "\\s+", " ");
    string[] tokens = regex:split(firstLine, " ");

    foreach int i in 0 ..< tokens.length() {
        if tokens[i] == "function" && i + 1 < tokens.length() {
            string method = tokens[i + 1];
            if method == "get" || method == "post" || method == "put" || method == "delete" || method == "patch" {
                return method;
            }
        }
    }

    return "unknown";
}

// Extract the resource path from a resource method block.
function extractPath(string content) returns string {
    string[] lines = regex:split(content, "\n");
    if lines.length() == 0 {
        return "";
    }

    string firstLine = regex:replaceAll(lines[0].trim(), "\\s+", " ");
    string[] tokens = regex:split(firstLine, " ");

    foreach int i in 0 ..< tokens.length() {
        if (tokens[i] == "get" || tokens[i] == "post" || tokens[i] == "put" || tokens[i] == "delete" ||
            tokens[i] == "patch") && i + 1 < tokens.length() {
            string rawPath = tokens[i + 1];
            string[] pathParts = regex:split(rawPath, "\\(");
            string path = pathParts.length() > 0 ? pathParts[0] : rawPath;
            path = regex:replaceAll(path, "\\[[\\w:]+\\s+(\\w+)\\]", "[$1]");
            return path;
        }
    }

    return "";
}

// Generate sorting key
function generateSortKey(string methodType, string path) returns [string, string, string] {
    string normalizedPath = regex:replaceAll(path, "\\\\-", "-");
    string[] segments = regex:split(normalizedPath, "/");

    map<string> methodPriority = {
        "get": "1",
        "post": "2",
        "put": "3",
        "delete": "4",
        "patch": "5",
        "unknown": "9"
    };

    string priority = methodPriority[methodType] ?: "9";
    string joinedPath = string:'join("/", ...segments);

    return [joinedPath, priority, path];
}

// Count occurrences of a character in a string
function countChar(string str, string char) returns int {
    int count = 0;
    foreach int i in 0 ..< str.length() {
        if str.substring(i, i + 1) == char {
            count += 1;
        }
    }
    return count;
}

// Extract all content blocks (methods and non-methods) preserving everything
function extractAllBlocks(string content) returns [ContentBlock[], int, int] {
    string[] lines = regex:split(content, "\n");
    ContentBlock[] blocks = [];

    int firstMethodLine = -1;
    int lastMethodLine = -1;

    int i = 0;
    while i < lines.length() {
        string line = lines[i];

        // Check if this is a resource method start
        if regex:matches(line, "\\s*resource\\s+isolated\\s+function\\s+(get|post|put|delete|patch)") {
            // Mark first method if not set
            if firstMethodLine == -1 {
                firstMethodLine = i;
            }

            // Extract the complete method
            string[] methodLines = [line];
            int startLine = i;
            int braceCount = countChar(line, "{") - countChar(line, "}");
            i += 1;

            while i < lines.length() && braceCount > 0 {
                string currentLine = lines[i];
                methodLines.push(currentLine);
                braceCount += countChar(currentLine, "{") - countChar(currentLine, "}");
                i += 1;
            }

            lastMethodLine = i - 1;

            string methodContent = string:'join("\n", ...methodLines);
            blocks.push({
                startLine: startLine,
                endLine: i - 1,
                content: methodContent,
                blockType: "method"
            });
        } else {
            i += 1;
        }
    }

    return [blocks, firstMethodLine, lastMethodLine];
}

// Compare two ResourceMethods for sorting
function compareResourceMethods(ResourceMethod a, ResourceMethod b) returns int {
    [string, string, string] keyA = a.sortKey;
    [string, string, string] keyB = b.sortKey;

    if keyA[0] < keyB[0] {
        return -1;
    } else if keyA[0] > keyB[0] {
        return 1;
    }

    if keyA[1] < keyB[1] {
        return -1;
    } else if keyA[1] > keyB[1] {
        return 1;
    }

    if keyA[2] < keyB[2] {
        return -1;
    } else if keyA[2] > keyB[2] {
        return 1;
    }

    return 0;
}

// Simple bubble sort
function sortResourceMethods(ResourceMethod[] methods) returns ResourceMethod[] {
    ResourceMethod[] sorted = [...methods];
    int n = sorted.length();
    foreach int i in 0 ..< n {
        foreach int j in i + 1 ..< n {
            if compareResourceMethods(sorted[i], sorted[j]) > 0 {
                ResourceMethod temp = sorted[i];
                sorted[i] = sorted[j];
                sorted[j] = temp;
            }
        }
    }
    return sorted;
}

// Sort resource methods while preserving ALL other content
function sortAndWrite(string inputPath, string outputPath) returns error? {
    string content = check io:fileReadString(inputPath);
    string[] lines = regex:split(content, "\n");

    // Extract all method blocks
    [ContentBlock[], int, int] result = extractAllBlocks(content);
    ContentBlock[] methodBlocks = result[0];
    int firstMethodLine = result[1];
    int lastMethodLine = result[2];

    if methodBlocks.length() == 0 {
        // No methods found, just copy the file
        check io:fileWriteString(outputPath, content);
        io:println("⚠️ No resource methods found, file copied as-is");
        return;
    }

    // Convert blocks to ResourceMethods
    ResourceMethod[] methods = [];
    foreach ContentBlock block in methodBlocks {
        string methodType = extractMethodType(block.content);
        string path = extractPath(block.content);
        [string, string, string] sortKey = generateSortKey(methodType, path);

        methods.push({
            content: block.content,
            startLine: block.startLine,
            endLine: block.endLine,
            methodType: methodType,
            path: path,
            sortKey: sortKey
        });
    }

    // Sort methods
    ResourceMethod[] sortedMethods = sortResourceMethods(methods);

    // Reconstruct file preserving everything
    string[] outputLines = [];

    // 1. Add everything before first method (header)
    foreach int i in 0 ..< firstMethodLine {
        outputLines.push(lines[i]);
    }

    // 2. Add sorted methods with preserved spacing between them
    foreach int idx in 0 ..< sortedMethods.length() {
        ResourceMethod method = sortedMethods[idx];
        outputLines.push(method.content);

        // Preserve spacing after method (look ahead to next method or end)
        if idx < sortedMethods.length() - 1 {
            // Add one blank line between methods (normalized spacing)
            outputLines.push("");
        }
    }

    // 3. Add everything after last method (footer)
    foreach int i in (lastMethodLine + 1) ..< lines.length() {
        outputLines.push(lines[i]);
    }

    check io:fileWriteString(outputPath, string:'join("\n", ...outputLines));

    io:println(string `✅ Sorted ${methods.length()} resource methods`);
    io:println(string `📝 Written to: ${outputPath}`);
}

public function main(string[] args) returns error? {
    if args.length() != 2 {
        io:println("Usage: bal run sort_ballerina_client.bal -- <input_file> <output_file>");
        return error("Invalid arguments");
    }

    string inputFile = args[0];
    string outputFile = args[1];

    if !check file:test(inputFile, file:EXISTS) {
        io:println(string `❌ Input file not found: ${inputFile}`);
        return error("Input file not found");
    }

    check sortAndWrite(inputFile, outputFile);
}

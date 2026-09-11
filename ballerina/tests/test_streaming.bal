// Copyright (c) 2025 WSO2 LLC (http://www.wso2.com).
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

import ballerina/ai;
import ballerina/test;

const STREAM_SERVICE_URL = "http://localhost:8081/sse";

isolated function chatStreamProvider(string scenario) returns ModelProvider|ai:Error =>
    new (API_KEY, GPT_4_TURBO, string `${STREAM_SERVICE_URL}/${scenario}`, apiType = CHAT_COMPLETIONS);

isolated function responsesStreamProvider(string scenario) returns ModelProvider|ai:Error =>
    new (API_KEY, GPT_4O, string `${STREAM_SERVICE_URL}/${scenario}`, apiType = RESPONSES);

// Drains a chunk stream into a list, so a test can assert over the whole sequence.
isolated function collectChunks(stream<ai:ChatCompletionChunk, ai:Error?> chunks)
        returns ai:ChatCompletionChunk[]|ai:Error {
    ai:ChatCompletionChunk[] collected = [];
    while true {
        record {|ai:ChatCompletionChunk value;|}|ai:Error? next = chunks.next();
        if next is () {
            return collected;
        }
        if next is ai:Error {
            return next;
        }
        collected.push(next.value);
    }
}

// Concatenates every text fragment in a chunk sequence.
isolated function joinContent(ai:ChatCompletionChunk[] chunks) returns string {
    string text = "";
    foreach ai:ChatCompletionChunk chunk in chunks {
        if chunk is ai:ChatCompletionTextChunk {
            text += chunk.content;
        }
    }
    return text;
}

// Concatenates every reasoning fragment in a chunk sequence.
isolated function joinReasoning(ai:ChatCompletionChunk[] chunks) returns string {
    string reasoning = "";
    foreach ai:ChatCompletionChunk chunk in chunks {
        if chunk is ai:ChatCompletionReasoningChunk {
            reasoning += chunk.reasoning;
        }
    }
    return reasoning;
}

// Accumulates streamed tool-call fragments the way a consumer of `ai:ChatCompletionChunk` is
// expected to: keyed by `index`, with name and argument fragments joined in arrival order.
isolated function accumulateToolCalls(ai:ChatCompletionChunk[] chunks) returns map<[string, string]> {
    map<[string, string]> accumulated = {};
    foreach ai:ChatCompletionChunk chunk in chunks {
        if chunk !is ai:ChatCompletionToolCallChunk {
            continue;
        }
        foreach ai:ToolCallFragment fragment in chunk.toolCalls {
            string key = fragment.index.toString();
            [string, string] entry = accumulated[key] ?: ["", ""];
            entry[0] += fragment?.name ?: "";
            entry[1] += fragment?.arguments ?: "";
            accumulated[key] = entry;
        }
    }
    return accumulated;
}

// Returns the finish reason of the last stop chunk in the sequence.
isolated function finalFinishReason(ai:ChatCompletionChunk[] chunks) returns ai:FinishReason? {
    ai:FinishReason? finishReason = ();
    foreach ai:ChatCompletionChunk chunk in chunks {
        if chunk is ai:ChatCompletionStopChunk {
            finishReason = chunk.finishReason;
        }
    }
    return finishReason;
}

// The kind of each chunk, in arrival order - a stronger assertion than field presence,
// since it also catches chunks that should never have been emitted at all.
isolated function chunkKinds(ai:ChatCompletionChunk[] chunks) returns string[] {
    string[] kinds = [];
    foreach ai:ChatCompletionChunk chunk in chunks {
        if chunk is ai:ChatCompletionTextChunk {
            kinds.push("text");
        } else if chunk is ai:ChatCompletionReasoningChunk {
            kinds.push("reasoning");
        } else if chunk is ai:ChatCompletionToolCallChunk {
            kinds.push("toolCall");
        } else {
            kinds.push("stop");
        }
    }
    return kinds;
}

// ===== Chat Completions streaming =====

@test:Config
function testChatStreamText() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Hello world");
    test:assertEquals(finalFinishReason(chunks), ai:STOP);
    // The opening delta carries `role` alongside its content, and `role` is no longer
    // part of the contract - so it yields a text chunk only. The trailing usage-only
    // chunk carries no choice at all and maps to nothing, its token counts going to the
    // observability span instead. Asserting the kinds catches any spurious extra chunk.
    test:assertEquals(chunkKinds(chunks), ["text", "text", "stop"]);
}

@test:Config
function testChatStreamCarriesResponseMetadata() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertTrue(chunks.length() > 0, "Expected at least one chunk");
    test:assertEquals(chunks[0]?.id, "chatcmpl-1");
}

// A role-only opening delta carries nothing once `role` is gone, so it must map to no
// chunk at all rather than to an empty one.
@test:Config
function testChatStreamSkipsRoleOnlyChunk() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("roleonly");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(chunkKinds(chunks), ["text", "stop"]);
    test:assertEquals(joinContent(chunks), "Hi");
}

// One wire chunk carrying a content fragment and a finish reason together must fan out
// into two normalized chunks, in order, both stamped with the completion id.
@test:Config
function testChatStreamFansOutCombinedChunk() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("combined");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(chunkKinds(chunks), ["text", "stop"]);
    test:assertEquals(joinContent(chunks), "All done.");
    test:assertEquals(finalFinishReason(chunks), ai:STOP);
    test:assertEquals(chunks[0]?.id, "chatcmpl-combined");
    test:assertEquals(chunks[1]?.id, "chatcmpl-combined");
}

@test:Config
function testChatStreamToolCalls() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("tools");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Weather and time?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    map<[string, string]> toolCalls = accumulateToolCalls(chunks);
    test:assertEquals(toolCalls["0"], ["getWeather", string `{"city":"Colombo"}`]);
    test:assertEquals(toolCalls["1"], ["getTime", "{}"]);
    test:assertEquals(finalFinishReason(chunks), ai:TOOL_CALLS);
}

@test:Config
function testChatStreamReasoningFragments() returns ai:Error? {
    ModelProvider model = check chatStreamProvider("reasoning");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "What is 6 times 7?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinReasoning(chunks), "Let me think");
    test:assertEquals(joinContent(chunks), "42");
}

@test:Config
function testChatStreamSurfacesMidStreamErrorFrame() returns error? {
    ModelProvider model = check chatStreamProvider("midstreamerror");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    // A generation cut short must not look like a clean, short answer.
    test:assertTrue(result is ai:Error, "Expected the mid-stream error frame to fail the stream");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("Rate limit reached for gpt-4-turbo"),
            string `Unexpected error message: ${err.message()}`);
}

@test:Config
function testChatStreamSurfacesMalformedFrame() returns error? {
    ModelProvider model = check chatStreamProvider("malformed");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    test:assertTrue(result is ai:Error, "Expected a malformed frame to fail the stream");
    test:assertTrue(result is ai:LlmInvalidResponseError,
            "A malformed chunk is an invalid response from the model");
}

@test:Config
function testChatStreamSurfacesHttpErrorStatus() returns error? {
    ModelProvider model = check chatStreamProvider("unauthorized");
    stream<ai:ChatCompletionChunk, ai:Error?>|ai:Error result =
        model->chatStream({role: ai:USER, content: "Say hello"});

    test:assertTrue(result is ai:Error, "Expected a 401 to fail before the stream opens");
    ai:Error err = <ai:Error>result;
    // The caller needs OpenAI's own message, not just "the stream could not be opened".
    test:assertTrue(err.message().includes("401"), string `Expected the status: ${err.message()}`);
    test:assertTrue(err.message().includes("Incorrect API key provided"),
            string `Expected the API error message: ${err.message()}`);
}

@test:Config
function testGenerateStreamProjectsTextFragments() returns error? {
    ModelProvider model = check chatStreamProvider("text");
    stream<string, ai:Error?> fragments = check model->generateStream(`Say hello`);
    string text = "";
    check from string fragment in fragments
        do {
            text += fragment;
        };
    test:assertEquals(text, "Hello world");
}

@test:Config
function testGenerateStreamRejectsNonStringTypes() returns error? {
    ModelProvider model = check chatStreamProvider("text");
    stream<int, ai:Error?>|ai:Error result = model->generateStream(`Rate this out of 10`);
    test:assertTrue(result is ai:Error, "Only 'string' can be streamed");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("supports only 'string'"),
            string `Unexpected error message: ${err.message()}`);
}

// ===== Responses API streaming =====

@test:Config
function testResponsesChatStreamText() returns ai:Error? {
    ModelProvider model = check responsesStreamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Hello world");
    test:assertEquals(finalFinishReason(chunks), ai:STOP);
}

@test:Config
function testResponsesChatStreamToolCallsUseDenseIndices() returns ai:Error? {
    ModelProvider model = check responsesStreamProvider("tools");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Weather and time?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    // The stream opens with a reasoning item, so the tool calls arrive at `output_index` 1 and 2.
    // `ai:ToolCallFragment.index` is a dense tool-call index, as the Chat Completions path produces,
    // so a consumer keying an array by it sees the same numbering on both APIs.
    map<[string, string]> toolCalls = accumulateToolCalls(chunks);
    test:assertEquals(toolCalls.keys().sort(), ["0", "1"]);
    test:assertEquals(toolCalls["0"], ["getWeather", string `{"city":"Colombo"}`]);
    test:assertEquals(toolCalls["1"], ["getTime", "{}"]);
    test:assertEquals(joinReasoning(chunks), "Checking the weather");
}

@test:Config
function testResponsesChatStreamReportsToolCallsFinishReason() returns ai:Error? {
    ModelProvider model = check responsesStreamProvider("tools");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Weather and time?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    // The Responses API has no `tool_calls` finish reason of its own, but the normalized stream
    // must report one so a consumer can drive either API.
    test:assertEquals(finalFinishReason(chunks), ai:TOOL_CALLS);
}

@test:Config
function testResponsesChatStreamSurfacesFailedResponse() returns error? {
    ModelProvider model = check responsesStreamProvider("failed");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    test:assertTrue(result is ai:Error, "A failed response must not look like a clean completion");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("The model failed to generate a response"),
            string `Unexpected error message: ${err.message()}`);
    test:assertTrue(err.message().includes("server_error"),
            string `Expected the failure code: ${err.message()}`);
}

@test:Config
function testResponsesChatStreamReportsTruncationAsLength() returns ai:Error? {
    ModelProvider model = check responsesStreamProvider("incomplete");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Partial");
    test:assertEquals(finalFinishReason(chunks), ai:LENGTH);
}

@test:Config
function testResponsesChatStreamSurfacesErrorEvent() returns error? {
    ModelProvider model = check responsesStreamProvider("errorevent");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream = check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    test:assertTrue(result is ai:Error, "Expected the error event to fail the stream");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("Rate limit reached"),
            string `Unexpected error message: ${err.message()}`);
}

@test:Config
function testResponsesChatStreamSurfacesHttpErrorStatus() returns error? {
    ModelProvider model = check responsesStreamProvider("unauthorized");
    stream<ai:ChatCompletionChunk, ai:Error?>|ai:Error result =
        model->chatStream({role: ai:USER, content: "Say hello"});

    test:assertTrue(result is ai:Error, "Expected a 401 to fail before the stream opens");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("Incorrect API key provided"),
            string `Expected the API error message: ${err.message()}`);
}

@test:Config
function testResponsesChatStreamRejectsStopSequence() returns error? {
    ModelProvider model = check responsesStreamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?>|ai:Error result =
        model->chatStream({role: ai:USER, content: "Say hello"}, stop = "STOP");

    test:assertTrue(result is ai:Error, "The Responses API has no stop-sequence parameter");
    ai:Error err = <ai:Error>result;
    test:assertTrue(err.message().includes("'stop' parameter is not supported"),
            string `Unexpected error message: ${err.message()}`);
}

@test:Config
function testResponsesGenerateStreamProjectsTextFragments() returns error? {
    ModelProvider model = check responsesStreamProvider("text");
    stream<string, ai:Error?> fragments = check model->generateStream(`Say hello`);
    string text = "";
    check from string fragment in fragments
        do {
            text += fragment;
        };
    test:assertEquals(text, "Hello world");
}

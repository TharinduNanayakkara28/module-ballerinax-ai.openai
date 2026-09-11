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

import ballerina/http;
import ballerina/test;

// Mock Server-Sent Events endpoints backing the streaming tests.
//
// Each scenario gets its own base path so a test can point a provider at exactly the stream
// it wants to exercise: a provider built with `serviceUrl` `.../stream/<scenario>` posts to
// `<scenario>/chat/completions` or `<scenario>/responses` under this service.
service /sse on new http:Listener(8081) {

    // ===== Chat Completions API =====

    // Plain text answer, ending with a finish-reason chunk and a usage-only chunk.
    resource function post text/chat/completions(@http:Payload json payload)
            returns stream<http:SseEvent, error?>|error {
        test:assertEquals(check payload.'stream, true, "Streaming requests must set 'stream'");
        test:assertEquals(check payload.stream_options.include_usage, true,
                "Streaming requests must ask for usage on the final chunk");
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Hello"}`),
            // `system_fingerprint` is explicitly null on some models; the chunk must still bind.
            string `{"id":"chatcmpl-1","object":"chat.completion.chunk","created":1,` +
                string `"model":"gpt-4-turbo","system_fingerprint":null,"choices":` +
                string `[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}`,
            chatChunkWithFinishReason("stop"),
            string `{"id":"chatcmpl-1","object":"chat.completion.chunk","created":1,` +
                string `"model":"gpt-4-turbo","choices":[],` +
                string `"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}`,
            "[DONE]"
        ]);
    }

    // A role-only opening delta, as OpenAI sends before the first content fragment. It
    // carries nothing the normalized chunks can hold, so it must map to no chunk at all.
    resource function post roleonly/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant"}`),
            chatChunk(string `{"content":"Hi"}`),
            chatChunkWithFinishReason("stop"),
            "[DONE]"
        ]);
    }

    // One wire chunk carrying a content fragment and a finish reason together, as some
    // OpenAI-compatible gateways emit. One raw chunk, two normalized chunks.
    resource function post combined/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"id":"chatcmpl-combined","object":"chat.completion.chunk","created":1,` +
                string `"model":"gpt-4-turbo","choices":[{"index":0,` +
                string `"delta":{"role":"assistant","content":"All done."},"finish_reason":"stop"}]}`,
            "[DONE]"
        ]);
    }

    // Two tool calls streamed in fragments, ending with a `tool_calls` finish reason.
    resource function post tools/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","tool_calls":[{"index":0,"id":"call_a",` +
                    string `"type":"function","function":{"name":"getWeather","arguments":""}}]}`),
            chatChunk(string `{"tool_calls":[{"index":0,"function":{"arguments":"{\"city\":"}}]}`),
            chatChunk(string `{"tool_calls":[{"index":1,"id":"call_b","type":"function",` +
                    string `"function":{"name":"getTime","arguments":"{}"}}]}`),
            chatChunk(string `{"tool_calls":[{"index":0,"function":{"arguments":"\"Colombo\"}"}}]}`),
            chatChunkWithFinishReason("tool_calls"),
            "[DONE]"
        ]);
    }

    // A generation cut short part-way: content, then the error frame OpenAI emits in place of
    // the rest of the answer.
    resource function post midstreamerror/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Partial"}`),
            string `{"error":{"message":"Rate limit reached for gpt-4-turbo","type":"rate_limit_error"}}`
        ]);
    }

    // A frame that is not JSON at all.
    resource function post malformed/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Partial"}`),
            "{not json at all"
        ]);
    }

    // A rejected request: the endpoint answers with a normal JSON error body, not a stream.
    resource function post unauthorized/chat/completions() returns http:Response {
        return unauthorizedResponse();
    }

    // Reasoning fragments under the name some OpenAI-compatible providers use.
    resource function post reasoning/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","reasoning_content":"Let me think"}`),
            chatChunk(string `{"content":"42"}`),
            chatChunkWithFinishReason("stop"),
            "[DONE]"
        ]);
    }

    // ===== Responses API =====

    // Plain text answer, ending with the terminal lifecycle event carrying usage.
    resource function post text/responses(@http:Payload json payload)
            returns stream<http:SseEvent, error?>|error {
        test:assertEquals(check payload.'stream, true, "Streaming requests must set 'stream'");
        test:assertEquals(check payload.store, false, "Streaming requests must not store the response");
        return sseEvents([
            string `{"type":"response.created","response":{"status":"in_progress"}}`,
            string `{"type":"response.output_item.added","output_index":0,` +
                string `"item":{"type":"message","id":"msg_1"}}`,
            string `{"type":"response.output_text.delta","output_index":0,"delta":"Hello"}`,
            string `{"type":"response.output_text.delta","output_index":0,"delta":" world"}`,
            string `{"type":"response.output_text.done","output_index":0,"text":"Hello world"}`,
            responsesCompleted()
        ]);
    }

    // A reasoning item ahead of two tool calls, so the Responses `output_index` and the dense
    // tool-call index the `ai` module expects deliberately disagree.
    resource function post tools/responses() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"type":"response.output_item.added","output_index":0,` +
                string `"item":{"type":"reasoning","id":"rs_1"}}`,
            string `{"type":"response.reasoning_summary_text.delta","output_index":0,` +
                string `"delta":"Checking the weather"}`,
            string `{"type":"response.output_item.added","output_index":1,` +
                string `"item":{"type":"function_call","id":"fc_1","call_id":"call_a","name":"getWeather"}}`,
            string `{"type":"response.function_call_arguments.delta","output_index":1,` +
                string `"delta":"{\"city\":"}`,
            string `{"type":"response.output_item.added","output_index":2,` +
                string `"item":{"type":"function_call","id":"fc_2","call_id":"call_b","name":"getTime"}}`,
            string `{"type":"response.function_call_arguments.delta","output_index":2,"delta":"{}"}`,
            string `{"type":"response.function_call_arguments.delta","output_index":1,` +
                string `"delta":"\"Colombo\"}"}`,
            responsesCompleted()
        ]);
    }

    // A server-side failure reported through the stream rather than the HTTP status.
    resource function post failed/responses() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"type":"response.output_text.delta","output_index":0,"delta":"Partial"}`,
            string `{"type":"response.failed","response":{"status":"failed",` +
                string `"error":{"code":"server_error","message":"The model failed to generate a response"}}}`
        ]);
    }

    // A generation truncated by `max_output_tokens`.
    resource function post incomplete/responses() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"type":"response.output_text.delta","output_index":0,"delta":"Partial"}`,
            string `{"type":"response.incomplete","response":{"status":"incomplete",` +
                string `"incomplete_details":{"reason":"max_output_tokens"},` +
                string `"usage":{"input_tokens":10,"output_tokens":5,"total_tokens":15}}}`
        ]);
    }

    // The standalone `error` event the Responses stream can emit.
    resource function post errorevent/responses() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"type":"error","message":"Rate limit reached"}`
        ]);
    }

    resource function post unauthorized/responses() returns http:Response {
        return unauthorizedResponse();
    }
}

# Wraps each payload as the `data` of one Server-Sent Event.
#
# + payloads - The `data` payloads to emit, in order
# + return - The event stream the mock endpoint answers with
isolated function sseEvents(string[] payloads) returns stream<http:SseEvent, error?> {
    http:SseEvent[] events = from string payload in payloads
        select {data: payload};
    return events.toStream();
}

# Builds one `chat.completion.chunk` frame around the given delta.
#
# + delta - The `delta` object as a JSON string
# + return - The frame's `data` payload
isolated function chatChunk(string delta) returns string =>
    string `{"id":"chatcmpl-1","object":"chat.completion.chunk","created":1,"model":"gpt-4-turbo",` +
        string `"choices":[{"index":0,"delta":${delta},"finish_reason":null}]}`;

# Builds the terminal `chat.completion.chunk` frame carrying a finish reason.
#
# + finishReason - The wire finish reason
# + return - The frame's `data` payload
isolated function chatChunkWithFinishReason(string finishReason) returns string =>
    string `{"id":"chatcmpl-1","object":"chat.completion.chunk","created":1,"model":"gpt-4-turbo",` +
        string `"choices":[{"index":0,"delta":{},"finish_reason":"${finishReason}"}]}`;

# The terminal Responses lifecycle event, carrying usage.
#
# + return - The event's `data` payload
isolated function responsesCompleted() returns string =>
    string `{"type":"response.completed","response":{"status":"completed",` +
        string `"usage":{"input_tokens":10,"output_tokens":5,"total_tokens":15}}}`;

# The JSON error body OpenAI answers a rejected request with.
#
# + return - A 401 response carrying the usual error envelope
isolated function unauthorizedResponse() returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_UNAUTHORIZED;
    response.setJsonPayload({
        'error: {
            message: "Incorrect API key provided",
            'type: "invalid_request_error",
            code: "invalid_api_key"
        }
    });
    return response;
}

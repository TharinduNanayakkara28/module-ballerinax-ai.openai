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
import ballerina/http;

# Configurations for controlling the behaviours when communicating with a remote HTTP endpoint.
@display {label: "Connection Configuration"}
public type ConnectionConfig record {|

    # The HTTP version understood by the client
    @display {label: "HTTP Version"}
    http:HttpVersion httpVersion = http:HTTP_2_0;

    # Configurations related to HTTP/1.x protocol
    @display {label: "HTTP1 Settings"}
    http:ClientHttp1Settings http1Settings?;

    # Configurations related to HTTP/2 protocol
    @display {label: "HTTP2 Settings"}
    http:ClientHttp2Settings http2Settings?;

    # The maximum time to wait (in seconds) for a response before closing the connection
    @display {label: "Timeout"}
    decimal timeout = 60;

    # The choice of setting `forwarded`/`x-forwarded` header
    @display {label: "Forwarded"}
    string forwarded = "disable";

    # Configurations associated with request pooling
    @display {label: "Pool Configuration"}
    http:PoolConfiguration poolConfig?;

    # HTTP caching related configurations
    @display {label: "Cache Configuration"}
    http:CacheConfig cache?;

    # Specifies the way of handling compression (`accept-encoding`) header
    @display {label: "Compression"}
    http:Compression compression = http:COMPRESSION_AUTO;

    # Configurations associated with the behaviour of the Circuit Breaker
    @display {label: "Circuit Breaker Configuration"}
    http:CircuitBreakerConfig circuitBreaker?;

    # Configurations associated with retrying
    @display {label: "Retry Configuration"}
    http:RetryConfig retryConfig?;

    # Configurations associated with inbound response size limits
    @display {label: "Response Limit Configuration"}
    http:ResponseLimitConfigs responseLimits?;

    # SSL/TLS-related options
    @display {label: "Secure Socket Configuration"}
    http:ClientSecureSocket secureSocket?;

    # Proxy server related options
    @display {label: "Proxy Configuration"}
    http:ProxyConfig proxy?;

    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    @display {label: "Payload Validation"}
    boolean validation = true;
|};

# Defines which OpenAI API endpoint to use for model interactions.
@display {label: "OpenAI API Type"}
public enum ApiType {
    # Use the OpenAI Chat Completions API (`/chat/completions`)
    CHAT_COMPLETIONS = "chat_completions",
    # Use the OpenAI Responses API (`/responses`)
    RESPONSES = "responses"
}

# Constrains the effort spent on reasoning for reasoning-capable models.
# Supported by both the Chat Completions API (`reasoning_effort`) and the Responses API (`reasoning.effort`).
# Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning.
#
# Each model accepts only a subset of these values; for example, `gpt-5` accepts
# `minimal`, `low`, `medium` and `high`, while `gpt-5-pro` accepts only `high`.
# The value is validated against the selected model when the provider is initialized.
#
# Note: the `max` effort accepted by the `gpt-5.6` family cannot be represented yet, because
# `ballerinax/openai.chat` and `ballerinax/openai.responses` declare a closed `ReasoningEffort`
# union without it. Add `MAX` here once those connectors are regenerated.
@display {label: "Reasoning Effort"}
public enum ReasoningEffort {
    NONE = "none",
    MINIMAL = "minimal",
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    XHIGH = "xhigh"
}

# Model types for OpenAI
@display {label: "OpenAI Model Names"}
public enum OPEN_AI_MODEL_NAMES {
    GPT_4O = "gpt-4o",
    GPT_4O_2024_11_20 = "gpt-4o-2024-11-20",
    GPT_4O_2024_08_06 = "gpt-4o-2024-08-06",
    GPT_4O_2024_05_13 = "gpt-4o-2024-05-13",
    GPT_4O_MINI = "gpt-4o-mini",
    GPT_4O_MINI_2024_07_18 = "gpt-4o-mini-2024-07-18",
    GPT_4_TURBO = "gpt-4-turbo",
    GPT_4_TURBO_2024_04_09 = "gpt-4-turbo-2024-04-09",
    GPT_4_0125_PREVIEW = "gpt-4-0125-preview",
    GPT_4_TURBO_PREVIEW = "gpt-4-turbo-preview",
    GPT_4_1106_PREVIEW = "gpt-4-1106-preview",
    GPT_4_0613 = "gpt-4-0613",
    O1 = "o1",
    O1_2024_12_17 = "o1-2024-12-17",
    O1_PRO_2025_03_19 = "o1-pro-2025-03-19",
    O1_PRO = "o1-pro",
    O1_MINI = "o1-mini",
    O3 = "o3",
    O3_MINI = "o3-mini",
    O3_PRO = "o3-pro",
    O4_MINI = "o4-mini",
    GPT_3_5_TURBO = "gpt-3.5-turbo",
    GPT_3_5_TURBO_16K = "gpt-3.5-turbo-16k",
    GPT_3_5_TURBO_1106 = "gpt-3.5-turbo-1106",
    GPT_3_5_TURBO_0125 = "gpt-3.5-turbo-0125",
    GPT_4_1_2025_04_14 = "gpt-4.1-2025-04-14",
    GPT_4_1 = "gpt-4.1",
    GPT_4_1_MINI_2025_04_14 = "gpt-4.1-mini-2025-04-14",
    GPT_4_1_MINI = "gpt-4.1-mini",
    GPT_4_1_NANO = "gpt-4.1-nano",
    GPT_4_1_NANO_2025_04_14 = "gpt-4.1-nano-2025-04-14",
    GPT_5 = "gpt-5",
    GPT_5_MINI = "gpt-5-mini",
    GPT_5_NANO = "gpt-5-nano",
    GPT_5_PRO = "gpt-5-pro",
    GPT_5_1 = "gpt-5.1",
    GPT_5_2 = "gpt-5.2",
    GPT_5_2_PRO = "gpt-5.2-pro",
    GPT_5_3_CODEX = "gpt-5.3-codex",
    GPT_5_4 = "gpt-5.4",
    GPT_5_4_MINI = "gpt-5.4-mini",
    GPT_5_4_NANO = "gpt-5.4-nano",
    GPT_5_4_PRO = "gpt-5.4-pro",
    GPT_5_5 = "gpt-5.5",
    GPT_5_5_PRO = "gpt-5.5-pro",
    # Alias that always routes to the latest `gpt-5.6-sol` snapshot.
    GPT_5_6 = "gpt-5.6",
    GPT_5_6_SOL = "gpt-5.6-sol",
    GPT_5_6_TERRA = "gpt-5.6-terra",
    GPT_5_6_LUNA = "gpt-5.6-luna",
    GPT_4O_AUDIO_PREVIEW = "gpt-4o-audio-preview",
    GPT_5_CHAT = "gpt-5-chat-latest",
    GPT_5_CODEX = "gpt-5-codex",
    GPT_5_1_CHAT = "gpt-5.1-chat-latest",
    GPT_5_1_CODEX = "gpt-5.1-codex",
    GPT_5_1_CODEX_MINI = "gpt-5.1-codex-mini",
    GPT_5_1_CODEX_MAX = "gpt-5.1-codex-max",
    GPT_5_2_CHAT = "gpt-5.2-chat-latest",
    GPT_5_2_CODEX = "gpt-5.2-codex",
    CHATGPT_4O_LATEST = "chatgpt-4o-latest",
    COMPUTER_USE_PREVIEW = "computer-use-preview",
    CODEX_MINI_LATEST = "codex-mini-latest"
}

@display {label: "OpenAI Embedding Model Names"}
public enum OPEN_AI_EMBEDDING_MODEL_NAMES {
    TEXT_EMBEDDING_3_SMALL = "text-embedding-3-small",
    TEXT_EMBEDDING_3_LARGE = "text-embedding-3-large",
    TEXT_EMBEDDING_ADA_002 = "text-embedding-ada-002"
}

type ToolInfo readonly & record {|
    string toolList;
    string toolIntro;
|};

type LlmChatResponse record {|
    string content;
|};

// ── Chat Completions streaming types ───────────────────────────────────────
// Models the streamed `chat.completion.chunk` objects emitted by the
// /chat/completions endpoint when `stream` is true.
// Reference: https://platform.openai.com/docs/api-reference/chat-streaming/streaming

# A streamed chunk of a chat completion response, as part of a Server-Sent Events
# stream from the /chat/completions endpoint (object "chat.completion.chunk").
#
# Only `choices` is required. OpenAI itself sends the metadata fields on every chunk, but
# OpenAI-compatible gateways routinely omit some of them, and a chunk that fails to bind is
# now reported as an error rather than skipped - so anything the mapping does not actually
# need is optional, and a bind failure means a genuinely unexpected shape.
type CreateChatCompletionStreamResponse record {
    # Unique identifier for the chat completion; the same across every chunk
    string id?;
    # Object type, always "chat.completion.chunk"
    string 'object?;
    # Unix timestamp (seconds) of creation; the same across every chunk
    int created?;
    # The model used to generate the completion
    string model?;
    # A list of chat completion choices; can hold more than one when `n` > 1,
    # or be empty for the final usage-only chunk
    ChatCompletionStreamChoice[] choices;
    # Fingerprint of the backend configuration the model runs with. Optional, and
    # explicitly `null` (rather than omitted) on some models' streamed chunks (e.g. gpt-5).
    string? system_fingerprint = ();
    # The service tier used for processing the request
    string? service_tier = ();
    # Moderation results for the request input and generated output. Present on
    # the moderation chunk when moderated completions are requested
    ChatCompletionStreamModeration moderation?;
    # Token usage statistics. Null on every chunk except the final one, and only
    # present when `stream_options: { include_usage: true }` was set
    CompletionUsage? usage = ();
};

# Moderation results carried on a streamed moderation chunk, covering both the
# request input and the generated output
type ChatCompletionStreamModeration record {
    # Moderation for the request input; either successful results or an error
    ModerationResults|ModerationError input?;
    # Moderation for the generated output; either successful results or an error
    ModerationResults|ModerationError output?;
};

# Successful moderation results for the request input or generated output
type ModerationResults record {
    # The model used to generate the moderation results
    string model;
    # The moderation results payload
    json results;
    # The type of the object, always "moderation"
    string 'type;
};

# An error produced while attempting moderation
type ModerationError record {
    # Machine-readable error code
    string code;
    # Human-readable error message
    string message;
    # The type of the object, always "error"
    string 'type;
};

# A single choice within a streamed chat completion chunk
type ChatCompletionStreamChoice record {
    # Index of the choice in the list of choices
    int index;
    # The incremental delta of the chat message for this chunk
    ChatCompletionStreamResponseDelta delta;
    # Log-probability information for the choice, null when not requested
    ChatCompletionStreamChoiceLogprobs? logprobs = ();
    # Reason the model stopped generating tokens; null until the final chunk
    FinishReason? finish_reason = ();
};

# The reason the model stopped generating tokens.
# - `stop`: hit a natural stop point or a provided stop sequence
# - `length`: reached the maximum number of tokens specified in the request
# - `content_filter`: content was omitted due to a content-filter flag
# - `tool_calls`: the model called a tool
# - `function_call`: (deprecated) the model called a function
enum FinishReason {
    STOP = "stop",
    LENGTH = "length",
    TOOL_CALLS = "tool_calls",
    CONTENT_FILTER = "content_filter",
    FUNCTION_CALL = "function_call"
}

# A chat completion delta generated by streamed model responses
type ChatCompletionStreamResponseDelta record {
    # Role of the author of this message; only sent on the first delta
    string role?;
    # The contents of the chunk message, null for non-content deltas
    string? content = ();
    # Reasoning/chain-of-thought fragment. Not emitted by standard OpenAI chat
    # completions; sent by some OpenAI-compatible providers (e.g. DeepSeek uses
    # `reasoning_content`). Mapped to `delta.reasoning` when present.
    string? reasoning_content = ();
    # Alternative field name some providers use for the reasoning fragment
    string? reasoning = ();
    # The refusal message generated by the model, null when not refusing
    string? refusal = ();
    # Incremental tool calls generated by the model
    ChatCompletionMessageToolCallChunk[] tool_calls?;
    # Deprecated and replaced by `tool_calls`; the name and arguments of the
    # function to call
    record {
        # The name of the function to call
        string name?;
        # The arguments to call the function with, as a JSON string
        string arguments?;
    } function_call?;
};

# An incremental tool call delivered within a streamed delta. With parallel tool
# calling enabled, several tool calls stream concurrently, distinguished by `index`.
type ChatCompletionMessageToolCallChunk record {
    # Index of the tool call in the message's `tool_calls` array; used to
    # correlate fragments of the same tool call across chunks
    int index;
    # Identifier of the tool call; only sent on the first chunk of the call
    string id?;
    # The type of the tool, always "function"; only sent on the first chunk
    string 'type?;
    # The function the model is calling
    ChatCompletionMessageToolCallChunkFunction 'function?;
};

# The function fragment of a streamed tool call chunk
type ChatCompletionMessageToolCallChunkFunction record {
    # Name of the function to call; only sent on the first chunk of the call
    string name?;
    # Incremental fragment of the function arguments, accumulated as a JSON string
    string arguments?;
};

# Log-probability information for a streamed choice
type ChatCompletionStreamChoiceLogprobs record {
    # Log probabilities of the content tokens, null when none
    ChatCompletionTokenLogprob[]? content = ();
    # Log probabilities of the refusal tokens, null when none
    ChatCompletionTokenLogprob[]? refusal = ();
};

# Log-probability information for a single token
type ChatCompletionTokenLogprob record {
    # The token
    string token;
    # The log probability of this token
    decimal logprob;
    # UTF-8 byte representation of the token, null when unavailable
    int[]? bytes = ();
    # The most likely tokens and their log probabilities at this position
    ChatCompletionTokenTopLogprob[] top_logprobs;
};

# A candidate token and its log probability at a given position
type ChatCompletionTokenTopLogprob record {
    # The token
    string token;
    # The log probability of this token
    decimal logprob;
    # UTF-8 byte representation of the token, null when unavailable
    int[]? bytes = ();
};

# Usage statistics for the completion request, sent on the final chunk when
# `stream_options: { include_usage: true }` is set
type CompletionUsage record {
    # Number of tokens in the prompt
    int prompt_tokens;
    # Number of tokens in the generated completion
    int completion_tokens;
    # Total tokens used (prompt + completion)
    int total_tokens;
    # Breakdown of tokens used in the completion
    CompletionTokensDetails completion_tokens_details?;
    # Breakdown of tokens used in the prompt
    PromptTokensDetails prompt_tokens_details?;
};

# Breakdown of tokens used in a completion
type CompletionTokensDetails record {
    # Tokens generated for reasoning (o-series models)
    int reasoning_tokens?;
    # Audio input tokens generated by the model
    int audio_tokens?;
    # Tokens generated by accepted prediction outputs
    int accepted_prediction_tokens?;
    # Tokens generated by rejected prediction outputs
    int rejected_prediction_tokens?;
};

# Breakdown of tokens present in the prompt
type PromptTokensDetails record {
    # Audio input tokens present in the prompt
    int audio_tokens?;
    # Prompt tokens served from cache
    int cached_tokens?;
};

// ── Wire → normalized mapping ──────────────────────────────────────────────
// Projects an OpenAI `chat.completion.chunk` (the wire types above) onto the
// normalized `ai:ChatCompletionChunk` that `chatStream` must return. Only the
// subset the `ai` type can hold is mapped; everything else is ignored.

# Maps an OpenAI wire chunk onto the normalized `ai:ChatCompletionChunk`.
# Forwards tool calls on every chunk (not just the first), so argument fragments
# stream through correctly.
#
# The normalized chunk has no notion of multiple choices, so only the first wire
# choice is surfaced - which is all any consumer ever read. A chunk carrying no
# choice at all (the usage-only chunk `stream_options.include_usage` appends) maps
# to `()`: its token counts go to the observability span, and there is nothing left
# to hand the caller. Usage is likewise not carried on the chunk.
#
# + w - The parsed OpenAI wire chunk
# + return - The normalized chunk, or `()` when the wire chunk carries no choice
isolated function toAiChunk(CreateChatCompletionStreamResponse w) returns ai:ChatCompletionChunk? {
    ChatCompletionStreamChoice[] wireChoices = w.choices;
    if wireChoices.length() == 0 {
        return ();
    }

    ChatCompletionStreamChoice c = wireChoices[0];
    ai:ChatCompletionChunk chunk = {
        content: c.delta.content,
        finishReason: mapFinishReason(c.finish_reason)
    };
    ai:ASSISTANT? role = mapRole(c.delta?.role);
    if role is ai:ASSISTANT {
        chunk.role = role;
    }
    string? reasoningFragment = c.delta.reasoning_content ?: c.delta.reasoning;
    if reasoningFragment is string {
        chunk.reasoning = reasoningFragment;
    }
    ChatCompletionMessageToolCallChunk[]? wireToolCalls = c.delta?.tool_calls;
    if wireToolCalls is ChatCompletionMessageToolCallChunk[] {
        ai:ToolCallChunk[] toolCalls = [];
        foreach ChatCompletionMessageToolCallChunk t in wireToolCalls {
            ai:ToolCallChunk toolCall = {index: t.index};
            string? id = t?.id;
            if id is string {
                toolCall.id = id;
            }
            ChatCompletionMessageToolCallChunkFunction? fn = t?.'function;
            if fn is ChatCompletionMessageToolCallChunkFunction {
                string? name = fn?.name;
                if name is string {
                    toolCall.name = name;
                }
                string? arguments = fn?.arguments;
                if arguments is string {
                    toolCall.arguments = arguments;
                }
            }
            toolCalls.push(toolCall);
        }
        chunk.toolCalls = toolCalls;
    }

    string? id = w?.id;
    if id is string {
        chunk.id = id;
    }
    return chunk;
}

# Safely maps an OpenAI role string onto `ai:ASSISTANT`; returns `()` for absent or
# other values rather than panicking on a cast.
#
# + role - The role string from the wire delta
# + return - `ai:ASSISTANT` for the "assistant" role, `()` otherwise
isolated function mapRole(string? role) returns ai:ASSISTANT? {
    // Streamed response deltas only ever carry the "assistant" role, and that is the
    // only role the normalized chunk can hold; anything else is dropped.
    return role == "assistant" ? ai:ASSISTANT : ();
}

# Safely maps an OpenAI finish reason onto the `ai:FinishReason` enum. The `ai`
# enum has no `function_call` member, so the deprecated `function_call` value is
# folded into `tool_calls`. Returns `()` for absent or unrecognized values.
#
# + finishReason - The finish reason from the wire chunk
# + return - The mapped `ai:FinishReason`, or `()` when absent/unrecognized
isolated function mapFinishReason(FinishReason? finishReason) returns ai:FinishReason? {
    if finishReason is () {
        return ();
    }
    if finishReason == STOP {
        return ai:STOP;
    }
    if finishReason == LENGTH {
        return ai:LENGTH;
    }
    if finishReason == TOOL_CALLS || finishReason == FUNCTION_CALL {
        return ai:TOOL_CALLS;
    }
    return ai:CONTENT_FILTER;
}

// ── Responses API streaming event wire types ───────────────────────────────
// A trimmed model of the Server-Sent Events emitted by the /responses endpoint
// when `stream` is true. Open records, so unmodeled fields are ignored. Only the
// subset needed to build `ai:ChatCompletionChunk` is captured. `ResponsesChunkIterator`
// maps these onto the normalized chunk.
// Reference: https://platform.openai.com/docs/api-reference/responses-streaming

# A single streamed event from the Responses API, discriminated by `type`.
type ResponsesStreamEvent record {
    # Event type (e.g., "response.output_text.delta", "response.output_item.added",
    # "response.function_call_arguments.delta", "response.completed", "error")
    string 'type;
    # Index of the output item this event refers to; used to correlate tool-call fragments
    int? output_index = ();
    # Incremental text/argument fragment (output_text.delta / function_call_arguments.delta)
    string? delta = ();
    # Error message (error event)
    string? message = ();
    # The output item, on "response.output_item.added"/".done"
    ResponsesEventItem? item = ();
    # The full response snapshot, on lifecycle events like "response.completed"
    ResponsesEventResponse? response = ();
};

# The output item carried by a Responses output-item event.
type ResponsesEventItem record {
    # Item type ("message", "function_call", "reasoning", ...)
    string? 'type = ();
    # Identifier of the output item
    string? id = ();
    # Identifier used to correlate the tool result (function_call items)
    string? call_id = ();
    # Name of the function being called (function_call items)
    string? name = ();
};

# The response snapshot carried by a Responses lifecycle event.
type ResponsesEventResponse record {
    # Lifecycle status ("completed", "incomplete", "failed", ...)
    string? status = ();
    # Billing/rate-limit usage, present on the terminal event
    ResponsesEventUsage? usage = ();
    # Failure detail, present on "response.failed"
    ResponsesEventError? 'error = ();
    # Why the response stopped short, present on "response.incomplete"
    ResponsesEventIncompleteDetails? incomplete_details = ();
};

# The failure detail carried by a "response.failed" event.
type ResponsesEventError record {
    # Machine-readable failure code
    string? code = ();
    # Human-readable failure message
    string? message = ();
};

# The reason a response stopped short, carried by a "response.incomplete" event.
type ResponsesEventIncompleteDetails record {
    # Why the response is incomplete ("max_output_tokens", "content_filter", ...)
    string? reason = ();
};

# Token usage carried by the terminal Responses lifecycle event.
type ResponsesEventUsage record {
    # Number of input (prompt) tokens
    int? input_tokens = ();
    # Number of output (completion) tokens
    int? output_tokens = ();
    # Total tokens used
    int? total_tokens = ();
};

# Mutable state carried across one Responses stream while its events are mapped onto chunks.
type ResponsesStreamState record {|
    # Dense, 0-based tool-call index for each Responses `output_index` that started a
    # function call
    map<int> toolCallIndices = {};
    # Number of tool calls started so far; also the next dense index to hand out
    int toolCallCount = 0;
|};

# Maps a single Responses API stream event onto an `ai:ChatCompletionChunk`, or
# `()` for lifecycle/other events that carry no answer content. Text deltas,
# tool-call starts (`output_item.added`) and argument fragments
# (`function_call_arguments.delta`) each map to one chunk.
#
# + ev - The parsed Responses stream event
# + state - Per-stream state, updated in place as tool calls are seen
# + return - The normalized chunk, or `()` to skip the event
isolated function responsesEventToChunk(ResponsesStreamEvent ev, ResponsesStreamState state)
        returns ai:ChatCompletionChunk? {
    match ev.'type {
        "response.output_text.delta" => {
            string? delta = ev.delta;
            if delta is string {
                return {content: delta};
            }
        }
        "response.reasoning_text.delta"|"response.reasoning_summary_text.delta" => {
            string? delta = ev.delta;
            if delta is string {
                return {reasoning: delta};
            }
        }
        "response.output_item.added" => {
            ResponsesEventItem? item = ev.item;
            if item is ResponsesEventItem && item.'type == "function_call" {
                ai:ToolCallChunk toolCall = {index: nextToolCallIndex(ev.output_index, state)};
                string? callId = item.call_id;
                if callId is string {
                    toolCall.id = callId;
                }
                string? name = item.name;
                if name is string {
                    toolCall.name = name;
                }
                return {toolCalls: [toolCall]};
            }
        }
        "response.function_call_arguments.delta" => {
            string? delta = ev.delta;
            if delta is string {
                ai:ToolCallChunk toolCall = {
                    index: nextToolCallIndex(ev.output_index, state),
                    arguments: delta
                };
                return {toolCalls: [toolCall]};
            }
        }
        "response.completed"|"response.incomplete" => {
            return responsesFinalChunk(ev, state);
        }
    }
    return ();
}

# Resolves the Responses `output_index` of a function call onto the dense, 0-based
# tool-call index that `ai:ToolCallChunk.index` is defined to carry.
#
# The Responses API numbers *output items*, so reasoning and message items consume
# indices too and the first tool call of a reasoning model can arrive as index 3.
# `ai:ToolCallChunk.index` is the index used to accumulate fragments of the same call,
# and the Chat Completions path produces a dense 0-based one - a consumer keying an
# array by it must see the same numbering on both APIs. Fragments of one call share an
# `output_index`, so the first sighting allocates and the rest look up.
#
# + outputIndex - The `output_index` from the event, if any
# + state - Per-stream state, updated in place when a new index is allocated
# + return - The dense tool-call index
isolated function nextToolCallIndex(int? outputIndex, ResponsesStreamState state) returns int {
    string key = (outputIndex ?: 0).toString();
    int? existing = state.toolCallIndices[key];
    if existing is int {
        return existing;
    }
    int allocated = state.toolCallCount;
    state.toolCallIndices[key] = allocated;
    state.toolCallCount = allocated + 1;
    return allocated;
}

# Builds the terminal `ai:ChatCompletionChunk` for a Responses lifecycle event,
# carrying the finish reason. Token usage is not carried on the chunk; the iterator
# reports it to the observability span straight off the wire event.
#
# The Responses API has no `tool_calls` finish reason of its own, so a completed
# response that streamed at least one tool call is reported as `tool_calls` - matching
# what the Chat Completions path emits, so one consumer can drive both APIs.
#
# + ev - The terminal Responses stream event
# + state - Per-stream state, read to decide between `stop` and `tool_calls`
# + return - The final normalized chunk
isolated function responsesFinalChunk(ResponsesStreamEvent ev, ResponsesStreamState state)
        returns ai:ChatCompletionChunk {
    ai:FinishReason finishReason = state.toolCallCount > 0 ? ai:TOOL_CALLS : ai:STOP;
    if ev.'type == "response.incomplete" {
        finishReason = responsesIncompleteReason(ev);
    }
    return {finishReason};
}

# Extracts the token usage a Responses lifecycle event carries on its response
# snapshot, for the observability span to report.
#
# + ev - The parsed Responses stream event
# + return - The wire usage, or `()` when the event carries none
isolated function responsesEventUsage(ResponsesStreamEvent ev) returns ResponsesEventUsage? {
    ResponsesEventResponse? response = ev.response;
    if response is ResponsesEventResponse {
        return response.usage;
    }
    return ();
}

# Maps the `incomplete_details.reason` of a "response.incomplete" event onto the
# normalized finish reason; an incomplete response is a truncation, so anything other
# than an explicit content-filter stop is reported as `length`.
#
# + ev - The "response.incomplete" event
# + return - The normalized finish reason
isolated function responsesIncompleteReason(ResponsesStreamEvent ev) returns ai:FinishReason {
    ResponsesEventResponse? response = ev.response;
    if response is ResponsesEventResponse {
        ResponsesEventIncompleteDetails? details = response.incomplete_details;
        if details is ResponsesEventIncompleteDetails && details.reason == "content_filter" {
            return ai:CONTENT_FILTER;
        }
    }
    return ai:LENGTH;
}

# Builds the message for a "response.failed" event, preferring the failure detail the
# Responses API carries on the response snapshot.
#
# + ev - The "response.failed" event
# + return - The failure message
isolated function responsesFailureMessage(ResponsesStreamEvent ev) returns string {
    ResponsesEventResponse? response = ev.response;
    if response is ResponsesEventResponse {
        ResponsesEventError? failure = response.'error;
        if failure is ResponsesEventError {
            string? message = failure.message;
            string? code = failure.code;
            if message is string && code is string {
                return string `Response generation failed (${code}): ${message}`;
            }
            if message is string {
                return string `Response generation failed: ${message}`;
            }
        }
    }
    return "Response generation failed";
}

# Extracts the message from an OpenAI `{"error": {...}}` frame, which either API can emit
# mid-stream when generation is cut short (a rate limit tripped part-way, for example).
#
# + payload - The parsed `data:` payload of one SSE frame
# + return - The error message, or `()` when the payload is not an error frame
isolated function extractStreamErrorFrame(json payload) returns string? {
    if payload !is map<json> {
        return ();
    }
    json? failure = payload["error"];
    if failure is () {
        return ();
    }
    if failure is map<json> {
        json? message = failure["message"];
        if message is string {
            return message;
        }
    }
    return failure.toJsonString();
}


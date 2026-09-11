# Change Log

This file documents all significant changes made to the Ballerina ai.openai package across releases.

## [Un-released]

### Added
- [Add support for the OpenAI Responses API, selectable through the `apiType` configuration](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Add the current OpenAI model families to `OPEN_AI_MODEL_NAMES`: `gpt-5.6`, `gpt-5.5`, `gpt-5.5-pro`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.4-pro` and `gpt-5.3-codex`](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Add a `reasoningEffort` initialization parameter for reasoning-capable models, applied on both the Chat Completions (`reasoning_effort`) and the Responses (`reasoning.effort`) APIs, matching `ai.azure`](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Validate `reasoningEffort` against the selected model at initialization, so an unsupported effort fails fast instead of being rejected by OpenAI on the first call](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Add `chatStream`, which streams the model's answer as normalized `ai:ChatCompletionChunk` values - a union of text, reasoning, tool-call and stop chunks, each carrying exactly one kind of update - over the Chat Completions or the Responses API, selected by `apiType`. A single wire chunk carrying several updates at once fans out into several chunks sharing one `id`. Token usage is reported to the observability span rather than on a chunk](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Add `generateStream`, which streams a generated `string` answer; other expected types return an error, since a partial generation is a valid value only for `string`](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Streaming requests reach OpenAI under the caller's full `ConnectionConfig`, so a proxy or a custom truststore applies to `chatStream` exactly as it does to `chat`](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Streaming calls open an observability chat span, closed when the stream ends, carrying the finish reason and token usage as the non-streaming calls do](https://github.com/wso2/product-ballerina-integrator/issues/2457)

### Updated
- [Update batchEmbed to Validate Chunks at Element Level](https://github.com/ballerina-platform/ballerina-library/issues/8171)
- [`apiType` now defaults to `CHAT_COMPLETIONS`; the Responses API is opt-in](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Passing `stop` with `apiType = RESPONSES` now returns an `ai:Error` instead of being silently dropped, as the Responses API has no stop-sequence parameter](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [`generate()` now applies `reasoningEffort` on both the Chat Completions and the Responses API, matching `chat()`](https://github.com/wso2/product-ballerina-integrator/issues/2457)

### Fixed
- [A streaming request rejected by OpenAI now returns the API's own message and status instead of an opaque "failed to open the stream" error](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [A malformed frame, an `{"error": ...}` frame, a Responses `error` event, or a `response.failed` event now fails the stream instead of ending it silently and handing the caller a truncated answer as if it were complete](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Tool calls streamed over the Responses API now carry the dense, 0-based `index` the Chat Completions path produces, rather than the Responses output-item index, which also counts reasoning and message items](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [A completed Responses stream that produced tool calls now reports the `tool_calls` finish reason, matching the Chat Completions path](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [`generate()` on the Responses API now reports a failed, cancelled or truncated response for what it is, instead of reporting that the model had no relevant response](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Tool results are paired with the assistant tool call they answer through the ids actually issued, so a call and its result no longer drift apart when only one of them carries an id](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [Models without native tool-call support are driven through the ReAct prompt on both APIs again: the request no longer declares tools they cannot use, and tool results are no longer sent as `tool`-role messages answering a `tool_call_id` that was never issued](https://github.com/wso2/product-ballerina-integrator/issues/2457)
- [`temperature` is sent only when the caller sets one, instead of putting an explicit `null` on the wire](https://github.com/wso2/product-ballerina-integrator/issues/2457)

## [1.2.1] - 2025-07-27

### Added
- [Add `batchEmbed` API in `EmbeddingProvider`](https://github.com/ballerina-platform/ballerina-library/issues/8110)
- Bump AI module dependency version to 1.1.0

## [1.0.0] - 2025-07-09

### Added
- Add Implementations for ModelProvider and EmbeddingProvider

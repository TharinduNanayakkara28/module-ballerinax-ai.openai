## Overview

OpenAI provides powerful AI models for natural language processing, image generation, and other advanced tasks.

The OpenAI connector offers APIs for connecting with OpenAI Large Language Models (LLMs), enabling the integration of advanced conversational AI, text generation, and language processing capabilities into applications.

### Key Features

- Connect and interact with OpenAI Large Language Models (LLMs)
- Support for GPT-4o, GPT-4, GPT-3.5, and other advanced models
- A choice of the Chat Completions API or the Responses API, selected with `apiType`
- Efficient handling of conversational prompts and completions
- Streaming responses, so the answer can be shown as it is produced
- Secure communication with API key authentication

## Prerequisites

Before using this module in your Ballerina application, first you must obtain the nessary configuration to engage the LLM.

- Create an [OpenAI account](https://beta.openai.com/signup/).
- Obtain an API key by following [these instructions](https://platform.openai.com/docs/api-reference/authentication).


## Quickstart

To use the `ai.openai` module in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ai.openai;` module.

```ballerina
import ballerinax/ai.openai;
```

### Step 2: Intialize the Model Provider

Here's how to initialize the Model Provider:

```ballerina
import ballerina/ai;
import ballerinax/ai.openai;

final ai:ModelProvider openAiModel = check new openai:ModelProvider("openAiApiKey", modelType = openai:GPT_4O);
```

### Step 4: Invoke chat completion

```ballerina
ai:ChatMessage[] chatMessages = [{role: "user", content: "hi"}];
ai:ChatAssistantMessage response = check openAiModel->chat(chatMessages, tools = []);

chatMessages.push(response);
```

### Step 5: Stream the response

To show the answer as it is produced rather than waiting for all of it, use `generateStream` for
the generated text, or `chatStream` for the raw chunks:

```ballerina
stream<string, ai:Error?> fragments = check openAiModel->generateStream(`Tell me about Ballerina`);
check from string fragment in fragments
    do {
        io:print(fragment);
    };
```

`ai:ChatCompletionChunk` from `chatStream` is a union of four single-purpose chunk types -
`ai:ChatCompletionTextChunk` (`content`), `ai:ChatCompletionReasoningChunk` (`reasoning`),
`ai:ChatCompletionToolCallChunk` (`toolCalls`) and `ai:ChatCompletionStopChunk`
(`finishReason`) - so narrow with `is` to tell them apart. Each chunk carries exactly one kind
of update, and one provider event may map onto several chunks in a row, all sharing the same
`id`. Tool-call fragments are correlated by `index`, numbered the same way whichever `apiType`
is in use. Token usage is not carried on any chunk; it is reported to the observability span.
`generateStream` supports only `string`, since a partial generation is a valid value only for
`string`; use `generate` for structured output.

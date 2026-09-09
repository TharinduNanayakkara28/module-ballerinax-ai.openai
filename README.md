# Ballerina OpenAI Model Provider Library

[![Build](https://github.com/ballerina-platform/module-ballerinax-ai.openai/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-ai.openai/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-ai.openai.svg)](https://github.com/ballerina-platform/module-ballerinax-ai.openai/commits/main)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

This module provides a generic API for connecting with OpenAI's LLM chat completion models.

It talks to either of OpenAI's two APIs, chosen with the `apiType` initialization parameter:
`CHAT_COMPLETIONS` (the default) or `RESPONSES`. Both support the same operations - `chat` and
`generate` for a complete answer, and `chatStream` and `generateStream` to receive the answer as
it is produced.

```ballerina
import ballerina/ai;
import ballerina/io;
import ballerinax/ai.openai;

configurable string apiKey = ?;

public function main() returns error? {
    ai:ModelProvider model = check new openai:ModelProvider(apiKey, openai:GPT_4O);

    // The whole answer, once it is ready.
    string answer = check model->generate(`Explain Server-Sent Events in a sentence.`);

    // The same answer, a fragment at a time.
    stream<string, ai:Error?> fragments = check model->generateStream(
            `Explain Server-Sent Events in a sentence.`);
    check from string fragment in fragments
        do {
            io:print(fragment);
        };
}
```

`chatStream` gives the raw chunks instead: each `ai:ChatCompletionChunk` carries text, reasoning
and tool-call fragments directly on the chunk - `content`, `reasoning` and `toolCalls` - and the
last one carries the `finishReason`. Tool-call fragments are correlated by `index`, and the
numbering is the same whichever `apiType` is in use. Token usage is not carried on the chunk; it is
reported to the observability span. `generateStream` supports only `string` - a partial generation
is a valid value only for `string`, so any other expected type returns an error; use `generate` for
structured output.

## Issues and projects

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Library. To report bugs, request new features, start new discussions, view project boards, etc., go to the [Ballerina Library parent repository](https://github.com/ballerina-platform/ballerina-standard-library).
This repository only contains the source code for the module.

## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 21 (from one of the following locations).

   - [Oracle](https://www.oracle.com/java/technologies/downloads/)
   - [OpenJDK](https://adoptium.net/)

     > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Generate a GitHub access token with read package permissions, then set the following `env` variables:

   ```shell
   export packageUser=<Your GitHub Username>
   export packagePAT=<GitHub Personal Access Token>
   ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To run a group of tests

   ```bash
   ./gradlew clean test -Pgroups=<test_group_names>
   ```

4. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina central repository:

   ```bash
   ./gradlew clean build -PpublishToLocalCentral=true
   ```

8. Publish the generated artifacts to the Ballerina central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

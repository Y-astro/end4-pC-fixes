import QtQuick

ApiStrategy {
    property bool isReasoning: false
    property var toolCallAccumulator: null
    
    function buildEndpoint(model: AiModel): string {
        // console.log("[AI] Endpoint: " + model.endpoint);
        return model.endpoint;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let formattedMessages = [
            { role: "system", content: systemPrompt }
        ];

        messages.forEach(message => {
            if (message.functionCall && message.functionName && message.functionName.length > 0) {
                // Assistant message that requested a function call
                const argsStr = (typeof message.functionCall.args === "string") 
                    ? message.functionCall.args 
                    : JSON.stringify(message.functionCall.args || {});
                
                formattedMessages.push({
                    "role": "assistant",
                    "content": message.content ? message.content.replace(/\n\n\*\*Command execution request\*\*[\s\S]*/, "").trim() : null,
                    "tool_calls": [{
                        "id": message.functionCall.id || "call_cmd",
                        "type": "function",
                        "function": {
                            "name": message.functionName,
                            "arguments": argsStr
                        }
                    }]
                });
            } else if (message.functionResponse !== undefined && message.functionName && message.functionName.length > 0) {
                // Tool output message
                formattedMessages.push({
                    "role": "tool",
                    "tool_call_id": message.functionCall?.id || "call_cmd",
                    "name": message.functionName,
                    "content": message.functionResponse
                });
            } else {
                // Regular chat message
                formattedMessages.push({
                    "role": message.role,
                    "content": message.rawContent
                });
            }
        });

        let baseData = {
            "model": model.model,
            "messages": formattedMessages,
            "stream": true,
            "temperature": temperature,
        };

        if (tools && tools.length > 0) {
            baseData.tools = tools;
        }

        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "Authorization: Bearer \$\{${apiKeyEnvVarName}\}"`;
    }

    function finishToolCall(message) {
        if (!toolCallAccumulator || !toolCallAccumulator.name) return { finished: true };
        let parsedArgs = {};
        try {
            parsedArgs = JSON.parse(toolCallAccumulator.arguments || "{}");
        } catch (e) {
            console.log("[AI] Could not parse tool arguments JSON: ", toolCallAccumulator.arguments);
            parsedArgs = { command: toolCallAccumulator.arguments };
        }
        const callObj = {
            id: toolCallAccumulator.id,
            name: toolCallAccumulator.name,
            args: parsedArgs
        };
        toolCallAccumulator = null;
        return {
            functionCall: callObj,
            finished: true
        };
    }

    function parseResponseLine(line, message) {
        // Remove 'data: ' prefix if present and trim whitespace
        let cleanData = line.trim();
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        // console.log("[AI] OpenAI: Data:", cleanData);
        
        // Handle special cases
        if (!cleanData || cleanData.startsWith(":")) return {};
        if (cleanData === "[DONE]") {
            if (toolCallAccumulator && toolCallAccumulator.name) {
                return finishToolCall(message);
            }
            return { finished: true };
        }
        
        // Real stuff
        try {
            const dataJson = JSON.parse(cleanData);

            // Error response handling
            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            let newContent = "";

            const responseContent = dataJson.choices?.[0]?.delta?.content || dataJson.message?.content;
            const responseReasoning = dataJson.choices?.[0]?.delta?.reasoning || dataJson.choices?.[0]?.delta?.reasoning_content;

            // Check for tool calls
            const toolCalls = dataJson.choices?.[0]?.delta?.tool_calls || dataJson.message?.tool_calls;
            if (toolCalls && toolCalls.length > 0) {
                const tc = toolCalls[0];
                if (!toolCallAccumulator) {
                    toolCallAccumulator = {
                        id: tc.id || ("call_" + Date.now().toString(36)),
                        name: tc.function?.name || "",
                        arguments: tc.function?.arguments || ""
                    };
                } else {
                    if (tc.id) toolCallAccumulator.id = tc.id;
                    if (tc.function?.name) toolCallAccumulator.name = tc.function.name;
                    if (tc.function?.arguments) toolCallAccumulator.arguments += tc.function.arguments;
                }
            }

            if (responseContent && responseContent.length > 0) {
                if (isReasoning) {
                    isReasoning = false;
                    const endBlock = "\n\n</think>\n\n";
                    message.content += endBlock;
                    message.rawContent += endBlock;
                }
                newContent = responseContent;
            } else if (responseReasoning && responseReasoning.length > 0) {
                if (!isReasoning) {
                    isReasoning = true;
                    const startBlock = "\n\n<think>\n\n";
                    message.rawContent += startBlock;
                    message.content += startBlock;
                }
                newContent = responseReasoning;
            }

            message.content += newContent;
            message.rawContent += newContent;

            // Usage metadata
            if (dataJson.usage) {
                return {
                    tokenUsage: {
                        input: dataJson.usage.prompt_tokens ?? -1,
                        output: dataJson.usage.completion_tokens ?? -1,
                        total: dataJson.usage.total_tokens ?? -1
                    }
                };
            }

            const finishReason = dataJson.choices?.[0]?.finish_reason;
            if (finishReason === "tool_calls" || ((dataJson.done) && toolCallAccumulator)) {
                return finishToolCall(message);
            }

            if (dataJson.done) {
                return { finished: true };
            }
            
        } catch (e) {
            console.log("[AI] OpenAI: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }
        
        return {};
    }
    
    function onRequestFinished(message) {
        if (toolCallAccumulator && toolCallAccumulator.name) {
            return finishToolCall(message);
        }
        return { finished: true };
    }
    
    function reset() {
        isReasoning = false;
        toolCallAccumulator = null;
    }

}

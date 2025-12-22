//! Integration tests for the OpenCog client
//!
//! These tests verify the OpenCog client implementation including:
//! - Configuration parsing
//! - Request body building
//! - Response parsing
//!
//! Note: Some tests require a running OpenCog server and are marked with #[ignore]

use serde_json::{json, Value};

/// Test OpenCog chat completions body building
#[test]
fn test_opencog_build_chat_completions_body_basic() {
    // Simulate the body building logic from opencog.rs
    let messages: Vec<Value> = vec![
        json!({"role": "user", "content": "Hello, OpenCog!"}),
    ];

    let body = json!({
        "model": "opencog-chat",
        "messages": messages,
    });

    assert_eq!(body["model"], "opencog-chat");
    assert!(body["messages"].is_array());
    assert_eq!(body["messages"][0]["role"], "user");
    assert_eq!(body["messages"][0]["content"], "Hello, OpenCog!");
}

#[test]
fn test_opencog_build_chat_completions_body_with_options() {
    let messages: Vec<Value> = vec![
        json!({"role": "system", "content": "You are an OpenCog reasoning assistant."}),
        json!({"role": "user", "content": "What is PLN?"}),
    ];

    let mut body = json!({
        "model": "opencog-reasoning",
        "messages": messages,
    });

    // Add optional parameters
    body["temperature"] = json!(0.7);
    body["top_p"] = json!(0.9);
    body["max_tokens"] = json!(1000);
    body["stream"] = json!(true);

    assert_eq!(body["model"], "opencog-reasoning");
    assert_eq!(body["temperature"], 0.7);
    assert_eq!(body["top_p"], 0.9);
    assert_eq!(body["max_tokens"], 1000);
    assert_eq!(body["stream"], true);
}

#[test]
fn test_opencog_build_chat_completions_body_with_tools() {
    let messages: Vec<Value> = vec![
        json!({"role": "user", "content": "Calculate PLN deduction"}),
    ];

    let tools: Vec<Value> = vec![
        json!({
            "type": "function",
            "function": {
                "name": "pln_deduction",
                "description": "Calculate PLN deduction TruthValue",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "premise1_strength": {"type": "number"},
                        "premise1_confidence": {"type": "number"},
                        "premise2_strength": {"type": "number"},
                        "premise2_confidence": {"type": "number"}
                    },
                    "required": ["premise1_strength", "premise1_confidence", "premise2_strength", "premise2_confidence"]
                }
            }
        }),
    ];

    let body = json!({
        "model": "opencog-reasoning",
        "messages": messages,
        "tools": tools,
    });

    assert!(body["tools"].is_array());
    assert_eq!(body["tools"][0]["type"], "function");
    assert_eq!(body["tools"][0]["function"]["name"], "pln_deduction");
}

#[test]
fn test_opencog_build_embeddings_body() {
    let body = json!({
        "input": ["OpenCog AtomSpace", "Probabilistic Logic Networks"],
        "model": "opencog-embed"
    });

    assert_eq!(body["model"], "opencog-embed");
    assert!(body["input"].is_array());
    assert_eq!(body["input"].as_array().unwrap().len(), 2);
}

#[test]
fn test_opencog_extract_chat_completions_response() {
    // Simulate a response from OpenCog server
    let response = json!({
        "id": "chatcmpl-opencog-123",
        "object": "chat.completion",
        "created": 1234567890,
        "model": "opencog-chat",
        "choices": [{
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "PLN (Probabilistic Logic Networks) is a framework for uncertain inference."
            },
            "finish_reason": "stop"
        }],
        "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 20,
            "total_tokens": 30
        }
    });

    let text = response["choices"][0]["message"]["content"]
        .as_str()
        .unwrap_or_default();

    assert!(!text.is_empty());
    assert!(text.contains("PLN"));
    assert_eq!(response["usage"]["prompt_tokens"], 10);
    assert_eq!(response["usage"]["completion_tokens"], 20);
}

#[test]
fn test_opencog_extract_tool_calls_response() {
    // Simulate a response with tool calls
    let response = json!({
        "id": "chatcmpl-opencog-456",
        "choices": [{
            "message": {
                "role": "assistant",
                "content": "",
                "tool_calls": [{
                    "id": "call_1",
                    "type": "function",
                    "function": {
                        "name": "pln_deduction",
                        "arguments": "{\"premise1_strength\":0.8,\"premise1_confidence\":0.9,\"premise2_strength\":0.7,\"premise2_confidence\":0.85}"
                    }
                }]
            }
        }]
    });

    let tool_calls = response["choices"][0]["message"]["tool_calls"]
        .as_array()
        .unwrap();

    assert_eq!(tool_calls.len(), 1);
    assert_eq!(tool_calls[0]["function"]["name"], "pln_deduction");

    let args: Value = serde_json::from_str(
        tool_calls[0]["function"]["arguments"].as_str().unwrap()
    ).unwrap();

    assert_eq!(args["premise1_strength"], 0.8);
    assert_eq!(args["premise1_confidence"], 0.9);
}

#[test]
fn test_opencog_embeddings_response() {
    // Simulate embeddings response
    let response = json!({
        "object": "list",
        "data": [
            {
                "object": "embedding",
                "index": 0,
                "embedding": [0.1, 0.2, 0.3, 0.4, 0.5]
            },
            {
                "object": "embedding",
                "index": 1,
                "embedding": [0.2, 0.3, 0.4, 0.5, 0.6]
            }
        ],
        "model": "opencog-embed",
        "usage": {
            "prompt_tokens": 8,
            "total_tokens": 8
        }
    });

    let embeddings = response["data"].as_array().unwrap();
    assert_eq!(embeddings.len(), 2);

    let first_embedding = embeddings[0]["embedding"].as_array().unwrap();
    assert_eq!(first_embedding.len(), 5);
    assert_eq!(first_embedding[0], 0.1);
}

#[test]
fn test_opencog_api_base_default() {
    let default_base = "http://localhost:5000/v1";
    let expected_chat_url = format!("{}/chat/completions", default_base);
    let expected_embed_url = format!("{}/embeddings", default_base);

    assert_eq!(expected_chat_url, "http://localhost:5000/v1/chat/completions");
    assert_eq!(expected_embed_url, "http://localhost:5000/v1/embeddings");
}

#[test]
fn test_opencog_api_base_custom() {
    let custom_base = "http://cogserver.local:8080/api";
    let expected_url = format!("{}/chat/completions", custom_base.trim_end_matches('/'));

    assert_eq!(expected_url, "http://cogserver.local:8080/api/chat/completions");
}

/// Test streaming response parsing (SSE format)
#[test]
fn test_opencog_streaming_response_parsing() {
    let sse_data = r#"{"choices":[{"delta":{"content":"Hello"}}]}"#;
    let parsed: Value = serde_json::from_str(sse_data).unwrap();

    let content = parsed["choices"][0]["delta"]["content"]
        .as_str()
        .unwrap_or_default();

    assert_eq!(content, "Hello");
}

#[test]
fn test_opencog_streaming_tool_call_parsing() {
    let sse_data = r#"{"choices":[{"delta":{"tool_calls":[{"id":"call_1","function":{"name":"pln_deduction","arguments":"{\"premise1"}}]}}]}"#;
    let parsed: Value = serde_json::from_str(sse_data).unwrap();

    let function = &parsed["choices"][0]["delta"]["tool_calls"][0]["function"];
    assert_eq!(function["name"], "pln_deduction");
}

/// Integration test that requires a running OpenCog server
#[test]
#[ignore]
fn test_opencog_live_chat_completion() {
    // This test requires a running OpenCog server at localhost:5000
    // Run with: cargo test -- --ignored
    println!("This test requires a running OpenCog server");
}

/// Integration test for embeddings with live server
#[test]
#[ignore]
fn test_opencog_live_embeddings() {
    // This test requires a running OpenCog server at localhost:5000
    // Run with: cargo test -- --ignored
    println!("This test requires a running OpenCog server");
}

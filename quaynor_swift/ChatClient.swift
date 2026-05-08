//
//  ChatClient.swift
//  quaynor_swift
//

import Foundation
import Quaynor

let circleArea = Tool(
    name: "circle_area",
    description: "Calculates the area of a circle from its radius when the user asks.",
    parameters: [
        ToolParameterDefinition(
            name: "radius",
            schema: .number(description: "The circle radius.")
        )
    ]
) { args in
    let radius = (args[0] as? Double) ?? 0
    let area = Double.pi * radius * radius
    return String(format: "%.2f", area)
}

enum ChatClientError: LocalizedError {
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Model is not ready."
        }
    }
}

actor ChatClient {
    static let shared = ChatClient()

    // Replace with a local file path if you have a downloaded model on device.
    private let modelPath = "huggingface:bartowski/Qwen_Qwen3-0.6B-GGUF/Qwen_Qwen3-0.6B-Q4_K_M.gguf"
    private let systemPrompt = "You are a helpful general assistant. Only talk about or use tools when the user asks."
    private var model: Model?
    private var chat: Chat?

    private func loadIfNeeded() async throws {
        if chat != nil {
            return
        }

        let loadedModel = try await Model.load(modelPath: modelPath)
        model = loadedModel

        let newChat = try Chat(model: loadedModel)
        try await newChat.resetContext(systemPrompt: systemPrompt)
        try await newChat.setTools([circleArea])
        chat = newChat
    }

    func reply(message: String) async throws -> String {
        let stream = try await streamReply(message: message)
        return try await stream.completed()
    }

    func streamReply(message: String) async throws -> TokenStream {
        try await loadIfNeeded()
        guard let chat else {
            throw ChatClientError.modelUnavailable
        }

        return try chat.ask(message)
    }

    func resetConversation() async throws {
        guard let chat else {
            return
        }

        try await chat.resetContext(systemPrompt: systemPrompt)
    }
}

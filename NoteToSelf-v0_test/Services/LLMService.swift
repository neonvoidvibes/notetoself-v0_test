import Foundation
import OpenAI // Using the swift-openai-responses SDK module

@MainActor // Ensure service methods are called on the main actor
final class LLMService {
    static let shared = LLMService()

    private let openAIClient: ResponsesAPI // Client from swift-openai-responses SDK

    private init() {
        // TODO: [SECURITY] In production, the API key should ideally be fetched securely at runtime (e.g., Remote Config) or requests proxied through your own backend, not loaded directly here even via APIConfiguration.
        let apiKey = APIConfiguration.openAIAPIKey
        self.openAIClient = ResponsesAPI(authToken: apiKey)
        print("LLMService initialized with ResponsesAPI client (using development key loading).")
    }

    /// Generates a conversational response (plain text).
    func generateChatResponse(systemPrompt: String, userMessage: String) async throws -> String {
        print("LLMService: Generating chat response for user message: '\(userMessage.prefix(50))...'")

        // Construct the request using the SDK's Request struct
        let request = Request(
            model: "gpt-4o", // Specify the desired model
            input: .text(userMessage),
            instructions: systemPrompt // System prompt goes here
            // Add other parameters like temperature if needed via the Request initializer
        )

        do {
            // Use the create method from the SDK
            let response = try await openAIClient.create(request)
            
            // Extract the text output
            // Note: The SDK provides `outputText` convenience property
            guard let replyContent = response.outputText, !replyContent.isEmpty else {
                 // Handle cases where the model might refuse or return empty content
                 if let refusal = response.refusal {
                      print("LLMService: Model refused - \(refusal)")
                      throw LLMError.modelRefusal(refusal)
                 }
                 throw LLMError.unexpectedResponse("No text content in chat response")
            }
            print("LLMService: Received chat response.")
            return replyContent
        } catch let error as APIError {
            // Handle specific API errors from the SDK if needed
            print("LLMService: OpenAI API Error - \(error)")
            throw LLMError.sdkError("API Error: \(error.localizedDescription)")
        } catch {
            // Handle other potential errors (network, etc.)
            print("LLMService: Error during chat generation - \(error)")
            throw LLMError.sdkError("Network or other error: \(error.localizedDescription)")
        }
    }

    /// Generates structured output conforming to a specific Decodable type and JSON schema.
    /// NOTE: swift-openai-responses SDK doesn't directly support forcing JSON schema output via `response_format`.
    /// We rely on instructing the model via the prompt and then decoding the resulting text string.
    func generateStructuredOutput<T: Decodable>(
        systemPrompt: String, // Prompt MUST strongly instruct for JSON output matching the schema
        userMessage: String,
        responseModel: T.Type
        // jsonSchema parameter removed as it's not directly used by this SDK's 'create' method
    ) async throws -> T {
        print("LLMService: Generating structured output for type \(T.self)...")

        // Construct the request - the systemPrompt MUST demand JSON output.
        let request = Request(
            model: "gpt-4o", // Use a model known to be good at following JSON instructions
            input: .text(userMessage),
            instructions: systemPrompt // This prompt is critical for getting JSON back
            // Consider setting temperature lower (e.g., 0.2) for more deterministic JSON output if needed
        )

        do {
            let response = try await openAIClient.create(request)

            guard let jsonString = response.outputText, !jsonString.isEmpty else {
                if let refusal = response.refusal {
                     print("LLMService: Model refused structured output - \(refusal)")
                     throw LLMError.modelRefusal(refusal)
                }
                throw LLMError.unexpectedResponse("No JSON content string in structured response")
            }
            print("LLMService: Received potential JSON string: \(jsonString.prefix(300))...")

            // Attempt to clean potential markdown ```json ... ``` wrappers if the model adds them
            let cleanedJsonString = jsonString
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^```json\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s*```$", with: "", options: .regularExpression)

            // Decode the JSON string
            guard let jsonData = cleanedJsonString.data(using: .utf8) else {
                throw LLMError.decodingError("Failed to convert cleaned JSON string to Data. Original: \(jsonString)")
            }
            let decoder = JSONDecoder()
            do {
                let decodedObject = try decoder.decode(T.self, from: jsonData)
                print("LLMService: Successfully decoded structured response into \(T.self).")
                return decodedObject
            } catch let decodingError {
                print("LLMService: JSON Decoding Error - \(decodingError)")
                // Provide more context in the error
                throw LLMError.decodingError("Failed to decode JSON into \(T.self): \(decodingError.localizedDescription). Received string (cleaned): '\(cleanedJsonString)'")
            }
        } catch let error as APIError {
             print("LLMService: OpenAI API Error during structured output - \(error)")
            throw LLMError.sdkError("API Error: \(error.localizedDescription)")
        } catch let error as LLMError {
             // Re-throw specific LLM errors
             throw error
        } catch {
            print("LLMService: Other error during structured output - \(error)")
            throw LLMError.sdkError("Network or other error: \(error.localizedDescription)")
        }
    }

    // Define potential errors
    enum LLMError: Error, LocalizedError {
        case sdkError(String)
        case modelRefusal(String?) // Added case for refusals
        case unexpectedResponse(String)
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .sdkError(let reason): return "LLM Service Error: \(reason)"
            case .modelRefusal(let reason): return "LLM Refused Request: \(reason ?? "No specific reason provided.")"
            case .unexpectedResponse(let reason): return "Unexpected LLM response: \(reason)"
            case .decodingError(let reason): return "JSON Decoding Error: \(reason)"
            }
        }
    }
}
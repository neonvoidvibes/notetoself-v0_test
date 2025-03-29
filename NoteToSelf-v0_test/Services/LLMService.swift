import Foundation
import OpenAI // Using the swift-openai-responses SDK module

@MainActor // Ensure service methods are called on the main actor
final class LLMService {
    static let shared = LLMService()

    // Client from swift-openai-responses SDK
    private let openAIClient: ResponsesAPI

    private init() {
        // TODO: [SECURITY] In production, the API key should ideally be fetched securely at runtime (e.g., Remote Config) or requests proxied through your own backend, not loaded directly here even via APIConfiguration.
        let apiKey = APIConfiguration.openAIAPIKey
        self.openAIClient = ResponsesAPI(authToken: apiKey)
        print("LLMService initialized with ResponsesAPI client (using development key loading).")
    }

    // Helper function to create a Model type from its ID string
    private func createModel(from id: String) -> Model {
        guard let data = "\"\(id)\"".data(using: .utf8),
              let model = try? JSONDecoder().decode(Model.self, from: data) else {
            fatalError("❌ Failed to create Model enum/struct from id string: \(id)")
        }
        return model
    }

    /// Generates a conversational response (plain text).
    func generateChatResponse(systemPrompt: String, userMessage: String) async throws -> String {
        print("LLMService: Generating chat response for user message: '\(userMessage.prefix(50))...'")

        let model = createModel(from: "gpt-4o")

        let request = Request(
            model: model,
            input: .text(userMessage),
            instructions: systemPrompt
        )

        do {
            // Add 'try' before the await call
            let result: Result<Response, Response.Error> = try await openAIClient.create(request)

            // Handle the Result
            switch result {
            case .success(let response):
                // Assuming outputText is non-optional based on error "Initializer for conditional binding must have Optional type"
                let replyContent = response.outputText

                // Check if the non-optional content is empty, potentially indicating refusal or empty response
                if replyContent.isEmpty {
                    // We don't have direct access to 'refusal' here based on errors.
                    // Assume empty outputText might imply refusal or just an empty answer.
                     print("LLMService: Received empty outputText, potentially a refusal or empty response.")
                     // Decide how to handle this - throw an error or return empty string? Let's throw.
                     throw LLMError.unexpectedResponse("Received empty text content from LLM")
                }

                print("LLMService: Received chat response.")
                return replyContent

            case .failure(let error):
                print("LLMService: OpenAI API Error - \(error)")
                throw LLMError.sdkError("API Error: \(error.localizedDescription)")
            }
        } catch let error as LLMError {
             throw error
        } catch {
            print("LLMService: Error during chat generation - \(error)")
            throw LLMError.sdkError("Network or other error: \(error.localizedDescription)")
        }
    }

    /// Generates structured output conforming to a specific Decodable type.
    func generateStructuredOutput<T: Decodable>(
        systemPrompt: String, // Prompt MUST strongly instruct for JSON output
        userMessage: String,
        responseModel: T.Type
    ) async throws -> T {
        print("LLMService: Generating structured output for type \(T.self)...")

        let model = createModel(from: "gpt-4o")

        let request = Request(
            model: model,
            input: .text(userMessage),
            instructions: systemPrompt
        )

        do {
            // Add 'try' before the await call
            let result: Result<Response, Response.Error> = try await openAIClient.create(request)

            switch result {
            case .success(let response):
                // Assuming outputText is non-optional based on error
                let jsonString = response.outputText

                if jsonString.isEmpty {
                     print("LLMService: Received empty outputText for structured response, potentially a refusal.")
                     throw LLMError.unexpectedResponse("Received empty JSON content string from LLM")
                }
                print("LLMService: Received potential JSON string: \(jsonString.prefix(300))...")

                // Clean potential markdown wrappers
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
                    throw LLMError.decodingError("Failed to decode JSON into \(T.self): \(decodingError.localizedDescription). Received string (cleaned): '\(cleanedJsonString)'")
                }

            case .failure(let error):
                 print("LLMService: OpenAI API Error during structured output - \(error)")
                throw LLMError.sdkError("API Error: \(error.localizedDescription)")
            }
        } catch let error as LLMError {
             throw error
        } catch {
            print("LLMService: Other error during structured output - \(error)")
            throw LLMError.sdkError("Network or other error: \(error.localizedDescription)")
        }
    }

    // Define potential errors
    enum LLMError: Error, LocalizedError {
        case sdkError(String)
        // Model refusal is now implicitly handled by checking for empty outputText
        // case modelRefusal(String?)
        case unexpectedResponse(String)
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .sdkError(let reason): return "LLM Service Error: \(reason)"
            // case .modelRefusal(let reason): return "LLM Refused Request: \(reason ?? "No specific reason provided.")"
            case .unexpectedResponse(let reason): return "Unexpected LLM response: \(reason)"
            case .decodingError(let reason): return "JSON Decoding Error: \(reason)"
            }
        }
    }
}
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
        // Add validation for supported model IDs
        guard ["gpt-4o", "gpt-4o-mini"].contains(id) else {
             fatalError("❌ Unsupported model ID requested: \(id). Only 'gpt-4o' and 'gpt-4o-mini' are currently configured.")
        }

        guard let data = "\"\(id)\"".data(using: .utf8),
              let model = try? JSONDecoder().decode(Model.self, from: data) else {
             // This might indicate an issue with the SDK's Model type or the ID string format
            fatalError("❌ Failed to create Model enum/struct from validated id string: \(id)")
        }
        print("[LLMService] Using model: \(id)") // Log which model is being used
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
        print("LLMService: Generating structured output for type \(T.self) using gpt-4o-mini...")

        let maxAttempts = 3 // Total attempts (1 initial + 2 retries)
        let retryDelaySeconds: Double = 0.5 // Short delay between retries

        for attempt in 1...maxAttempts {
            print("LLMService: Structured Output Attempt \(attempt)/\(maxAttempts)...")
            do {
                // Explicitly use gpt-4o-mini for structured output/insights
                let model = createModel(from: "gpt-4o-mini")

                let request = Request(
                    model: model,
                    input: .text(userMessage),
                    instructions: systemPrompt
                )

                let result: Result<Response, Response.Error> = try await openAIClient.create(request)

                switch result {
                case .success(let response):
                    let jsonString = response.outputText

                    if jsonString.isEmpty {
                         print("LLMService: Received empty outputText on attempt \(attempt), potentially a refusal.")
                         // Don't retry empty responses immediately, throw specific error
                         throw LLMError.unexpectedResponse("Received empty JSON content string from LLM on attempt \(attempt)")
                    }
                    // Log prefix before cleaning
                    // print("LLMService: Received potential JSON on attempt \(attempt): \(jsonString.prefix(300))...")

                    // Clean potential markdown wrappers
                    let cleanedJsonString = jsonString
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "^```json\\s*", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "\\s*```$", with: "", options: .regularExpression)

                    guard let jsonData = cleanedJsonString.data(using: .utf8) else {
                        // If cleaning results in empty/invalid data, treat as decoding error for retry
                        print("LLMService: Failed to convert cleaned JSON string to Data on attempt \(attempt). Original: \(jsonString)")
                        if attempt == maxAttempts {
                             throw LLMError.decodingError("Failed to convert cleaned JSON string to Data after \(maxAttempts) attempts. Original: \(jsonString)")
                        }
                         // Fall through to retry delay
                         print("LLMService: Conversion to Data failed, retrying...")
                         // Explicitly continue to next iteration after delay
                         try await Task.sleep(nanoseconds: UInt64(retryDelaySeconds * 1_000_000_000))
                         continue // Go to next attempt

                    }

                    // Decode the JSON string
                    let decoder = JSONDecoder()
                    do {
                        let decodedObject = try decoder.decode(T.self, from: jsonData)
                        print("LLMService: Successfully decoded structured response on attempt \(attempt).")
                        return decodedObject // SUCCESS: Exit loop and function
                    } catch let decodingError {
                        // SPECIFICALLY CATCH DECODING ERROR FOR RETRY
                        print("LLMService: JSON Decoding Error on attempt \(attempt): \(decodingError)")
                        // Log raw cleaned string that failed decoding
                        print("LLMService: Failed JSON string (cleaned): >>>\(cleanedJsonString)<<<")

                        if attempt == maxAttempts {
                            print("LLMService: Max retry attempts reached for decoding error.")
                            // Throw the specific decoding error after max attempts
                            throw LLMError.decodingError("Failed to decode JSON into \(T.self) after \(maxAttempts) attempts: \(decodingError.localizedDescription). Last received string (cleaned): '\(cleanedJsonString)'")
                        }
                        // Wait before retrying ONLY for decoding errors
                        print("LLMService: Waiting \(retryDelaySeconds)s before retry...")
                        try await Task.sleep(nanoseconds: UInt64(retryDelaySeconds * 1_000_000_000))
                        // Loop continues...
                    }

                case .failure(let error):
                     print("LLMService: OpenAI API Error on attempt \(attempt) - \(error)")
                    // Do not retry API errors (network, auth etc.)
                    throw LLMError.sdkError("API Error: \(error.localizedDescription)")
                }
            } catch LLMError.sdkError(let reason) {
                // Catch specific SDK errors - do not retry
                print("LLMService: SDKError caught on attempt \(attempt), throwing immediately: \(reason)")
                throw LLMError.sdkError(reason) // Re-throw the original error
            } catch LLMError.unexpectedResponse(let reason) {
                // Catch specific unexpected responses - do not retry
                print("LLMService: UnexpectedResponse caught on attempt \(attempt), throwing immediately: \(reason)")
                throw LLMError.unexpectedResponse(reason) // Re-throw the original error
            } catch let error {
                // Catch any remaining error types here.
                // Check if it's specifically a decoding error type that might warrant a retry.
                // Use 'if case let' for optional pattern matching on the LLMError case
                if case .decodingError = error as? LLMError {
                     // Specifically caught our custom decodingError enum case
                     print("LLMService: Outer catch hit for LLMError.decodingError on attempt \(attempt): \(error). Allowing retry loop to handle.")
                } else if error is DecodingError || (error as NSError).domain == NSCocoaErrorDomain {
                     // Caught a system decoding error or related Cocoa error
                     print("LLMService: Outer catch hit for System/Cocoa decoding-related error on attempt \(attempt): \(error). Allowing retry loop to handle.")
                } else {
                     // If it's not any kind of decoding error, treat it as unexpected and don't retry.
                     print("LLMService: Unexpected non-LLMError or non-decoding LLMError caught during attempt \(attempt): \(error)")
                     throw LLMError.unexpectedResponse("Unexpected error during structured output generation: \(error.localizedDescription)")
                }

                // If we haven't thrown, it was a decoding-related error, proceed with retry logic:
                if attempt == maxAttempts {
                    print("LLMService: Max attempts reached even in outer decoding catch.")
                    // Re-throw a generic decoding error if max attempts reached here too
                    throw LLMError.decodingError("Failed decoding-related operation after \(maxAttempts) attempts. Last error: \(error.localizedDescription)")
                }
                // Wait before retrying if caught here
                print("LLMService: Waiting \(retryDelaySeconds)s before retry (outer catch)...")
                try await Task.sleep(nanoseconds: UInt64(retryDelaySeconds * 1_000_000_000))
                // Loop continues...
            }
            // If we reach here, it means a decoding error occurred but it wasn't the last attempt.
            // The loop will continue after the delay.
        } // End for loop

        // This should technically be unreachable if the loop logic is correct
        fatalError("LLMService: generateStructuredOutput retry loop finished without returning or throwing an error.")
    }

    // Define potential errors - Added Equatable conformance
    enum LLMError: Error, LocalizedError, Equatable {
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
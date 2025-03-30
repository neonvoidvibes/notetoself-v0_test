import Foundation
import NaturalLanguage

// Actor to manage NLEmbedding instance and ensure thread-safe access
@available(iOS 16.0, *)
actor EmbeddingService {
    static let shared = EmbeddingService() // Singleton instance

    private let embeddingDimension = 512 // Expected dimension
    private var embeddingModel: NLEmbedding?

    private init() {
        // Initialize the model synchronously during actor initialization.
        // Actors ensure initialization happens safely before methods are called.
        print("[EmbeddingService] Initializing...")
        self.embeddingModel = loadModel()
        if embeddingModel != nil {
            print("[EmbeddingService] NLEmbedding model loaded successfully.")
        } else {
            print("‼️ [EmbeddingService] Failed to load NLEmbedding model during initialization.")
        }
    }

    private func loadModel() -> NLEmbedding? {
        guard let model = NLEmbedding.sentenceEmbedding(for: .english) else {
            print("‼️ [EmbeddingService] NLEmbedding.sentenceEmbedding returned nil.")
            return nil
        }
        guard model.dimension == embeddingDimension else {
            print("‼️ [EmbeddingService] Loaded NLEmbedding dimension (\(model.dimension)) doesn't match EXPECTED (\(embeddingDimension)).")
            return nil
        }
        return model
    }

    /// Generates a sentence embedding for the given text using the managed NLEmbedding instance.
    /// This method is safe to call from any thread due to the actor isolation.
    func generateEmbedding(for text: String) -> [Float]? {
        guard let model = self.embeddingModel else {
            print("‼️ [EmbeddingService] Embedding model not available.")
            return nil
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("[EmbeddingService] Input text is empty, skipping embedding generation.")
            return nil
        }

        // Calling vector(for:) within the actor ensures serial access.
        guard let vector = model.vector(for: text) else {
            print("⚠️ [EmbeddingService] Could not generate vector for text: '\(text.prefix(50))...'")
            return nil
        }

        // NLEmbedding returns [Double], convert to [Float]
        let floatVector = vector.map { Float($0) }
        // print("[EmbeddingService] Generated \(floatVector.count)-dim vector.")
        return floatVector
    }
}

// Global async function to access the embedding service easily, handling availability check.
func generateEmbedding(for text: String) async -> [Float]? {
    if #available(iOS 16.0, *) {
        return await EmbeddingService.shared.generateEmbedding(for: text)
    } else {
        print("‼️ [Embedding] NLEmbedding requires iOS 16.0 or later.")
        return nil
    }
}

// Global function for JSON conversion, handling availability check.
// This doesn't access shared mutable state, so it doesn't need to be part of the actor.
func embeddingToJson(_ embedding: [Float]) -> String? {
     if #available(iOS 16.0, *) {
         // Use higher precision format specifier if needed, but %.8f is usually sufficient
         let numberStrings = embedding.map { String(format: "%.8f", $0) }
         return "[" + numberStrings.joined(separator: ",") + "]"
     } else {
         print("‼️ [Embedding] Embedding requires iOS 16.0 or later.")
         return nil
     }
}
# Document 12b. OpenAI API Implementation

Below is an **outline** for implementing backend chat functionality with GPT‑4o, saving chat history (in Core Data), and adding a simple chat UI in `ChatView.swift`. The plan reflects **Document 9** (PRD), **Document 10** (Implementation Plan), and **Document 12** (OpenAI API), and follows best practices for scalability and separation of concerns. 

---

## 1. Data & Architecture Overview

1. **Create a New Chat Data Model:**
   - **Core Data Entity**: For example, `ChatMessageEntity` with fields:
     - `id` (UUID, primary key)
     - `content` (String)
     - `role` (String: “user” or “assistant”)
     - `timestamp` (Date)
   - (Optionally) use a “conversationID” or link to a “ChatSessionEntity” if you foresee multiple parallel chats. For now, storing messages in a single table is enough—just keep the design open for multiple sessions later.

2. **Service Layer for GPT‑4o Integration:**
   - **`GPT4ChatService`** (or “OpenAIChatService”) that:
     1. Handles loading the API key (from `.env` or `Config.plist`).
     2. Initializes the OpenAI client (using the Swift Responses API or your chosen approach).
     3. Exposes a function like:
        ```swift
        func sendMessage(userMessage: String) async throws -> String
        ```
        which:
        - Prepares the system prompt (loaded from a separate Swift file).
        - Sends the user message to GPT‑4o with the system prompt as “system” instructions.
        - Returns the assistant’s text response.

3. **ViewModel / Chat Manager:**
   - **`ChatViewModel`** (or “ChatManager”) that orchestrates:
     1. **Core Data** for storing messages (both user and assistant).
     2. **GPT4ChatService** for calling GPT‑4o.
     3. Provides a SwiftUI-friendly interface (e.g. `@Published var messages: [ChatMessageEntity]`) so the UI can react to changes.
   - Typically, the flow is:
     - User enters a message → `sendMessage(userMessage:)` on `ChatViewModel` → 
     - The VM appends a new user message to Core Data → calls the GPT‑4 service → gets the assistant reply → appends the reply to Core Data → UI is automatically updated.

4. **Chat UI in `ChatView.swift`:**
   - A SwiftUI view that:
     - Observes the `ChatViewModel`.
     - Displays messages in a vertical list (e.g. `List` or `ScrollView` with a `VStack`).
     - Shows an **input field** and **send button** at the bottom. 
     - Each message is styled differently based on role (user vs. assistant).
   - All **styling** (bubbles, fonts, background colors) is defined in `UIStyles`, so it’s consistent and easily maintainable.

---

## 2. Implementation Steps

Here is a step-by-step plan incorporating the tasks mentioned in your documents:

### **Step 1: Create or Update Core Data Model**

1. **Add `ChatMessageEntity`**:  
   - Fields: `id (UUID)`, `content (String)`, `role (String)`, `timestamp (Date)`.
2. (Optional) **Migration**: If you already have a persistent store, ensure the new entity is integrated properly.

This covers how we store both the **current chat** and **previous chats** in the database. (We can decide later to filter by conversation if we want multiple sessions.)

### **Step 2: Add the GPT-4o Service**

Following **Document 12** guidelines:

1. **Set up the Swift package** (or direct `URLSession`) to call the GPT‑4o model:
   - E.g. `swift-openai-responses` or your chosen library.  
   - **Load API Key** from `.env` or a secure plist. 
2. Create `GPT4ChatService`:
   - A singleton or `@MainActor` class with:
     ```swift
     final class GPT4ChatService {
         static let shared = GPT4ChatService()
         private let openAIClient: ResponsesAPI
         private init() {
             let apiKey = loadAPIKeySomehow() 
             self.openAIClient = ResponsesAPI(authToken: apiKey)
         }

         func sendMessage(systemPrompt: String, userMessage: String) async throws -> String {
             let request = Request(model: "gpt-4o",
                                   input: .text(userMessage),
                                   instructions: systemPrompt)
             let response = try await openAIClient.create(request)
             return response.outputText ?? ""
         }
     }
     ```
   - The **system prompt** is passed in from outside. This ensures we can switch prompts as needed.

### **Step 3: Store System Prompts in a Separate Swift File**

1. Create `SystemPrompts.swift`, e.g.:
   ```swift
   struct SystemPrompts {
       static let defaultPrompt = """
       You are a helpful assistant in a journaling app ...
       """
       // We can add more prompts or roles here in the future
   }
   ```
2. Reference `SystemPrompts.defaultPrompt` whenever we want the system instructions.

### **Step 4: Build the ChatViewModel**

1. Add properties:
   ```swift
   @MainActor
   final class ChatViewModel: ObservableObject {
       @Published var messages: [ChatMessageEntity] = []

       // Reference to GPT4ChatService
       private let chatService = GPT4ChatService.shared
       private let context = PersistenceController.shared.container.viewContext
       ...
   }
   ```
2. **Fetch existing messages** from Core Data on init:
   ```swift
   init() {
       // e.g. load the existing chat message entities
       let request = NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
       request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
       do {
           messages = try context.fetch(request)
       } catch {
           print("Error fetching messages: \(error)")
       }
   }
   ```
3. Add a function to **send user message**:
   ```swift
   func sendMessage(_ userMessage: String) {
       // 1) Save user message to Core Data
       let userEntry = ChatMessageEntity(context: context)
       userEntry.id = UUID()
       userEntry.content = userMessage
       userEntry.role = "user"
       userEntry.timestamp = Date()
       saveContext()

       // 2) Update messages array
       messages.append(userEntry)

       // 3) Call GPT-4o (async)
       Task {
           do {
               let assistantReply = try await chatService.sendMessage(
                   systemPrompt: SystemPrompts.defaultPrompt,
                   userMessage: userMessage
               )
               // 4) Save assistant message
               let assistantEntry = ChatMessageEntity(context: context)
               assistantEntry.id = UUID()
               assistantEntry.content = assistantReply
               assistantEntry.role = "assistant"
               assistantEntry.timestamp = Date()
               saveContext()

               // 5) Update array
               messages.append(assistantEntry)
           } catch {
               // Handle errors (API offline, etc.)
               print("GPT-4o error: \(error)")
           }
       }
   }

   private func saveContext() {
       do {
           try context.save()
       } catch {
           print("Failed to save context: \(error)")
       }
   }
   ```
4. This pattern keeps the chat history in **Core Data** for both user and assistant. We **won’t** display older sessions yet, but they’re stored.

### **Step 5: Add Chat UI in `ChatView.swift`**

1. **UI Structure**: 
   ```swift
   struct ChatView: View {
       @StateObject private var viewModel = ChatViewModel()
       @State private var currentInput: String = ""

       var body: some View {
           VStack {
               ScrollViewReader { scrollProxy in
                   ScrollView {
                       // Each message
                       ForEach(viewModel.messages, id: \.id) { msg in
                           ChatMessageBubble(message: msg)
                               .id(msg.id)
                       }
                   }
                   .onChange(of: viewModel.messages.count) { _ in
                       // auto-scroll to bottom
                       if let lastId = viewModel.messages.last?.id {
                           scrollProxy.scrollTo(lastId, anchor: .bottom)
                       }
                   }
               }

               HStack {
                   TextField("Type a message...", text: $currentInput)
                       .textFieldStyle(.roundedBorder)
                   Button {
                       let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                       guard !trimmed.isEmpty else { return }
                       viewModel.sendMessage(trimmed)
                       currentInput = ""
                   } label: {
                       Text("Send")
                           .foregroundColor(.white)
                           .padding(.horizontal, 16)
                           .padding(.vertical, 8)
                           .background(UIStyles.chatSendButtonBackground)
                           .cornerRadius(8)
                   }
               }
               .padding()
           }
           .background(UIStyles.chatBackground)  // e.g. define in UIStyles
       }
   }
   ```
   - A `ScrollView` of messages, with a text field + “Send” button at the bottom.
   - We use `ScrollViewReader` to auto-scroll when new messages arrive.

2. **Define Chat Bubbles** in `UIStyles` or separate SwiftUI views. For example, a `ChatMessageBubble` might look like:

   ```swift
   struct ChatMessageBubble: View {
       let message: ChatMessageEntity

       var body: some View {
           HStack {
               if message.role == "assistant" {
                   Spacer() // push bubble to left for user messages or right for assistant
               }
               Text(message.content ?? "")
                   .font(UIStyles.chatFont)
                   .foregroundColor(.white)
                   .padding(12)
                   .background(message.role == "assistant" ? 
                               UIStyles.assistantBubbleColor : 
                               UIStyles.userBubbleColor)
                   .cornerRadius(12)
               if message.role == "user" {
                   Spacer()
               }
           }
           .padding(.horizontal)
           .padding(.vertical, 4)
       }
   }
   ```
   - All colors (`assistantBubbleColor`, `userBubbleColor`, etc.), fonts, corner radius, etc. should be in `UIStyles` for consistency.

3. **UIStyles Additions**:
   ```swift
   struct UIStyles {
       static let chatBackground = Color.black
       static let chatSendButtonBackground = Color.blue
       static let assistantBubbleColor = Color.gray.opacity(0.2)
       static let userBubbleColor = Color.blue.opacity(0.8)
       static let chatFont = Font.system(size: 16)
       // etc.
   }
   ```

### **Step 6: Ensure Separation & Scalability**

1. **One GPT-4o Instance**: Right now, `GPT4ChatService` is a single shared instance. If you need **multiple** in the future, you can add a factory or an initializer that points to different config. But for now, we have a single GPT-4o usage in the app.
2. **System Prompts** in separate file means you can scale up by adding new roles or specialized prompts easily.
3. **Core Data** for indefinite chat history. If you want to separate sessions, you can add a “sessionID” or a separate “ChatSessionEntity”. Because the code is structured in `ChatViewModel`, you can adapt the logic to handle multiple sessions or different channels.

---

## 3. Additional Notes from Documents

- **Document 9 (PRD)**: We’re fulfilling the requirement of hooking up the AI for the chat feature while storing data locally (no forced account). 
- **Document 10 (Implementation Plan)**: 
  - The steps align with “Backend Preparations & Testing” for GPT‑4o. 
  - We create a config file or `.env` for the key, build the service, test it, then integrate the UI in `ChatView`.
- **Document 12 (OpenAI API)**: 
  - We follow best practices: loading the key from `.env` or a config file, using an async call, not blocking the main thread, etc.
  - Optionally, consider streaming if messages may be large. The architecture above still applies; you’d just update the partial assistant response in real-time if you choose streaming.

---

## 4. Final Checklist

1. **Data Model**  
   - [ ] Add `ChatMessageEntity` in Core Data with fields for content, role, timestamp.
   - [ ] Optionally, add “ChatSessionEntity” for multiple sessions.

2. **OpenAI GPT-4o Service**  
   - [ ] Create `GPT4ChatService` that loads key from `.env` or config.  
   - [ ] Provide `sendMessage(systemPrompt:, userMessage:)` method returning GPT-4o’s text.

3. **System Prompts**  
   - [ ] Store in `SystemPrompts.swift` for easy referencing and editing.

4. **ChatViewModel**  
   - [ ] Observes (and fetches from) Core Data.  
   - [ ] On `sendMessage`, saves user message, calls GPT-4o, saves assistant reply.

5. **ChatView.swift**  
   - [ ] Displays messages from `ChatViewModel.messages`.  
   - [ ] Input field + send button.  
   - [ ] Calls `viewModel.sendMessage(_:)`.  
   - [ ] Scroll to bottom on new messages.  
   - [ ] All styles from `UIStyles`.

6. **UIStyles**  
   - [ ] Create color, font, bubble, and layout references for chat UI.  
   - [ ] Keep it consistent with the rest of the app.

7. **Testing**  
   - [ ] Test local logging of chat messages.  
   - [ ] Check GPT-4o integration with real or test API key.  
   - [ ] Ensure the app remains responsive (async calls).  
   - [ ] Validate offline behavior (no crash if we can’t call GPT-4o).

8. **Scalability**  
   - [ ] The single GPT-4o instance can be extended to multiple if needed.  
   - [ ] ChatView can eventually show older conversations in separate screens.  
   - [ ] If chat usage grows, consider a server-side proxy to fully hide API keys.

---

### Summary

By following this outline:
- You get **backend chat functionality** using GPT‑4o (through a centralized `GPT4ChatService`).
- Chat **history** is persisted in Core Data (both user and assistant messages).
- The **system prompts** live in a separate Swift file for easy maintenance.
- `ChatView.swift` has a fully functional text input, send button, and displays conversation messages. 
- **All chat UI** elements—bubbles, fonts, colors—are defined in `UIStyles`, ensuring consistent styling and easy scaling.

This approach cleanly separates concerns—**Service** layer for AI calls, **ViewModel** for app logic and Core Data, **UI** for the SwiftUI layout, and **UIStyles** for visual definitions—making the chat feature maintainable and ready to expand.
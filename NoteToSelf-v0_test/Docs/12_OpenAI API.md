# Document 12. OpenAI API

Research on how to connect to the OpenAI API in a Swift iOS app, specifically using the GPT-4o Responses API in the OpenAI Agents SDK. The report will include a simple, full working example, demonstrating how to load the API key from an `.env` file and make requests to the API efficiently.

# Introduction

OpenAI’s new **Responses API** allows you to interact with GPT-4 models (like **GPT-4o**) in a simpler, more powerful way. It combines the ease of ChatGPT-style conversations with the ability for AI “agents” to use tools and perform multi-step tasks ([OpenAI Launches New API, SDK, and Tools to Develop Custom Agents - InfoQ](https://www.infoq.com/news/2025/03/openai-responses-api-agents-sdk/#:~:text=The%20Responses%20API%20combines%20chat,Assistants%20API%20for%20new%20projects)). In this guide, we’ll walk through connecting to the GPT-4o Responses API from an iOS app using Swift. We’ll cover setting up the OpenAI SDK in Swift, **securely loading your API key from an `.env` file**, best practices for efficient API calls on iOS, and provide example code that you can adapt for your own app. This guide is beginner-friendly with clear explanations and working code snippets.

## Setting Up the OpenAI SDK in a Swift iOS App

To call OpenAI’s API from Swift, you can use an SDK instead of crafting HTTP calls manually. OpenAI’s new Agents SDK is currently officially available for Python, but the community has created Swift packages we can use. In this example, we’ll use an **unofficial Swift SDK for the Responses API** to simplify integration (you could also use `URLSession` directly, but an SDK handles a lot of boilerplate for us).

### Adding the OpenAI Swift Package

We’ll add the Swift package for the OpenAI Responses API to our Xcode project using Swift Package Manager (SPM):

1. **Open Xcode** and go to **File > Add Packages** (or **Swift Packages > Add Package Dependency**).
2. Enter the package URL: `https://github.com/m1guelpf/swift-openai-responses.git` (this is an open-source Swift SDK for the Responses API).
3. When prompted, select the branch *“main”* (since this package is new, it might not have a version tag yet) ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=Swift%20Package%20Manager)).
4. Add the package to your app target.

Once added, import the library in your Swift code: 

```swift
import OpenAI  // module name from the Swift package
```

This package provides a `ResponsesAPI` client class to interact with the API. We’ll use it to send requests.

### Project Configuration and Dependencies

Besides the OpenAI Swift package, ensure your project targets iOS 15 or later so that we can use Swift’s async/await for network calls. No other dependencies are required for basic API usage. The OpenAI package will handle JSON encoding/decoding and networking under the hood. 

**Note:** It’s crucial to keep your API key **out of your source code**. In the next section, we’ll set up loading the key securely from an external file.

## Securely Loading the OpenAI API Key from an `.env` File

Never hard-code your OpenAI API key in your Swift source – this can lead to it being leaked ([Sensitive information in source code - API Key - Swift](https://help.fluidattacks.com/portal/en/kb/articles/criteria-fixes-swift-142#:~:text=In%20this%20Swift%20code%20snippet,class)) ([Sensitive information in source code - API Key - Swift](https://help.fluidattacks.com/portal/en/kb/articles/criteria-fixes-swift-142#:~:text=The%20key%20should%20be%20stored,and%20accessed%20through%20secure%20means)). Instead, store it in a separate configuration (like an `.env` file or a plist) that is not committed to source control. Here are two common approaches for iOS:

- **Use Xcode Environment Variables:** You can load the key from an environment variable at runtime. For development, create a file named `.env` in your project directory with a line like `OPENAI_API_KEY=<your-secret-key>`. Add this file to your *.gitignore* so it isn’t checked in ([GitHub - thebarndog/swift-dotenv: Swift micro-package for loading .env environment files](https://github.com/thebarndog/swift-dotenv#:~:text=IMPORTANT%3A%20Please%20note%20that%20storing,this%20great%20article%20from%20NSHipster)). Then, in Xcode, go to *Product > Scheme > Edit Scheme > Run > Arguments*, and under **Environment Variables** add `OPENAI_API_KEY` with your API key as the value ([ios - How to read environment variable from .env file using Xcode? - Stack Overflow](https://stackoverflow.com/questions/76212234/how-to-read-environment-variable-from-env-file-using-xcode#:~:text=You%20can%20set%20Environment%20Variables,for%20Xcode%20by)). Now, at runtime you can access this with `ProcessInfo.processInfo.environment["OPENAI_API_KEY"]`. This keeps the key out of code and only available when running the app via Xcode (it won’t be included in a release build) ([ios - How to read environment variable from .env file using Xcode? - Stack Overflow](https://stackoverflow.com/questions/76212234/how-to-read-environment-variable-from-env-file-using-xcode#:~:text=But%20this%20won%27t%20affect%20your,the%20app%20via%20to%20Xcode)).

- **Use a Configuration File:** Alternatively, store the key in a plist or a similar config file that you don’t check into Git. For example, create a `Config.plist` with a key for your API token. You can load it in code as follows: 

  ```swift
  func loadAPIKey() -> String? {
      if let filePath = Bundle.main.path(forResource: "Config", ofType: "plist"),
         let plist = NSDictionary(contentsOfFile: filePath) {
          return plist["API_KEY"] as? String
      }
      return nil
  }
  ``` 

  In this snippet, we read an `API_KEY` value from *Config.plist* at runtime ([Sensitive information in source code - API Key - Swift](https://help.fluidattacks.com/portal/en/kb/articles/criteria-fixes-swift-142#:~:text=func%20loadAPIKey%28%29%20,)). Ensure this file is added to your app’s resources and **not** included in source control. (You might keep a template file or use different files for debug vs. release.)

For this guide, we’ll assume you’ve set up one of the above and can retrieve your API key with a helper (e.g. `loadAPIKey()`). Remember, these methods protect your key in the repo, but a determined attacker could still extract a key embedded in the app bundle. **For a truly secure solution, consider storing the key on a server and having your app talk to that server instead of directly to OpenAI** – OpenAI also *“strongly recommends”* routing requests through your own backend to avoid exposing secrets in client apps ([GitHub - MacPaw/OpenAI: Swift community driven package for OpenAI public API](https://github.com/MacPaw/OpenAI#:~:text=,significant%20risk%20to%20expose%20them)).

## Making API Requests to GPT-4o from Swift

With the SDK integrated and the API key loaded, you can now make a request to the GPT-4o model via the Responses API. The process involves creating a client with your API key, building a request (including the model name and your prompt), and then sending that request asynchronously.

### Initializing the OpenAI API Client

First, create an instance of the `ResponsesAPI` client using your API key:

```swift
guard let apiKey = loadAPIKey() else {
    fatalError("Missing OpenAI API key")
}
let openAIClient = ResponsesAPI(authToken: apiKey)
```

Here, `ResponsesAPI` is provided by the Swift SDK and we pass in our secret key to authenticate ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=To%20interact%20with%20the%20Responses,with%20your%20API%20key)). (Optionally, you can also specify an organization or project ID if you have those, but it’s not required for basic usage.)

### Creating a Request to GPT-4o

Next, we prepare a request to send to GPT-4o. In the Responses API, a **Request** object encapsulates the model to use, the user input, and any additional instructions or parameters. For example:

```swift
// Define your prompt and any system instructions
let userMessage = "Ask a question or give a prompt here."
let systemInstructions = "You are a helpful assistant."  // Similar to ChatGPT system role

// Create the request for GPT-4o
let request = Request(
    model: "gpt-4o", 
    input: .text(userMessage),
    instructions: systemInstructions
)
```

In this code, `.text(userMessage)` denotes that our input is plain text. The `instructions` field can be used to give the model context or a persona (like a system prompt). The model name `"gpt-4o"` specifies we want the GPT-4o model. (You can replace it with any model ID supported by OpenAI – GPT-4o is one of the new models introduced with the Responses API.)

### Sending the Request and Handling the Response

Now we can send the request using our `openAIClient`. Network calls should be done asynchronously to avoid blocking the UI. Swift’s `async/await` makes this easy. For example, if we’re calling this from a button tap or `viewDidLoad`, we can do:

```swift
Task {
    do {
        let response = try await openAIClient.create(request)
        // The response is returned as a Response object. Get the text output:
        let answerText = response.outputText  // convenience to get model's text answer
        print("GPT-4o answered: \(answerText)")
    } catch {
        print("OpenAI API error: \(error)")
    }
}
```

The `create(...)` method sends our request to OpenAI and waits for the result ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=To%20create%20a%20new%20response%2C,instance)). The result (`response`) includes the model’s reply, which we can access as `response.outputText` (a convenience provided by the SDK to get the assistant’s text) ([New tools for building agents | OpenAI](https://openai.com/index/new-tools-for-building-agents/#:~:text=To%20start%2C%20the%20Responses%20API,access%20the%20model%E2%80%99s%20text%20output)) ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=To%20create%20a%20new%20response%2C,instance)). In a real app, instead of `print`, you’d update your UI state with `answerText` (make sure to do UI updates on the main thread, although `Task{}` by default runs on the main actor for SwiftUI, simplifying this).

That’s it – you’ve made a call to the GPT-4o model! 🎉 In summary, the flow is: initialize client → build request → `await` the response.

**Full Example Snippet:** Putting it all together, here’s a simplified example (using SwiftUI for context):

```swift
import SwiftUI
import OpenAI

struct ContentView: View {
    @State private var query: String = ""
    @State private var answer: String = ""
    private let openAIClient = ResponsesAPI(authToken: loadAPIKey())

    var body: some View {
        VStack(spacing: 20) {
            TextField("Ask something...", text: $query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Send to GPT-4o") {
                Task {
                    do {
                        let request = Request(model: "gpt-4o", input: .text(query))
                        let response = try await openAIClient.create(request)
                        answer = response.outputText ?? "(No response)"
                    } catch {
                        answer = "Error: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Text(answer)
                .padding()
        }
        .padding()
    }
}
```

In this example, the user’s query is taken from a `TextField`, and on button tap we create a `Request` with the `gpt-4o` model. We then call `openAIClient.create(request)` asynchronously and update the `answer` state with the model’s reply. The UI will automatically display the answer text when it’s set.

## Best Practices for Efficient API Requests in iOS

When integrating OpenAI’s API in an iOS app, keep these best practices in mind:

- **Avoid Blocking the UI:** Always make network calls off the main thread. Using Swift’s `async/await` (or completion handlers) ensures the UI remains responsive while waiting for the API. In SwiftUI, perform the call inside a `Task` or an `async` function (as shown above) so it doesn’t freeze your interface.

- **Reuse the API Client / Session:** Initialize the OpenAI client once (for example, as a singleton or an `@StateObject` in SwiftUI). Reusing it avoids overhead of recreating HTTP sessions repeatedly. The underlying `URLSession` can then efficiently reuse connections for multiple requests.

- **Leverage Streaming for Large Responses:** If you expect long answers, consider using streaming. The OpenAI Responses SDK supports streaming token-by-token so you can update the UI incrementally (for example, show the answer as it’s being written). You can use `openAIClient.stream(request)` and iterate over streaming event ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=))】. This provides a better user experience for lengthy responses.

- **Throttling and Batching:** Be mindful of how often you call the API. If the user is typing or making rapid requests, implement some throttling (e.g., only send a request when a user stops typing for a moment, or on a button press). Avoid flooding the API with requests in quick succession to stay within rate limits.

- **Error Handling and Retries:** Handle errors gracefully. The API might fail due to network issues or rate limits. In the `catch` block, you can update the UI with an error message. For certain errors (like timeouts) you might retry the request after a delay. Always check the error descriptions provided.

- **Secure Your API Key:** **Never ship the app with an exposed API key.** During development, loading from an `.env` or config file is fine, but for production consider moving the OpenAI call to your own server. That way your app communicates with your server (which holds the API key securely), and users can’t extract your key from the ap ([GitHub - MacPaw/OpenAI: Swift community driven package for OpenAI public API](https://github.com/MacPaw/OpenAI#:~:text=,significant%20risk%20to%20expose%20them))】. This also allows you to add logging or request filtering for abuse prevention.

- **Optimize Network Usage:** Use JSON efficiently. The OpenAI Responses API returns quite a bit of data (model outputs, tool usage, etc.). If using your own `URLSession` calls, use `URLSession.shared` or a singleton session with keep-alive. The SDK we used already uses URLSession under the hood, so you get these benefits automatically. Also, enable compression (the API should support gzip) if using custom calls to reduce data usage.

By following these practices, your app will remain responsive and efficient while integrating powerful AI features.

## Conclusion

In this guide, we demonstrated how to connect an iOS app to OpenAI’s GPT-4o via the new Responses API using Swift. We set up a Swift package that simplifies API calls, loaded our secret API key from a safe place outside of code, and made an example request to get a completion from the model. We also discussed best practices, like keeping the UI thread free, reusing connections, streaming results, and protecting your API key. 

With this foundation, you can start building AI-powered features in your app. For example, you might create a chat UI where user messages are sent to GPT-4o and responses are displayed in real-time. Always test with your own API key and handle errors and edge cases (like empty responses or user cancellations). Happy coding!

**Sources:** The OpenAI announcement recommends using the new Responses API for multi-step AI agent ([OpenAI Launches New API, SDK, and Tools to Develop Custom Agents - InfoQ](https://www.infoq.com/news/2025/03/openai-responses-api-agents-sdk/#:~:text=The%20Responses%20API%20combines%20chat,Assistants%20API%20for%20new%20projects))】. We used an unofficial Swift SDK for the Responses API for our exampl ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=To%20create%20a%20new%20response%2C,instance))】. Remember to keep API keys out of source code (using environment files or config ([GitHub - thebarndog/swift-dotenv: Swift micro-package for loading .env environment files](https://github.com/thebarndog/swift-dotenv#:~:text=IMPORTANT%3A%20Please%20note%20that%20storing,this%20great%20article%20from%20NSHipster)) ([Sensitive information in source code - API Key - Swift](https://help.fluidattacks.com/portal/en/kb/articles/criteria-fixes-swift-142#:~:text=func%20loadAPIKey%28%29%20,))】, and never expose them in a released ap ([GitHub - MacPaw/OpenAI: Swift community driven package for OpenAI public API](https://github.com/MacPaw/OpenAI#:~:text=,significant%20risk%20to%20expose%20them))】 for security. The Xcode scheme can load environment variables for development convenienc ([ios - How to read environment variable from .env file using Xcode? - Stack Overflow](https://stackoverflow.com/questions/76212234/how-to-read-environment-variable-from-env-file-using-xcode#:~:text=You%20can%20set%20Environment%20Variables,for%20Xcode%20by))】. The Swift SDK and OpenAI’s tools also support streaming responses for better performanc ([GitHub - m1guelpf/swift-openai-responses: An unofficial Swift SDK for the OpenAI Responses API.](https://github.com/m1guelpf/swift-openai-responses#:~:text=))】. All code in this guide is adaptable and meant to be a starting point for your own iOS+OpenAI projects. Enjoy building with GPT-4o!
# Unum USearch for Offline Semantic Search on iOS (Swift)

## Performance of USearch on iOS

**Memory Usage:** USearch is designed to be highly memory-efficient. It uses the HNSW (Hierarchical Navigable Small World) graph algorithm for approximate nearest neighbor search, but with a compact implementation. By default, vectors are stored in 32-bit floats, but USearch supports **half-precision (16-bit)** and **quarter-precision (8-bit)** storage to cut memory usage in half or even more ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=%2A%20%E2%9C%85%20SIMD,accommodating%204B%2B%20size)). This is ideal for mobile devices where memory is constrained. For example, storing 10,000 embeddings of dimension 384 in 32-bit floats would use ~15 MB; using half-precision would reduce that to ~7.5 MB. USearch also allows **memory-mapping indexes** from disk (using `view` mode) so that large indexes don't have to be fully loaded into RAM ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=%2A%20%E2%9C%85%20SIMD,accommodating%204B%2B%20size)). In practice, the data volumes you described (a few thousand journal and chat embeddings, growing to maybe 5–10K vectors over years) are very small for USearch – the index will consume only tens of megabytes at most, well within an iPhone’s capabilities.

**Search Speed:** USearch is optimized for fast k-NN search using HNSW. It has been benchmarked to outperform FAISS (Facebook’s ANN library) in speed, with claims of **up to 10× faster search** for similar recall and memory usage ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=,bit%20integer)) ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=,precision)). On mobile hardware, this translates to **millisecond-level query times** for thousands of vectors. For example, a real-world demo achieved **real-time searches (≈15 queries per second)** on an iPhone 15 Pro Max against an index of 25,000 image embeddings ([GitHub - ashvardanian/SwiftSemanticSearch: S3 stands for Swift Semantic… | Ash Vardanian](https://www.linkedin.com/posts/ashvardanian_github-ashvardanianswiftsemanticsearch-activity-7190878876099616768-t-Vp#:~:text=Preternatural%20AI%2C%20Inc%20,in%2Fdp6bEpfM)). Even with cosine similarity or inner-product metrics, you can expect querying 5–10K sentence embeddings to feel instantaneous (a few milliseconds per search in practice). USearch’s default parameters favor high recall (accuracy) by exploring more of the graph on each query, but you can tune this for even faster searches if needed. Overall, k-NN search for cosine or inner product distance on the order of 10³–10⁴ vectors is essentially **instantaneous** on modern iPhones.

**Scalability:** The HNSW index in USearch scales sub-linearly with the number of vectors, so adding more entries has a modest impact on search speed. In fact, USearch has been shown to handle extremely large indexes on-device – on the order of **tens of millions of vectors** – by using quantization and disk mapping strategies ([GitHub - ashvardanian/SwiftSemanticSearch: Real-time on-device text-to-image and image-to-image Semantic Search with video stream camera capture using USearch & UForm AI Swift SDKs for Apple devices ](https://github.com/ashvardanian/SwiftSemanticSearch#:~:text=This%20Swift%20demo%20app%20shows,entries%20on%20an%20iPhone%20easily)). (One demo reports scaling to *100 million+* vectors on an iPhone by memory-mapping the index ([GitHub - ashvardanian/SwiftSemanticSearch: Real-time on-device text-to-image and image-to-image Semantic Search with video stream camera capture using USearch & UForm AI Swift SDKs for Apple devices ](https://github.com/ashvardanian/SwiftSemanticSearch#:~:text=This%20Swift%20demo%20app%20shows,entries%20on%20an%20iPhone%20easily)).) While an index that large would be unusual in a mobile app, this demonstrates that your target of a few thousand or even tens of thousands of embeddings is easily within USearch’s capabilities. In summary, you can expect **minimal memory impact and sub-10ms query speeds** for the described data volumes, with plenty of headroom as the journal and message archives grow.

## Integrating USearch into a Swift iOS App

USearch provides a Swift SDK that you can integrate via Swift Package Manager. Below are step-by-step instructions to set up USearch and use it to store and search embeddings, entirely offline within your iOS app.

### Installation with Swift Package Manager

1. **Add the USearch package** to your project. In Xcode, go to **File ▸ Add Packages** and enter the GitHub URL for USearch: `https://github.com/unum-cloud/usearch`. Alternatively, update your `Package.swift` manifest:

```swift
dependencies: [
    .package(url: "https://github.com/unum-cloud/usearch", .upToNextMajor(from: "2.0.0"))
]
```

This will fetch the USearch Swift SDK (the library supports iOS, with no additional dependencies). Once added, import the module in your Swift code:

```swift
import USearch
```

### Initializing a USearch Index

To use USearch, first create an index configured for your vector size and similarity metric. USearch supports cosine similarity (`.Cos`) and inner-product (`.IP`) metrics (among others like Euclidean). You also specify the vector dimensionality and can adjust parameters like graph connectivity (M):

```swift
// For example, using cosine similarity on 384-dimensional embeddings
let index = USearchIndex.make(metric: .Cos, dimensions: 384, connectivity: 16, quantization: .F32)
```

In this call: 

- `metric: .Cos` chooses cosine similarity (appropriate for normalized embeddings). Use `.IP` for inner product if you prefer (for unnormalized vectors or if using dot-product directly).
- `dimensions: 384` sets the expected length of your embedding vectors.
- `connectivity: 16` sets HNSW graph connectivity (higher means more memory and slower adds, but potentially better recall; 16 is a reasonable default ([Benchmarks - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/benchmarks.html#:~:text=The%20default%20values%20vary%20drastically)) ([Benchmarks - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/benchmarks.html#:~:text=))).
- `quantization: .F32` specifies 32-bit float storage. You can use `.F16` (half precision) or `.I8` (int8) to save memory. (Note: Int8 quantization is only valid for cosine-like metrics, since it internally normalizes vectors ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=In%20most%20cases%2C%20it%27s%20recommended,than%20zero%20are%20set%20to)).)

**Memory Reservation (Optional):** If you know roughly how many vectors you will store, pre-allocate to optimize memory usage. For example, if you expect ~10,000 total entries:

```swift
index.reserve(10000)
```

This is not required but can improve insertion performance by reducing reallocations.

### Adding Embedding Vectors

You can now add your embedding vectors (as Swift arrays) to the index. Each vector is stored with a **unique key** (an integer identifier). In a journal app, you might use an auto-incrementing ID or a hash of the entry. For example:

```swift
let entryVector: [Float32] = ...  // your 384-dim embedding for a journal entry
let entryID: UInt32 = 1001       // some unique ID for this entry
try index.add(key: entryID, vector: entryVector)
```

Here, `index.add` inserts the vector. This operation may throw an error (for example, if the vector length is wrong), so we call it with `try`. In practice, you'd wrap calls in `do-catch` for error handling. You can add vectors one by one as new data comes in (USearch supports incremental additions). For instance, adding new chat message embeddings daily:

```swift
for message in newMessages {
    let msgVector = embed(message.text)      // assume embed() produces a [Float32] vector
    let msgID = generateUniqueID(for: message)
    try index.add(key: msgID, vector: msgVector)
}
```

USearch also allows **removing** vectors by key or renaming keys if needed (e.g., `index.remove(key: oldID)` or `index.rename(from: oldID, to: newID)`), and you can check `index.count` or `index.isEmpty` to inspect index stats ([Swift SDK - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/swift/#:~:text=%2F%2F%20Retrieve%20structural%20properties%20of,expansionSearch)) ([Swift SDK - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/swift/#:~:text=%2F%2F%20Remove%20a%20vector%20by,remove%28key%3A%2042)).

### Performing Nearest Neighbor Searches

To query the index for the nearest neighbors of a given embedding (for example, finding similar journal entries or relevant past messages), use the `search` method:

```swift
let queryVector: [Float32] = ...        // e.g., embedding of the current note or query text
let k = 5                               // number of nearest neighbors to retrieve
let (neighbors, distances) = try index.search(vector: queryVector, count: k)
```

The result of `index.search` is a tuple: an array of neighbor keys and a parallel array of distance scores. For cosine or inner-product, a **lower distance** means a closer match (note: USearch returns actual distances for `.Cos` metric, not cosine similarity values). In the example above, `neighbors[0]` would be the key of the closest match, and `distances[0]` its distance. You can then look up the actual entry (e.g., journal text) by that key in your database. If you also want to retrieve the stored vector, you can call `index.get(key)` which returns the vector (or `nil` if not found).

**Example:** Searching for similar entries to a new journal entry:

```swift
let (neighborIDs, dists) = try index.search(vector: newEntryVector, count: 5)
for (i, neighborID) in neighborIDs.enumerated() {
    print("Neighbor \(i): ID=\(neighborID), distance=\(dists[i])")
}
```

This will give you the 5 most semantically similar entries in your archive to the new entry.

### Persisting and Reloading the Index

For an offline-first app, you will want to save the index to disk so that the user’s data can be persisted between sessions without needing to recompute all embeddings or re-index on each launch. USearch provides simple serialization methods:

- `index.save(path)` – saves the index to a file.
- `index.load(path)` – loads a previously saved index file into the current index (overwriting its contents).
- `index.view(path)` – *memory-maps* an index file for use without fully loading it into RAM (useful for very large indexes).

In Swift, these calls are `throws`, so use try/catch. For example, to save the index when the app goes into the background:

```swift
let fileURL = getDocumentsDirectory().appendingPathComponent("journal_index.usearch")
do {
    try index.save(fileURL.path)
} catch {
    print("Failed to save index: \(error)")
}
```

And to load it on app launch:

```swift
let fileURL = getDocumentsDirectory().appendingPathComponent("journal_index.usearch")
if FileManager.default.fileExists(atPath: fileURL.path) {
    do {
        try index.load(fileURL.path)
    } catch {
        print("Failed to load index, will rebuild: \(error)")
    }
} else {
    // No saved index, will build fresh or add entries as needed
}
```

Here, `getDocumentsDirectory()` is a helper to get your app’s Documents directory URL. The `.usearch` extension is arbitrary (USearch can use any file path). After loading, the index is ready for use. If the index file is very large, consider using `index.view` instead of `load` to avoid high memory usage – this leaves the index on disk and brings data into memory on-the-fly ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=%2A%20%E2%9C%85%20SIMD,accommodating%204B%2B%20size)).

*Note:* The index file contains the vectors and the HNSW graph structure. Ensure you also persist your raw embeddings or have a way to re-compute them if needed, especially if using quantization (because when using int8 quantization, `index.get()` cannot recover the original high-precision vector ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=In%20most%20cases%2C%20it%27s%20recommended,than%20zero%20are%20set%20to))).

## Best Practices for Using USearch on iOS

Using USearch in a mobile environment benefits from a few additional considerations to maximize performance and efficiency:

- **Optimize Precision vs Memory:** Use the lowest precision that doesn’t hurt your search quality. USearch can downcast on-the-fly – modern iPhones have fast half-precision support, so using `.F16` is generally recommended for embedding vectors ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=In%20most%20cases%2C%20it%27s%20recommended,than%20zero%20are%20set%20to)). This cuts memory use by 50% with negligible impact on accuracy for semantic embeddings. Quarter-precision (`.I8`) is an option for cosine similarity indexes if you need even smaller memory footprint, but keep in mind int8 quantization normalizes vectors and you won’t get the exact originals back from the index ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=In%20most%20cases%2C%20it%27s%20recommended,than%20zero%20are%20set%20to)). Always measure the recall/quality trade-off; for most sentence embeddings, half-precision maintains virtually identical k-NN results.

- **Dimensionality Reduction:** If your embeddings are high-dimensional (e.g. 768 from a Transformer model) and you find performance lagging (especially on older devices), you might consider reducing dimensionality (using PCA or using a smaller embedding model). USearch itself doesn’t require this and handles 768-d vectors fine, but fewer dimensions mean faster distance computations and less memory per vector. Many mobile use-cases work well with 256-d or 384-d embeddings, for instance.

- **Index Parameters Tuning:** USearch’s HNSW index has parameters you can tune:
  - *Connectivity* (`M`): Default is 16. Lowering it (e.g., 8) will reduce memory usage slightly (fewer links per node) at the cost of some accuracy/recall. For a few thousand vectors, you might not need to change this; the default 16 is usually fine, ensuring high recall.
  - *Expansion (efSearch and efAdd)*: These control the breadth of search. USearch’s defaults (efSearch ~64, efAdd ~128 by default ([Benchmarks - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/benchmarks.html#:~:text=The%20default%20values%20vary%20drastically)) ([Benchmarks - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/benchmarks.html#:~:text=))) are geared for high recall. If you find searches are extremely fast and you can afford a slight slowdown for better accuracy, you can increase `index.expansionSearch`. Conversely, if you want to trade a bit of recall for even faster queries, you could reduce it. In practice, for the scale of ~10k vectors, you’ll likely get nearly 100% recall even with much lower settings, so the defaults work well out-of-the-box.

- **Updating vs. Rebuilding the Index:** USearch supports dynamic updates – you can keep calling `index.add()` as new data arrives, and even remove old entries. Unlike some older ANN libraries, there's no need to rebuild the entire index from scratch for a few new vectors. The graph will incrementally incorporate them. For the trickle of daily entries in your app, simply adding to the existing index is efficient and maintains good performance. If you ever perform massive bulk inserts (e.g., tens of thousands at once), you might consider building a fresh index offline and swapping it in, but for the described usage, incremental adds are fine. (If you do remove a lot of entries over time, and the index grows fragmented, a rebuild might reclaim some memory – but deletion in USearch is supported natively, so it should handle this well.)

- **Parallelism and Background Processing:** USearch’s core is thread-safe and even supports concurrent adds/searches internally (the data structure permits concurrent updates). However, from a Swift app perspective, you should still manage threading to avoid blocking the UI. Perform bulk index construction or large queries on a background thread (e.g., using Grand Central Dispatch). For example, you can batch-add a day’s worth of embeddings on a background queue. Searching a few thousand vectors is so fast that doing it on the main thread is usually okay, but if you plan to run many searches or more expensive operations, keep them off the main UI thread to maintain smooth performance. You can also use operations like `DispatchQueue.concurrentPerform` if you want to parallelize many independent searches. Given that USearch can execute thousands of queries per second on a single core ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=,bit%20integer)), a single background thread will usually suffice.

- **Batching Tips:** If you have a large number of vectors to insert at once (say on first launch or after a long offline period), consider batching them. While you could call `index.add()` in a tight loop, you might gain speed by grouping operations. One approach is to prepare your embeddings then call add in sequence (USearch will internally vectorize some operations, especially if you compiled with optimizations). Remember to call `reserve()` beforehand as mentioned, to allocate memory for the batch. There isn’t a special batch-add function in the Swift API (each `add` is one vector), but you could utilize concurrency (multiple threads adding different vectors) to speed up a huge initial load if needed. Just ensure each key is unique.

- **Persistence Strategy:** Because your app is offline-first, make sure to save the index periodically (e.g., after significant new data additions or when the app is backgrounded). Using the `index.save()` and `index.load()` as described will let the user pick up where they left off without re-indexing. For very large indexes, use `index.view()` to avoid RAM spikes on load ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=%2A%20%E2%9C%85%20SIMD,accommodating%204B%2B%20size)). The index file can be a few MBs for thousands of vectors, which is fine to store in the app’s documents. Include this file in your backups if the data is important to the user.

- **SwiftUI Integration:** If you use SwiftUI, note that creating or modifying the index in SwiftUI views should be done carefully. The USearch API might return values you don’t use (e.g., the result of `index.add` which is void). To avoid SwiftUI’s state update pitfalls and warning about unused results, you can explicitly assign unused returns to `_` as shown in the USearch docs ([Swift SDK - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/swift/#:~:text=let%20index%20%3D%20USearchIndex,add%28key%3A%2043%2C%20vector%3A%20vectorB)). For example: `let _ = index.add(key: 123, vector: vec)` to ignore the return. It’s also wise to manage the index in a view model or `ObservableObject` rather than directly in the view.

## Licensing and App Store Considerations

USearch is open-source under the **Apache 2.0 license** ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=License)). This is a permissive license that allows you to use, modify, and distribute USearch in your iOS application (even commercially) without any licensing fees. You can include USearch in an App Store app with no issue. Apache 2.0 does require that you give proper attribution and include the license text in your app’s documentation or "Open Source Licenses" section, but it **does not require you to open-source your own code**. In short, you can safely use USearch in a closed-source commercial iOS app. Just be sure to retain the license file and any copyright notices from the USearch project in your app’s acknowledgements.

Finally, because USearch is offline and runs entirely on-device, it aligns perfectly with the privacy and data requirements of an offline-first app – **no data leaves the device** during searches ([GitHub - ashvardanian/SwiftSemanticSearch: S3 stands for Swift Semantic… | Ash Vardanian](https://www.linkedin.com/posts/ashvardanian_github-ashvardanianswiftsemanticsearch-activity-7190878876099616768-t-Vp#:~:text=latency%20of%20these%20,clips%20should%20be%20easy%2C%20but)). You get state-of-the-art vector search performance without needing any network service, which means you can deliver fast semantic search in your journal app even with no internet connection, and the user's data remains private.

**Sources:**

- Unum USearch GitHub – *Project README and Documentation* ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=,precision)) ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=%2A%20%E2%9C%85%20SIMD,accommodating%204B%2B%20size)) ([GitHub - unum-cloud/usearch: Fast Open-Source Search & Clustering engine × for Vectors &  Strings × in C++, C, Python, JavaScript, Rust, Java, Objective-C, Swift, C#, GoLang, and Wolfram ](https://github.com/unum-cloud/usearch#:~:text=,bit%20integer))  
- Unum USearch Swift SDK Documentation – *Usage examples and API reference* ([Swift SDK - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/swift/#:~:text=let%20index%20%3D%20USearchIndex,add%28key%3A%2043%2C%20vector%3A%20vectorB)) ([Swift SDK - Unum · USearch 2.17.1 documentation](https://unum-cloud.github.io/usearch/swift/#:~:text=Save%20and%20load%20your%20indices,for%20efficient%20reuse))  
- Ash Vardanian, *USearch & UForm on Mobile* – Real-world demo of USearch on iPhone (LinkedIn post) ([GitHub - ashvardanian/SwiftSemanticSearch: S3 stands for Swift Semantic… | Ash Vardanian](https://www.linkedin.com/posts/ashvardanian_github-ashvardanianswiftsemanticsearch-activity-7190878876099616768-t-Vp#:~:text=Preternatural%20AI%2C%20Inc%20,in%2Fdp6bEpfM))  
- *SwiftSemanticSearch* Demo (Ash Vardanian) – USearch scaling and iOS example ([GitHub - ashvardanian/SwiftSemanticSearch: Real-time on-device text-to-image and image-to-image Semantic Search with video stream camera capture using USearch & UForm AI Swift SDKs for Apple devices ](https://github.com/ashvardanian/SwiftSemanticSearch#:~:text=This%20Swift%20demo%20app%20shows,entries%20on%20an%20iPhone%20easily))  
- Apache 2.0 License for USearch
import XCTest
import Leaf
import LeafKit
import XCTVapor

/*
 to profile memory growth, use an sh script like this:
 ```bash
 #!/bin/zsh
 swift test --filter LeafMemoryGrowthTests &
 sleep 5
 PID=$(ps aux | grep '[l]eafPackageTests' | awk '{print $2}' | head -n1)
 echo "leafPackageTests PID: $PID"
 leaks $PID
 ```
*/
final class LeafMemoryGrowthTests: XCTestCase {
//    func testRepeatedRenderMemoryGrowth() async throws {
//        sleep(3) // Keep process alive for leaks profiling
//        var test = TestFiles()
//        test.files["/foo.leaf"] = "Hello #(name)!"
//        
//        try await withApp { app in
//            app.views.use(.leaf)
//            app.leaf.sources = .singleSource(test)
//            struct Foo: Encodable { var name: String }
//            // Render with context 1000 times
//            for _ in 0..<1000 {
//                _ = try await app.leaf.renderer.render(path: "foo", context: Foo(name: "World")).get()
//            }
//        }
//        sleep(10) // Keep process alive for leaks profiling
//    }
//    
//    func testRepeatedRenderNoContextMemoryGrowth() async throws {
//        sleep(3) // Keep process alive for leaks profiling
//        var test = TestFiles()
//        test.files["/foo.leaf"] = "Hello!"
//        
//        try await withApp { app in
//            app.views.use(.leaf)
//            app.leaf.sources = .singleSource(test)
//            // Render without context 1000 times (pass nil context)
//            for _ in 0..<1000 {
//                _ = try await app.leaf.renderer.render(path: "foo", context: Optional<Bool>.none).get()
//            }
//        }
//        sleep(10) // Keep process alive for leaks profiling
//    }
}

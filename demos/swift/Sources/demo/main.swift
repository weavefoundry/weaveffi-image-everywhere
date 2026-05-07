// Swift demo for weaveffi-image.
//
// Calls the WeaveFFI C ABI directly via the CWeaveFFI system module
// (which re-exports sdk/c/weaveffi.h). The generated Swift SDK lives
// at sdk/swift/ but currently imports the wrong C module name; once
// that lands in WeaveFFI mainline, this demo can switch to
// `import WeaveImage` and call `Image.process(...)` instead.
import CWeaveFFI
import CryptoKit
import Foundation

func die(_ msg: String) -> Never {
    FileHandle.standardError.write(Data("swift:  \(msg)\n".utf8))
    exit(1)
}

func check(_ err: inout weaveffi_error, _ what: String) {
    if err.code != 0 {
        let msg = err.message.flatMap { String(cString: $0) } ?? ""
        weaveffi_error_clear(&err)
        die("\(what): \(msg) (code \(err.code))")
    }
}

// Avoid argv[0]-relative paths: with `swift run`, the executable lives
// in .build/<arch>/debug/, not in demos/swift/. Always derive paths
// from WEAVEFFI_ROOT (set by run.sh).
let root = URL(fileURLWithPath: ProcessInfo.processInfo.environment["WEAVEFFI_ROOT"]
    ?? FileManager.default.currentDirectoryPath)
let here = root.appendingPathComponent("demos/swift")

let inputURL = root.appendingPathComponent("assets/input.jpg")
let input = try Data(contentsOf: inputURL)

var err = weaveffi_error(code: 0, message: nil)

let probe = input.withUnsafeBytes { buf -> OpaquePointer? in
    weaveffi_image_probe(
        buf.bindMemory(to: UInt8.self).baseAddress,
        buf.count,
        &err
    )
}
check(&err, "probe")
guard let info = probe else { die("probe: null") }
let width = weaveffi_image_ImageInfo_get_width(info)
let height = weaveffi_image_ImageInfo_get_height(info)
FileHandle.standardError.write(Data("swift:  input  \(width)x\(height)\n".utf8))
weaveffi_image_ImageInfo_destroy(info)

guard
    let resize = weaveffi_image_resize(512, 512, &err)
else { die("resize: null"); }
check(&err, "resize")
guard
    let blur = weaveffi_image_blur(2.0, &err)
else { die("blur: null"); }
check(&err, "blur")
guard
    let gray = weaveffi_image_grayscale(&err)
else { die("grayscale: null"); }
check(&err, "grayscale")
defer {
    weaveffi_image_Operation_destroy(resize)
    weaveffi_image_Operation_destroy(blur)
    weaveffi_image_Operation_destroy(gray)
}

var ops: [OpaquePointer?] = [resize, blur, gray]
var outLen: size_t = 0

let outBytes: Data = input.withUnsafeBytes { inputBuf -> Data in
    ops.withUnsafeMutableBufferPointer { opsBuf -> Data in
        let outPtr = weaveffi_image_process(
            inputBuf.bindMemory(to: UInt8.self).baseAddress,
            inputBuf.count,
            opsBuf.baseAddress,
            opsBuf.count,
            weaveffi_image_ImageFormat_Png,
            &outLen,
            &err
        )
        if err.code != 0 || outPtr == nil {
            return Data()
        }
        let copy = Data(bytes: outPtr!, count: outLen)
        weaveffi_free_bytes(UnsafeMutablePointer(mutating: outPtr!), outLen)
        return copy
    }
}
check(&err, "process")
if outBytes.isEmpty { die("process: empty result") }

let outURL = here.appendingPathComponent("output.png")
try outBytes.write(to: outURL)

let digest = SHA256.hash(data: outBytes)
let hex = digest.map { String(format: "%02x", $0) }.joined()
print("swift \(hex)")
FileHandle.standardError.write(Data("swift:  wrote  demos/swift/output.png (\(outBytes.count) bytes)\n".utf8))

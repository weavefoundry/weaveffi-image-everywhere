// Kotlin demo for weaveffi-image.
//
// Calls the WeaveFFI C ABI from the JVM via JNA. The generated SDK at
// sdk/android/ targets Android via JNI (which requires building a JNI
// shim with the NDK); JNA gives us a single-file demo that runs on any
// JVM. The byte-identical SHA proves the C ABI is what matters.
import com.sun.jna.Library
import com.sun.jna.Memory
import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.PointerType
import com.sun.jna.Structure
import com.sun.jna.ptr.IntByReference
import java.io.File
import java.security.MessageDigest

@Structure.FieldOrder("code", "message")
class WeaveError : Structure() {
    @JvmField var code: Int = 0
    @JvmField var message: Pointer? = null
}

interface WeaveFFI : Library {
    fun weaveffi_error_clear(err: WeaveError)
    fun weaveffi_free_bytes(ptr: Pointer, len: Long)

    fun weaveffi_image_resize(w: Int, h: Int, err: WeaveError): Pointer?
    fun weaveffi_image_blur(sigma: Double, err: WeaveError): Pointer?
    fun weaveffi_image_grayscale(err: WeaveError): Pointer?
    fun weaveffi_image_Operation_destroy(p: Pointer)

    fun weaveffi_image_probe(input: Pointer, inputLen: Long, err: WeaveError): Pointer?
    fun weaveffi_image_ImageInfo_get_width(p: Pointer): Int
    fun weaveffi_image_ImageInfo_get_height(p: Pointer): Int
    fun weaveffi_image_ImageInfo_destroy(p: Pointer)

    fun weaveffi_image_process(
        input: Pointer, inputLen: Long,
        ops: Pointer, opsLen: Long,
        format: Int,
        outLen: com.sun.jna.ptr.LongByReference,
        err: WeaveError,
    ): Pointer?

    companion object {
        val INSTANCE: WeaveFFI = run {
            // Resolve the absolute lib path once. JNA's library search
            // paths don't include macOS DYLD env vars when SIP is on, so
            // we point JNA at the cargo target dir explicitly.
            val libPath = System.getenv("WEAVEFFI_LIB")
                ?: error("set WEAVEFFI_LIB to the absolute path of libweaveffi.dylib")
            System.setProperty("jna.library.path", File(libPath).parent)
            Native.load("weaveffi", WeaveFFI::class.java) as WeaveFFI
        }
    }
}

fun check(err: WeaveError, what: String) {
    if (err.code != 0) {
        val msg = err.message?.getString(0) ?: "?"
        WeaveFFI.INSTANCE.weaveffi_error_clear(err)
        error("$what: $msg (code ${err.code})")
    }
}

fun main() {
    val ffi = WeaveFFI.INSTANCE
    val root = System.getenv("WEAVEFFI_ROOT") ?: "."

    val input = File("$root/assets/input.jpg").readBytes()
    val inputBuf = Memory(input.size.toLong())
    inputBuf.write(0, input, 0, input.size)
    val err = WeaveError()

    val info = ffi.weaveffi_image_probe(inputBuf, input.size.toLong(), err)!!
    check(err, "probe")
    System.err.println("kotlin: input  ${ffi.weaveffi_image_ImageInfo_get_width(info)}x${ffi.weaveffi_image_ImageInfo_get_height(info)}")
    ffi.weaveffi_image_ImageInfo_destroy(info)

    val resize = ffi.weaveffi_image_resize(512, 512, err)!!; check(err, "resize")
    val blur   = ffi.weaveffi_image_blur(2.0, err)!!;        check(err, "blur")
    val gray   = ffi.weaveffi_image_grayscale(err)!!;        check(err, "grayscale")

    val ops = Memory(8L * 3)
    ops.setPointer(0, resize)
    ops.setPointer(8, blur)
    ops.setPointer(16, gray)

    val outLen = com.sun.jna.ptr.LongByReference()
    val outPtr = ffi.weaveffi_image_process(
        inputBuf, input.size.toLong(),
        ops, 3,
        0,
        outLen, err,
    )!!
    check(err, "process")
    val outBytes = outPtr.getByteArray(0, outLen.value.toInt())
    ffi.weaveffi_free_bytes(outPtr, outLen.value)
    ffi.weaveffi_image_Operation_destroy(resize)
    ffi.weaveffi_image_Operation_destroy(blur)
    ffi.weaveffi_image_Operation_destroy(gray)

    File("$root/demos/kotlin/output.png").writeBytes(outBytes)
    val digest = MessageDigest.getInstance("SHA-256").digest(outBytes)
    val hex = digest.joinToString("") { "%02x".format(it) }
    println("kotlin $hex")
    System.err.println("kotlin: wrote  demos/kotlin/output.png (${outBytes.size} bytes)")
}

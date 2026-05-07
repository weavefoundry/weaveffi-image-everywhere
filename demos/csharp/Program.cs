// .NET demo for weaveffi-image.
//
// Direct P/Invoke against the WeaveFFI C ABI. The generated SDK at
// sdk/dotnet/ has a known issue in the Process() helper in WeaveFFI
// 0.4.0 (Operation[] vs IntPtr+len mismatch); this demo bypasses the
// SDK and calls the C ABI directly, demonstrating the same canonical
// pipeline still produces the byte-identical SHA.
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

namespace WeaveFFIImageDemo;

[StructLayout(LayoutKind.Sequential)]
struct WeaveError {
    public int Code;
    public IntPtr Message;
}

static class Native {
    const string Lib = "weaveffi";

    [DllImport(Lib)] public static extern void weaveffi_error_clear(ref WeaveError err);
    [DllImport(Lib)] public static extern void weaveffi_free_bytes(IntPtr ptr, UIntPtr len);

    [DllImport(Lib)] public static extern IntPtr weaveffi_image_resize(uint w, uint h, ref WeaveError err);
    [DllImport(Lib)] public static extern IntPtr weaveffi_image_blur(double sigma, ref WeaveError err);
    [DllImport(Lib)] public static extern IntPtr weaveffi_image_grayscale(ref WeaveError err);
    [DllImport(Lib)] public static extern void weaveffi_image_Operation_destroy(IntPtr ptr);

    [DllImport(Lib)] public static extern IntPtr weaveffi_image_probe(IntPtr input, UIntPtr inputLen, ref WeaveError err);
    [DllImport(Lib)] public static extern uint weaveffi_image_ImageInfo_get_width(IntPtr ptr);
    [DllImport(Lib)] public static extern uint weaveffi_image_ImageInfo_get_height(IntPtr ptr);
    [DllImport(Lib)] public static extern void weaveffi_image_ImageInfo_destroy(IntPtr ptr);

    [DllImport(Lib)] public static extern IntPtr weaveffi_image_process(
        IntPtr input, UIntPtr inputLen,
        IntPtr ops, UIntPtr opsLen,
        int format, out UIntPtr outLen,
        ref WeaveError err);
}

class Program {
    static void Check(ref WeaveError err, string what) {
        if (err.Code != 0) {
            var msg = Marshal.PtrToStringUTF8(err.Message) ?? "?";
            Native.weaveffi_error_clear(ref err);
            throw new Exception($"{what}: {msg} (code {err.Code})");
        }
    }

    static int Main() {
        var root = Environment.GetEnvironmentVariable("WEAVEFFI_ROOT") ?? ".";
        var input = File.ReadAllBytes(Path.Combine(root, "assets/input.jpg"));
        var inputHandle = GCHandle.Alloc(input, GCHandleType.Pinned);
        try {
            var err = new WeaveError();

            var info = Native.weaveffi_image_probe(
                inputHandle.AddrOfPinnedObject(), (UIntPtr)input.Length, ref err);
            Check(ref err, "probe");
            Console.Error.WriteLine($"csharp: input  {Native.weaveffi_image_ImageInfo_get_width(info)}x{Native.weaveffi_image_ImageInfo_get_height(info)}");
            Native.weaveffi_image_ImageInfo_destroy(info);

            var resize = Native.weaveffi_image_resize(512, 512, ref err); Check(ref err, "resize");
            var blur   = Native.weaveffi_image_blur(2.0, ref err);        Check(ref err, "blur");
            var gray   = Native.weaveffi_image_grayscale(ref err);        Check(ref err, "grayscale");

            var ops = new IntPtr[] { resize, blur, gray };
            var opsHandle = GCHandle.Alloc(ops, GCHandleType.Pinned);
            try {
                var outPtr = Native.weaveffi_image_process(
                    inputHandle.AddrOfPinnedObject(), (UIntPtr)input.Length,
                    opsHandle.AddrOfPinnedObject(), (UIntPtr)ops.Length,
                    0,
                    out var outLen, ref err);
                Check(ref err, "process");

                var bytes = new byte[(int)outLen];
                Marshal.Copy(outPtr, bytes, 0, (int)outLen);
                Native.weaveffi_free_bytes(outPtr, outLen);
                Native.weaveffi_image_Operation_destroy(resize);
                Native.weaveffi_image_Operation_destroy(blur);
                Native.weaveffi_image_Operation_destroy(gray);

                File.WriteAllBytes(Path.Combine(root, "demos/csharp/output.png"), bytes);
                using var sha = SHA256.Create();
                var hex = Convert.ToHexString(sha.ComputeHash(bytes)).ToLowerInvariant();
                Console.WriteLine($"csharp {hex}");
                Console.Error.WriteLine($"csharp: wrote  demos/csharp/output.png ({bytes.Length} bytes)");
            } finally {
                opsHandle.Free();
            }
        } finally {
            inputHandle.Free();
        }
        return 0;
    }
}

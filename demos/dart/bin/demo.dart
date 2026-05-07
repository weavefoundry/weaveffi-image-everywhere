// Dart demo for weaveffi-image.
//
// Hand-rolled FFI binding to the WeaveFFI C ABI. The generated Dart
// SDK at sdk/dart has known issues in WeaveFFI 0.4.0 (process/probe
// signatures and optional struct getters); once those are fixed, this
// demo can switch to `import 'package:weave_image/weaveffi.dart'`.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';

final class WeaveError extends Struct {
  @Int32()
  external int code;
  external Pointer<Utf8> message;
}

typedef _ResizeNative = Pointer<Void> Function(
    Uint32, Uint32, Pointer<WeaveError>);
typedef _ResizeDart = Pointer<Void> Function(int, int, Pointer<WeaveError>);

typedef _BlurNative = Pointer<Void> Function(Double, Pointer<WeaveError>);
typedef _BlurDart = Pointer<Void> Function(double, Pointer<WeaveError>);

typedef _GrayNative = Pointer<Void> Function(Pointer<WeaveError>);
typedef _GrayDart = Pointer<Void> Function(Pointer<WeaveError>);

typedef _OpDestroyNative = Void Function(Pointer<Void>);
typedef _OpDestroyDart = void Function(Pointer<Void>);

typedef _ProbeNative = Pointer<Void> Function(
    Pointer<Uint8>, IntPtr, Pointer<WeaveError>);
typedef _ProbeDart = Pointer<Void> Function(
    Pointer<Uint8>, int, Pointer<WeaveError>);

typedef _InfoGetWidthNative = Uint32 Function(Pointer<Void>);
typedef _InfoGetWidthDart = int Function(Pointer<Void>);
typedef _InfoDestroyNative = Void Function(Pointer<Void>);
typedef _InfoDestroyDart = void Function(Pointer<Void>);

typedef _ProcessNative = Pointer<Uint8> Function(
    Pointer<Uint8>,
    IntPtr,
    Pointer<Pointer<Void>>,
    IntPtr,
    Int32,
    Pointer<IntPtr>,
    Pointer<WeaveError>);
typedef _ProcessDart = Pointer<Uint8> Function(
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Void>>,
    int,
    int,
    Pointer<IntPtr>,
    Pointer<WeaveError>);

typedef _FreeBytesNative = Void Function(Pointer<Uint8>, IntPtr);
typedef _FreeBytesDart = void Function(Pointer<Uint8>, int);

typedef _ErrClearNative = Void Function(Pointer<WeaveError>);
typedef _ErrClearDart = void Function(Pointer<WeaveError>);

DynamicLibrary _open() {
  final libName = Platform.isMacOS
      ? 'libweaveffi.dylib'
      : Platform.isWindows
          ? 'weaveffi.dll'
          : 'libweaveffi.so';
  final envPath = Platform.environment['WEAVEFFI_LIB'];
  if (envPath != null && envPath.isNotEmpty) {
    return DynamicLibrary.open(envPath);
  }
  // Fall back to cargo metadata for a deterministic absolute path.
  final root = Platform.environment['WEAVEFFI_ROOT'] ?? Directory.current.path;
  final result = Process.runSync(
    'cargo',
    ['metadata', '--no-deps', '--format-version=1'],
    workingDirectory: root,
  );
  final meta = jsonDecode(result.stdout as String);
  final targetDir = meta['target_directory'] as String;
  return DynamicLibrary.open('$targetDir/release/$libName');
}

void main() {
  final lib = _open();

  final resize = lib.lookupFunction<_ResizeNative, _ResizeDart>(
      'weaveffi_image_resize');
  final blur =
      lib.lookupFunction<_BlurNative, _BlurDart>('weaveffi_image_blur');
  final gray =
      lib.lookupFunction<_GrayNative, _GrayDart>('weaveffi_image_grayscale');
  final opDestroy = lib.lookupFunction<_OpDestroyNative, _OpDestroyDart>(
      'weaveffi_image_Operation_destroy');
  final probe =
      lib.lookupFunction<_ProbeNative, _ProbeDart>('weaveffi_image_probe');
  final infoGetWidth = lib.lookupFunction<_InfoGetWidthNative, _InfoGetWidthDart>(
      'weaveffi_image_ImageInfo_get_width');
  final infoGetHeight = lib.lookupFunction<_InfoGetWidthNative, _InfoGetWidthDart>(
      'weaveffi_image_ImageInfo_get_height');
  final infoDestroy = lib.lookupFunction<_InfoDestroyNative, _InfoDestroyDart>(
      'weaveffi_image_ImageInfo_destroy');
  final process = lib.lookupFunction<_ProcessNative, _ProcessDart>(
      'weaveffi_image_process');
  final freeBytes = lib.lookupFunction<_FreeBytesNative, _FreeBytesDart>(
      'weaveffi_free_bytes');
  final errClear = lib.lookupFunction<_ErrClearNative, _ErrClearDart>(
      'weaveffi_error_clear');

  void check(Pointer<WeaveError> err, String what) {
    if (err.ref.code != 0) {
      final msg =
          err.ref.message == nullptr ? '' : err.ref.message.toDartString();
      errClear(err);
      stderr.writeln('dart:   $what failed: $msg');
      exit(1);
    }
  }

  final root = Platform.environment['WEAVEFFI_ROOT'] ?? Directory.current.path;
  final inputPath = '$root/assets/input.jpg';
  final input = File(inputPath).readAsBytesSync();

  final inputBuf = malloc<Uint8>(input.length);
  inputBuf.asTypedList(input.length).setAll(0, input);

  final err = calloc<WeaveError>();

  final infoPtr = probe(inputBuf, input.length, err);
  check(err, 'probe');
  stderr.writeln('dart:   input  ${infoGetWidth(infoPtr)}x${infoGetHeight(infoPtr)}');
  infoDestroy(infoPtr);

  final r = resize(512, 512, err);
  check(err, 'resize');
  final b = blur(2.0, err);
  check(err, 'blur');
  final g = gray(err);
  check(err, 'grayscale');

  final ops = malloc<Pointer<Void>>(3);
  ops[0] = r;
  ops[1] = b;
  ops[2] = g;

  final outLen = calloc<IntPtr>();
  const formatPng = 0;

  final outPtr = process(inputBuf, input.length, ops, 3, formatPng, outLen, err);
  check(err, 'process');

  final outBytes = Uint8List.fromList(outPtr.asTypedList(outLen.value));
  freeBytes(outPtr, outLen.value);
  opDestroy(r);
  opDestroy(b);
  opDestroy(g);
  malloc.free(ops);
  malloc.free(inputBuf);
  calloc.free(outLen);
  calloc.free(err);

  final outPath = '$root/demos/dart/output.png';
  File(outPath).writeAsBytesSync(outBytes);
  final digest = sha256.convert(outBytes).toString();
  stdout.writeln('dart $digest');
  stderr.writeln('dart:   wrote  demos/dart/output.png (${outBytes.length} bytes)');
}

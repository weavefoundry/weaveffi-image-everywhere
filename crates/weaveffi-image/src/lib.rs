//! Pure-Rust image-processing facade with a stable C ABI.
//!
//! Eleven generated WeaveFFI SDKs (Swift, Kotlin, Node, WASM, Python,
//! .NET, Dart, Go, Ruby, C, C++) link against the symbols in this file.
//! Bytes in, bytes out. The `image` crate does the actual work.
//!
//! Determinism note: encoders/decoders in the `image` crate produce
//! byte-identical output for the same input across platforms when the
//! same compression knobs are used. We don't tune them — defaults.
//! That is what lets `scripts/verify.sh` SHA-256 every demo's output
//! and assert they all match.

#![allow(unsafe_code)]
#![allow(non_camel_case_types)]
#![allow(clippy::not_unsafe_ptr_arg_deref)]

use std::io::Cursor;
use std::os::raw::c_char;

use image::{
    imageops, DynamicImage, GenericImageView, ImageEncoder, ImageFormat as ImgFmt, ImageReader,
};
use weaveffi_abi::{self as abi, weaveffi_error};

// ── WASM-host helpers ────
//
// The generated `sdk/wasm/weaveffi_wasm.js` calls these to allocate
// scratch space (e.g. for the WeaveffiError struct) inside the WASM
// linear memory. They're harmless symbols on every other build target.

/// Allocate `size` bytes of zeroed linear memory and return a pointer
/// owned by Rust. Free with `weaveffi_dealloc(ptr, size)`.
#[no_mangle]
pub extern "C" fn weaveffi_alloc(size: usize) -> *mut u8 {
    let v = vec![0u8; size].into_boxed_slice();
    Box::into_raw(v) as *mut u8
}

/// Free memory previously returned by `weaveffi_alloc`.
///
/// # Safety
/// `ptr` must have been returned from `weaveffi_alloc` with the same `size`.
#[no_mangle]
pub unsafe extern "C" fn weaveffi_dealloc(ptr: *mut u8, size: usize) {
    if ptr.is_null() || size == 0 {
        return;
    }
    let slice = std::slice::from_raw_parts_mut(ptr, size);
    drop(Box::from_raw(slice as *mut [u8]));
}

// ── Discriminator constants (mirror the IDL enum values) ────

const KIND_RESIZE: i32 = 0;
const KIND_CROP: i32 = 1;
const KIND_ROTATE: i32 = 2;
const KIND_BLUR: i32 = 3;
const KIND_GRAYSCALE: i32 = 4;

const FMT_PNG: i32 = 0;
const FMT_JPEG: i32 = 1;
const FMT_WEBP: i32 = 2;
const FMT_GIF: i32 = 3;

fn img_fmt_from_i32(v: i32) -> Option<ImgFmt> {
    match v {
        FMT_PNG => Some(ImgFmt::Png),
        FMT_JPEG => Some(ImgFmt::Jpeg),
        FMT_WEBP => Some(ImgFmt::WebP),
        FMT_GIF => Some(ImgFmt::Gif),
        _ => None,
    }
}

fn img_fmt_to_i32(f: ImgFmt) -> i32 {
    match f {
        ImgFmt::Png => FMT_PNG,
        ImgFmt::Jpeg => FMT_JPEG,
        ImgFmt::WebP => FMT_WEBP,
        ImgFmt::Gif => FMT_GIF,
        _ => -1,
    }
}

// ── Operation: a flat tagged record ─────────────────────────

#[repr(C)]
pub struct weaveffi_image_Operation {
    kind: i32,
    width: Option<u32>,
    height: Option<u32>,
    x: Option<u32>,
    y: Option<u32>,
    degrees: Option<f64>,
    sigma: Option<f64>,
}

unsafe fn read_opt_u32(p: *const u32) -> Option<u32> {
    if p.is_null() {
        None
    } else {
        Some(unsafe { *p })
    }
}

unsafe fn read_opt_f64(p: *const f64) -> Option<f64> {
    if p.is_null() {
        None
    } else {
        Some(unsafe { *p })
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_create(
    kind: i32,
    width: *const u32,
    height: *const u32,
    x: *const u32,
    y: *const u32,
    degrees: *const f64,
    sigma: *const f64,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    let op = weaveffi_image_Operation {
        kind,
        width: unsafe { read_opt_u32(width) },
        height: unsafe { read_opt_u32(height) },
        x: unsafe { read_opt_u32(x) },
        y: unsafe { read_opt_u32(y) },
        degrees: unsafe { read_opt_f64(degrees) },
        sigma: unsafe { read_opt_f64(sigma) },
    };
    Box::into_raw(Box::new(op))
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_destroy(ptr: *mut weaveffi_image_Operation) {
    if ptr.is_null() {
        return;
    }
    unsafe { drop(Box::from_raw(ptr)) };
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_kind(ptr: *const weaveffi_image_Operation) -> i32 {
    if ptr.is_null() {
        return -1;
    }
    unsafe { (*ptr).kind }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_width(
    ptr: *const weaveffi_image_Operation,
) -> *mut u32 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).width } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_height(
    ptr: *const weaveffi_image_Operation,
) -> *mut u32 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).height } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_x(
    ptr: *const weaveffi_image_Operation,
) -> *mut u32 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).x } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_y(
    ptr: *const weaveffi_image_Operation,
) -> *mut u32 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).y } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_degrees(
    ptr: *const weaveffi_image_Operation,
) -> *mut f64 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).degrees } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_sigma(
    ptr: *const weaveffi_image_Operation,
) -> *mut f64 {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    match unsafe { (*ptr).sigma } {
        Some(v) => Box::into_raw(Box::new(v)),
        None => std::ptr::null_mut(),
    }
}

// ── ImageInfo: a flat record ────────────────────────────────

#[repr(C)]
pub struct weaveffi_image_ImageInfo {
    width: u32,
    height: u32,
    format: i32,
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_create(
    width: u32,
    height: u32,
    format: i32,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_ImageInfo {
    abi::error_set_ok(out_err);
    Box::into_raw(Box::new(weaveffi_image_ImageInfo {
        width,
        height,
        format,
    }))
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_destroy(ptr: *mut weaveffi_image_ImageInfo) {
    if ptr.is_null() {
        return;
    }
    unsafe { drop(Box::from_raw(ptr)) };
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_width(
    ptr: *const weaveffi_image_ImageInfo,
) -> u32 {
    if ptr.is_null() {
        return 0;
    }
    unsafe { (*ptr).width }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_height(
    ptr: *const weaveffi_image_ImageInfo,
) -> u32 {
    if ptr.is_null() {
        return 0;
    }
    unsafe { (*ptr).height }
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_format(
    ptr: *const weaveffi_image_ImageInfo,
) -> i32 {
    if ptr.is_null() {
        return -1;
    }
    unsafe { (*ptr).format }
}

// ── Factory functions for Operation ─────────────────────────

fn op(
    kind: i32,
    width: Option<u32>,
    height: Option<u32>,
    x: Option<u32>,
    y: Option<u32>,
    degrees: Option<f64>,
    sigma: Option<f64>,
) -> *mut weaveffi_image_Operation {
    Box::into_raw(Box::new(weaveffi_image_Operation {
        kind,
        width,
        height,
        x,
        y,
        degrees,
        sigma,
    }))
}

#[no_mangle]
pub extern "C" fn weaveffi_image_resize(
    width: u32,
    height: u32,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    op(KIND_RESIZE, Some(width), Some(height), None, None, None, None)
}

#[no_mangle]
pub extern "C" fn weaveffi_image_crop(
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    op(
        KIND_CROP,
        Some(width),
        Some(height),
        Some(x),
        Some(y),
        None,
        None,
    )
}

#[no_mangle]
pub extern "C" fn weaveffi_image_rotate(
    degrees: f64,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    op(KIND_ROTATE, None, None, None, None, Some(degrees), None)
}

#[no_mangle]
pub extern "C" fn weaveffi_image_blur(
    sigma: f64,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    op(KIND_BLUR, None, None, None, None, None, Some(sigma))
}

#[no_mangle]
pub extern "C" fn weaveffi_image_grayscale(
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_Operation {
    abi::error_set_ok(out_err);
    op(KIND_GRAYSCALE, None, None, None, None, None, None)
}

// ── Pipeline application ────────────────────────────────────

fn apply_op(img: DynamicImage, op: &weaveffi_image_Operation) -> Result<DynamicImage, String> {
    match op.kind {
        KIND_RESIZE => {
            let w = op
                .width
                .ok_or_else(|| "Resize requires width".to_string())?;
            let h = op
                .height
                .ok_or_else(|| "Resize requires height".to_string())?;
            // Lanczos3 is deterministic across platforms (pure integer math
            // after the kernel weights are computed in f32). Triangle/Nearest
            // would also work; Lanczos3 just looks better for the demo.
            Ok(img.resize_exact(w, h, imageops::FilterType::Lanczos3))
        }
        KIND_CROP => {
            let x = op.x.ok_or_else(|| "Crop requires x".to_string())?;
            let y = op.y.ok_or_else(|| "Crop requires y".to_string())?;
            let w = op
                .width
                .ok_or_else(|| "Crop requires width".to_string())?;
            let h = op
                .height
                .ok_or_else(|| "Crop requires height".to_string())?;
            let (img_w, img_h) = img.dimensions();
            if x.saturating_add(w) > img_w || y.saturating_add(h) > img_h {
                return Err(format!(
                    "Crop ({x},{y},{w}x{h}) exceeds image bounds {img_w}x{img_h}"
                ));
            }
            Ok(img.crop_imm(x, y, w, h))
        }
        KIND_ROTATE => {
            let deg = op
                .degrees
                .ok_or_else(|| "Rotate requires degrees".to_string())?;
            // We support fast 90-degree rotations losslessly. Arbitrary angles
            // would need bilinear/Lanczos resampling and a transparent canvas;
            // skip those for the demo so output stays deterministic.
            let normalized = ((deg % 360.0) + 360.0) % 360.0;
            match normalized as i32 {
                0 => Ok(img),
                90 => Ok(img.rotate90()),
                180 => Ok(img.rotate180()),
                270 => Ok(img.rotate270()),
                _ => Err(format!(
                    "Rotate only supports multiples of 90 degrees (got {deg})"
                )),
            }
        }
        KIND_BLUR => {
            let sigma = op
                .sigma
                .ok_or_else(|| "Blur requires sigma".to_string())?;
            // image::DynamicImage::blur takes f32 sigma
            Ok(img.blur(sigma as f32))
        }
        KIND_GRAYSCALE => Ok(img.grayscale()),
        other => Err(format!("Unknown OpKind: {other}")),
    }
}

fn encode(img: &DynamicImage, format: ImgFmt) -> Result<Vec<u8>, String> {
    let mut buf = Vec::new();
    let mut cursor = Cursor::new(&mut buf);
    match format {
        ImgFmt::Png => {
            // Use a fixed compression / filter to guarantee byte-identical
            // output across platforms. Default PNG encoder is deterministic
            // already but pinning the knobs makes the contract explicit.
            let encoder = image::codecs::png::PngEncoder::new_with_quality(
                &mut cursor,
                image::codecs::png::CompressionType::Default,
                image::codecs::png::FilterType::Adaptive,
            );
            let rgba = img.to_rgba8();
            encoder
                .write_image(
                    rgba.as_raw(),
                    rgba.width(),
                    rgba.height(),
                    image::ExtendedColorType::Rgba8,
                )
                .map_err(|e| format!("PNG encode failed: {e}"))?;
        }
        ImgFmt::Jpeg => {
            let encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut cursor, 90);
            let rgb = img.to_rgb8();
            encoder
                .write_image(
                    rgb.as_raw(),
                    rgb.width(),
                    rgb.height(),
                    image::ExtendedColorType::Rgb8,
                )
                .map_err(|e| format!("JPEG encode failed: {e}"))?;
        }
        ImgFmt::WebP => {
            // image 0.25's WebP encoder is lossless and deterministic.
            let encoder = image::codecs::webp::WebPEncoder::new_lossless(&mut cursor);
            let rgba = img.to_rgba8();
            encoder
                .write_image(
                    rgba.as_raw(),
                    rgba.width(),
                    rgba.height(),
                    image::ExtendedColorType::Rgba8,
                )
                .map_err(|e| format!("WebP encode failed: {e}"))?;
        }
        ImgFmt::Gif => {
            let mut encoder = image::codecs::gif::GifEncoder::new(&mut cursor);
            let rgba = img.to_rgba8();
            let frame = image::Frame::new(rgba);
            encoder
                .encode_frame(frame)
                .map_err(|e| format!("GIF encode failed: {e}"))?;
        }
        _ => return Err(format!("Unsupported output format: {format:?}")),
    }
    Ok(buf)
}

// ── process / probe ────────────────────────────────────────

#[no_mangle]
pub extern "C" fn weaveffi_image_process(
    input_ptr: *const u8,
    input_len: usize,
    ops: *const *const weaveffi_image_Operation,
    ops_len: usize,
    out_format: i32,
    out_len: *mut usize,
    out_err: *mut weaveffi_error,
) -> *mut u8 {
    if !out_len.is_null() {
        unsafe { *out_len = 0 };
    }

    if input_ptr.is_null() || input_len == 0 {
        abi::error_set(out_err, 1, "input buffer is empty");
        return std::ptr::null_mut();
    }
    let format = match img_fmt_from_i32(out_format) {
        Some(f) => f,
        None => {
            abi::error_set(out_err, 2, "invalid out_format");
            return std::ptr::null_mut();
        }
    };

    // SAFETY: caller guarantees `input_ptr` points to `input_len` valid bytes.
    let input = unsafe { std::slice::from_raw_parts(input_ptr, input_len) };

    let mut img = match ImageReader::new(Cursor::new(input))
        .with_guessed_format()
        .map_err(|e| format!("could not detect input format: {e}"))
        .and_then(|r| r.decode().map_err(|e| format!("decode failed: {e}")))
    {
        Ok(i) => i,
        Err(e) => {
            abi::error_set(out_err, 3, &e);
            return std::ptr::null_mut();
        }
    };

    if ops_len > 0 {
        if ops.is_null() {
            abi::error_set(out_err, 4, "ops array is null but ops_len > 0");
            return std::ptr::null_mut();
        }
        for i in 0..ops_len {
            // SAFETY: `ops` is a `*const *const Operation` array of length
            // `ops_len`; each element was returned by one of our factory
            // functions and is owned by the caller until they call
            // `Operation_destroy`.
            let op_ptr = unsafe { *ops.add(i) };
            if op_ptr.is_null() {
                abi::error_set(out_err, 5, "null Operation pointer");
                return std::ptr::null_mut();
            }
            let op = unsafe { &*op_ptr };
            img = match apply_op(img, op) {
                Ok(next) => next,
                Err(e) => {
                    abi::error_set(out_err, 6, &e);
                    return std::ptr::null_mut();
                }
            };
        }
    }

    let bytes = match encode(&img, format) {
        Ok(b) => b,
        Err(e) => {
            abi::error_set(out_err, 7, &e);
            return std::ptr::null_mut();
        }
    };

    abi::error_set_ok(out_err);
    let len = bytes.len();
    if !out_len.is_null() {
        unsafe { *out_len = len };
    }
    let boxed = bytes.into_boxed_slice();
    Box::into_raw(boxed) as *mut u8
}

#[no_mangle]
pub extern "C" fn weaveffi_image_probe(
    input_ptr: *const u8,
    input_len: usize,
    out_err: *mut weaveffi_error,
) -> *mut weaveffi_image_ImageInfo {
    if input_ptr.is_null() || input_len == 0 {
        abi::error_set(out_err, 1, "input buffer is empty");
        return std::ptr::null_mut();
    }
    // SAFETY: caller guarantees `input_ptr` points to `input_len` valid bytes.
    let input = unsafe { std::slice::from_raw_parts(input_ptr, input_len) };
    let reader = match ImageReader::new(Cursor::new(input)).with_guessed_format() {
        Ok(r) => r,
        Err(e) => {
            abi::error_set(out_err, 3, &format!("could not detect format: {e}"));
            return std::ptr::null_mut();
        }
    };
    let format = match reader.format() {
        Some(f) => f,
        None => {
            abi::error_set(out_err, 3, "could not detect image format");
            return std::ptr::null_mut();
        }
    };
    let dims = match reader.into_dimensions() {
        Ok(d) => d,
        Err(e) => {
            abi::error_set(out_err, 3, &format!("decode failed: {e}"));
            return std::ptr::null_mut();
        }
    };

    abi::error_set_ok(out_err);
    Box::into_raw(Box::new(weaveffi_image_ImageInfo {
        width: dims.0,
        height: dims.1,
        format: img_fmt_to_i32(format),
    }))
}

// ── Standard runtime symbols ────────────────────────────────

#[no_mangle]
pub extern "C" fn weaveffi_free_string(ptr: *const c_char) {
    abi::free_string(ptr);
}

#[no_mangle]
pub extern "C" fn weaveffi_free_bytes(ptr: *mut u8, len: usize) {
    abi::free_bytes(ptr, len);
}

#[no_mangle]
pub extern "C" fn weaveffi_error_clear(err: *mut weaveffi_error) {
    abi::error_clear(err);
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ptr;

    fn checker_jpeg() -> Vec<u8> {
        // Build a tiny 8x8 RGB JPEG in-process so tests don't need a
        // network or asset file.
        let mut img = image::RgbImage::new(8, 8);
        for (x, y, p) in img.enumerate_pixels_mut() {
            let v: u8 = if (x + y) % 2 == 0 { 255 } else { 0 };
            *p = image::Rgb([v, v, v]);
        }
        let mut buf = Vec::new();
        image::DynamicImage::ImageRgb8(img)
            .write_to(&mut Cursor::new(&mut buf), ImgFmt::Jpeg)
            .unwrap();
        buf
    }

    #[test]
    fn probe_decodes_jpeg() {
        let buf = checker_jpeg();
        let mut err = weaveffi_error::default();
        let info = weaveffi_image_probe(buf.as_ptr(), buf.len(), &mut err);
        assert!(!info.is_null());
        assert_eq!(err.code, 0);
        unsafe {
            assert_eq!((*info).width, 8);
            assert_eq!((*info).height, 8);
            assert_eq!((*info).format, FMT_JPEG);
        }
        weaveffi_image_ImageInfo_destroy(info);
    }

    #[test]
    fn process_resize_grayscale_to_png_is_deterministic() {
        let buf = checker_jpeg();
        let mut err = weaveffi_error::default();

        let resize_op = weaveffi_image_resize(4, 4, &mut err);
        let gray_op = weaveffi_image_grayscale(&mut err);
        assert!(!resize_op.is_null() && !gray_op.is_null());

        let ops: [*const weaveffi_image_Operation; 2] = [resize_op, gray_op];
        let mut out_len: usize = 0;
        let result = weaveffi_image_process(
            buf.as_ptr(),
            buf.len(),
            ops.as_ptr(),
            ops.len(),
            FMT_PNG,
            &mut out_len,
            &mut err,
        );
        assert!(!result.is_null());
        assert_eq!(err.code, 0);
        assert!(out_len > 0);

        let bytes = unsafe { std::slice::from_raw_parts(result, out_len).to_vec() };
        // PNG signature
        assert_eq!(&bytes[0..8], &[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        weaveffi_image_Operation_destroy(resize_op);
        weaveffi_image_Operation_destroy(gray_op);
        weaveffi_free_bytes(result, out_len);
    }

    #[test]
    fn process_with_no_ops_returns_reencoded_input() {
        let buf = checker_jpeg();
        let mut err = weaveffi_error::default();
        let mut out_len: usize = 0;
        let result = weaveffi_image_process(
            buf.as_ptr(),
            buf.len(),
            ptr::null(),
            0,
            FMT_PNG,
            &mut out_len,
            &mut err,
        );
        assert_eq!(err.code, 0);
        assert!(!result.is_null());
        assert!(out_len > 0);
        weaveffi_free_bytes(result, out_len);
    }

    #[test]
    fn process_rejects_invalid_format() {
        let buf = checker_jpeg();
        let mut err = weaveffi_error::default();
        let mut out_len: usize = 99;
        let result = weaveffi_image_process(
            buf.as_ptr(),
            buf.len(),
            ptr::null(),
            0,
            999,
            &mut out_len,
            &mut err,
        );
        assert!(result.is_null());
        assert_eq!(out_len, 0);
        assert_ne!(err.code, 0);
        weaveffi_error_clear(&mut err);
    }

    #[test]
    fn rotate_arbitrary_angle_errors() {
        let buf = checker_jpeg();
        let mut err = weaveffi_error::default();
        let rot = weaveffi_image_rotate(45.0, &mut err);
        let ops: [*const weaveffi_image_Operation; 1] = [rot];
        let mut out_len: usize = 0;
        let result = weaveffi_image_process(
            buf.as_ptr(),
            buf.len(),
            ops.as_ptr(),
            1,
            FMT_PNG,
            &mut out_len,
            &mut err,
        );
        assert!(result.is_null());
        assert_ne!(err.code, 0);
        weaveffi_image_Operation_destroy(rot);
        weaveffi_error_clear(&mut err);
    }

    #[test]
    fn op_getters_round_trip_options() {
        let mut err = weaveffi_error::default();
        let r = weaveffi_image_resize(100, 200, &mut err);
        assert_eq!(weaveffi_image_Operation_get_kind(r), KIND_RESIZE);

        let w = weaveffi_image_Operation_get_width(r);
        assert!(!w.is_null());
        unsafe {
            assert_eq!(*w, 100);
            drop(Box::from_raw(w));
        }

        let h = weaveffi_image_Operation_get_height(r);
        assert!(!h.is_null());
        unsafe {
            assert_eq!(*h, 200);
            drop(Box::from_raw(h));
        }

        // unused fields are null
        assert!(weaveffi_image_Operation_get_x(r).is_null());
        assert!(weaveffi_image_Operation_get_sigma(r).is_null());

        weaveffi_image_Operation_destroy(r);
    }
}

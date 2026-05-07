#![allow(unsafe_code)]
#![allow(clippy::not_unsafe_ptr_arg_deref)]

use std::os::raw::c_char;
use weaveffi_abi::*;

#[repr(C)]
pub struct weaveffi_image_Operation {
    // TODO: add fields
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_create(kind: i32, width: *const u32, height: *const u32, x: *const u32, y: *const u32, degrees: *const f64, sigma: *const f64, out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_destroy(ptr: *mut weaveffi_image_Operation) {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_kind(ptr: *const weaveffi_image_Operation) -> i32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_width(ptr: *const weaveffi_image_Operation) -> *mut u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_height(ptr: *const weaveffi_image_Operation) -> *mut u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_x(ptr: *const weaveffi_image_Operation) -> *mut u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_y(ptr: *const weaveffi_image_Operation) -> *mut u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_degrees(ptr: *const weaveffi_image_Operation) -> *mut f64 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_Operation_get_sigma(ptr: *const weaveffi_image_Operation) -> *mut f64 {
    todo!()
}

#[repr(C)]
pub struct weaveffi_image_ImageInfo {
    // TODO: add fields
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_create(width: u32, height: u32, format: i32, out_err: *mut weaveffi_error) -> *mut weaveffi_image_ImageInfo {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_destroy(ptr: *mut weaveffi_image_ImageInfo) {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_width(ptr: *const weaveffi_image_ImageInfo) -> u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_height(ptr: *const weaveffi_image_ImageInfo) -> u32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_ImageInfo_get_format(ptr: *const weaveffi_image_ImageInfo) -> i32 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_resize(width: u32, height: u32, out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_crop(x: u32, y: u32, width: u32, height: u32, out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_rotate(degrees: f64, out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_blur(sigma: f64, out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_grayscale(out_err: *mut weaveffi_error) -> *mut weaveffi_image_Operation {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_process(input_ptr: *const u8, input_len: usize, ops: *const *const weaveffi_image_Operation, ops_len: usize, out_format: i32, out_len: *mut usize, out_err: *mut weaveffi_error) -> *mut u8 {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_image_probe(input_ptr: *const u8, input_len: usize, out_err: *mut weaveffi_error) -> *mut weaveffi_image_ImageInfo {
    todo!()
}

#[no_mangle]
pub extern "C" fn weaveffi_free_string(ptr: *const c_char) {
    free_string(ptr);
}

#[no_mangle]
pub extern "C" fn weaveffi_free_bytes(ptr: *mut u8, len: usize) {
    free_bytes(ptr, len);
}

#[no_mangle]
pub extern "C" fn weaveffi_error_clear(err: *mut weaveffi_error) {
    error_clear(err);
}

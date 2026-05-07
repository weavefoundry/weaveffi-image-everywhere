// C++ demo for weaveffi-image.
//
// Uses the WeaveFFI C ABI directly. The generated header-only wrapper at
// sdk/cpp/weaveffi.hpp is also valid for most operations, but the
// process() helper has a const-correctness bug in WeaveFFI 0.4.0; this
// demo will switch back to the wrapper once that fix lands.
#include <CommonCrypto/CommonDigest.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

extern "C" {
#include "weaveffi.h"
}

static std::vector<uint8_t> read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        std::cerr << "cpp:    could not open " << path << "\n";
        std::exit(1);
    }
    return std::vector<uint8_t>(
        (std::istreambuf_iterator<char>(in)),
        std::istreambuf_iterator<char>());
}

static void write_file(const std::string& path, const uint8_t* data, size_t len) {
    std::ofstream out(path, std::ios::binary);
    out.write(reinterpret_cast<const char*>(data), len);
}

static std::string sha256_hex(const uint8_t* data, size_t len) {
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data, static_cast<CC_LONG>(len), digest);
    char hex[2 * CC_SHA256_DIGEST_LENGTH + 1];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        std::snprintf(hex + i * 2, 3, "%02x", digest[i]);
    }
    return std::string(hex, 2 * CC_SHA256_DIGEST_LENGTH);
}

static void check(weaveffi_error& err, const char* what) {
    if (err.code != 0) {
        std::string msg = err.message ? err.message : "?";
        weaveffi_error_clear(&err);
        throw std::runtime_error(std::string(what) + ": " + msg);
    }
}

int main() {
    const char* root_env = std::getenv("WEAVEFFI_ROOT");
    std::string root = root_env ? root_env : ".";

    auto input = read_file(root + "/assets/input.jpg");

    weaveffi_error err = {0, nullptr};

    auto* info = weaveffi_image_probe(input.data(), input.size(), &err);
    check(err, "probe");
    std::cerr << "cpp:    input  "
              << weaveffi_image_ImageInfo_get_width(info) << "x"
              << weaveffi_image_ImageInfo_get_height(info) << "\n";
    weaveffi_image_ImageInfo_destroy(info);

    auto* resize = weaveffi_image_resize(512, 512, &err); check(err, "resize");
    auto* blur   = weaveffi_image_blur(2.0, &err);        check(err, "blur");
    auto* gray   = weaveffi_image_grayscale(&err);        check(err, "grayscale");

    weaveffi_image_Operation* ops[] = {resize, blur, gray};
    size_t out_len = 0;
    const uint8_t* out_ptr = weaveffi_image_process(
        input.data(), input.size(),
        ops, 3,
        weaveffi_image_ImageFormat_Png,
        &out_len, &err);
    check(err, "process");

    weaveffi_image_Operation_destroy(resize);
    weaveffi_image_Operation_destroy(blur);
    weaveffi_image_Operation_destroy(gray);

    write_file(root + "/demos/cpp/output.png", out_ptr, out_len);
    std::cout << "cpp " << sha256_hex(out_ptr, out_len) << "\n";
    std::cerr << "cpp:    wrote  demos/cpp/output.png (" << out_len << " bytes)\n";

    weaveffi_free_bytes(const_cast<uint8_t*>(out_ptr), out_len);
    return 0;
}

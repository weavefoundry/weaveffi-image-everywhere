// C demo for weaveffi-image.
//
// Calls the WeaveFFI C ABI directly. Uses CommonCrypto on macOS for
// SHA-256; on Linux swap to <openssl/sha.h> (and link -lcrypto).
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <CommonCrypto/CommonDigest.h>

#include "weaveffi.h"

static int read_file(const char* path, uint8_t** out, size_t* out_len) {
    FILE* f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t* buf = (uint8_t*)malloc(size);
    if (!buf) { fclose(f); return -1; }
    size_t n = fread(buf, 1, size, f);
    fclose(f);
    if (n != (size_t)size) { free(buf); return -1; }
    *out = buf;
    *out_len = n;
    return 0;
}

static int write_file(const char* path, const uint8_t* data, size_t len) {
    FILE* f = fopen(path, "wb");
    if (!f) return -1;
    size_t n = fwrite(data, 1, len, f);
    fclose(f);
    return n == len ? 0 : -1;
}

static void sha256_hex(const uint8_t* data, size_t len, char hex[65]) {
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data, (CC_LONG)len, digest);
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        snprintf(hex + i * 2, 3, "%02x", digest[i]);
    }
    hex[64] = '\0';
}

#define CHECK(err, what) do { \
    if ((err).code != 0) { \
        fprintf(stderr, "c:      %s failed: %s (code %d)\n", \
                (what), (err).message ? (err).message : "?", (err).code); \
        weaveffi_error_clear(&(err)); \
        return 1; \
    } \
} while (0)

int main(int argc, char** argv) {
    const char* root = getenv("WEAVEFFI_ROOT");
    if (!root) root = ".";

    char input_path[1024];
    snprintf(input_path, sizeof(input_path), "%s/assets/input.jpg", root);
    uint8_t* input = NULL;
    size_t input_len = 0;
    if (read_file(input_path, &input, &input_len) != 0) {
        fprintf(stderr, "c:      could not read %s\n", input_path);
        return 1;
    }

    weaveffi_error err = {0, NULL};

    weaveffi_image_ImageInfo* info = weaveffi_image_probe(input, input_len, &err);
    CHECK(err, "probe");
    fprintf(stderr, "c:      input  %ux%u\n",
            weaveffi_image_ImageInfo_get_width(info),
            weaveffi_image_ImageInfo_get_height(info));
    weaveffi_image_ImageInfo_destroy(info);

    weaveffi_image_Operation* resize = weaveffi_image_resize(512, 512, &err);
    CHECK(err, "resize");
    weaveffi_image_Operation* blur = weaveffi_image_blur(2.0, &err);
    CHECK(err, "blur");
    weaveffi_image_Operation* gray = weaveffi_image_grayscale(&err);
    CHECK(err, "grayscale");

    weaveffi_image_Operation* ops[3] = {resize, blur, gray};
    size_t out_len = 0;
    const uint8_t* out_ptr = weaveffi_image_process(
        input, input_len, ops, 3,
        weaveffi_image_ImageFormat_Png, &out_len, &err);
    CHECK(err, "process");

    weaveffi_image_Operation_destroy(resize);
    weaveffi_image_Operation_destroy(blur);
    weaveffi_image_Operation_destroy(gray);

    char output_path[1024];
    snprintf(output_path, sizeof(output_path), "%s/demos/c/output.png", root);
    if (write_file(output_path, out_ptr, out_len) != 0) {
        fprintf(stderr, "c:      write failed\n");
        return 1;
    }

    char hex[65];
    sha256_hex(out_ptr, out_len, hex);
    printf("c %s\n", hex);
    fprintf(stderr, "c:      wrote  demos/c/output.png (%zu bytes)\n", out_len);

    weaveffi_free_bytes((uint8_t*)out_ptr, out_len);
    free(input);
    (void)argc; (void)argv;
    return 0;
}

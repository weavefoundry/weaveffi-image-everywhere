// Go demo for weaveffi-image.
//
// Loads the auto-generated CGo bindings, runs the canonical pipeline,
// writes output.png next to this binary's source, prints sha256.
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"

	weaveffi "github.com/weavefoundry/weaveffi-image-everywhere/sdk/go"
)

func main() {
	input, err := os.ReadFile("../../assets/input.jpg")
	if err != nil {
		fmt.Fprintf(os.Stderr, "read input: %v\n", err)
		os.Exit(1)
	}

	info, err := weaveffi.ImageProbe(input)
	if err != nil {
		fmt.Fprintf(os.Stderr, "probe: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintf(os.Stderr, "go:     input  %dx%d (%v)\n", info.Width(), info.Height(), info.Format())
	info.Close()

	resize, err := weaveffi.ImageResize(512, 512)
	if err != nil {
		fmt.Fprintf(os.Stderr, "resize: %v\n", err)
		os.Exit(1)
	}
	defer resize.Close()
	blur, err := weaveffi.ImageBlur(2.0)
	if err != nil {
		fmt.Fprintf(os.Stderr, "blur: %v\n", err)
		os.Exit(1)
	}
	defer blur.Close()
	gray, err := weaveffi.ImageGrayscale()
	if err != nil {
		fmt.Fprintf(os.Stderr, "grayscale: %v\n", err)
		os.Exit(1)
	}
	defer gray.Close()

	out, err := weaveffi.ImageProcess(input, []*weaveffi.Operation{resize, blur, gray}, weaveffi.ImageFormatPng)
	if err != nil {
		fmt.Fprintf(os.Stderr, "process: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile("output.png", out, 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "write output: %v\n", err)
		os.Exit(1)
	}

	digest := sha256.Sum256(out)
	fmt.Printf("go %s\n", hex.EncodeToString(digest[:]))
	fmt.Fprintf(os.Stderr, "go:     wrote  demos/go/output.png (%d bytes)\n", len(out))
}

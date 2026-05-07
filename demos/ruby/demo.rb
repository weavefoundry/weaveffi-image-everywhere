#!/usr/bin/env ruby
# Ruby demo for weaveffi-image.
#
# Loads the auto-generated FFI bindings, runs the canonical pipeline,
# writes output.png next to this script, prints sha256.

require 'digest'
require 'ffi'
require 'json'
require 'open3'

ROOT = File.expand_path('../..', __dir__)

# Locate libweaveffi.dylib via cargo metadata so we don't depend on
# DYLD_*_PATH (which macOS strips from system Ruby anyway). Override
# FFI::Library.ffi_lib so that the bare name 'libweaveffi.dylib' that
# the generated SDK requests resolves to the absolute build path.
def lib_path
  return ENV['WEAVEFFI_LIB'] if ENV['WEAVEFFI_LIB'] && File.exist?(ENV['WEAVEFFI_LIB'])
  meta_json, status = Open3.capture2(
    'cargo', 'metadata', '--no-deps', '--format-version=1',
    chdir: ROOT,
  )
  abort 'cargo metadata failed' unless status.success?
  meta = JSON.parse(meta_json)
  target_dir = meta['target_directory']
  candidates = ['libweaveffi.dylib', 'libweaveffi.so', 'weaveffi.dll']
  candidates.each do |name|
    path = File.join(target_dir, 'release', name)
    return path if File.exist?(path)
  end
  abort "weaveffi shared library not found under #{target_dir}/release"
end

LIB = lib_path
warn "ruby:   lib    #{LIB}"

module FFI
  module Library
    alias_method :_orig_ffi_lib, :ffi_lib
    def ffi_lib(*names)
      patched = names.map do |n|
        case File.basename(n.to_s)
        when 'libweaveffi.dylib', 'libweaveffi.so', 'weaveffi.dll'
          LIB
        else
          n
        end
      end
      _orig_ffi_lib(*patched)
    end
  end
end

require_relative '../../sdk/ruby/lib/weaveffi'

input = File.binread(File.join(ROOT, 'assets/input.jpg'))

info = WeaveImage.probe(input)
warn "ruby:   input  #{info.width}x#{info.height} (format=#{info.format})"

ops = [
  WeaveImage.resize(512, 512),
  WeaveImage.blur(2.0),
  WeaveImage.grayscale,
]
output = WeaveImage.process(input, ops, WeaveImage::ImageFormat::PNG)

output_path = File.join(__dir__, 'output.png')
File.binwrite(output_path, output)
digest = Digest::SHA256.hexdigest(output)
puts "ruby #{digest}"
warn "ruby:   wrote  demos/ruby/output.png (#{output.bytesize} bytes)"

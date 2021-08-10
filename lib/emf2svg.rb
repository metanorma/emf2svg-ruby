# frozen_string_literal: true

require "ffi"
require_relative "emf2svg/version"

module Emf2svg
  class Error < StandardError; end

  class GeneratorOptions < FFI::Struct
    layout :nameSpace, :string,
           :verbose, :bool,
           :emfplus, :bool,
           :svgDelimiter, :bool,
           :imgHeight, :double,
           :imgWidth, :double
  end

  extend FFI::Library

  lib_filename = if FFI::Platform.windows?
                   "emf2svg.dll"
                 elsif FFI::Platform.mac?
                   "libemf2svg.dylib"
                 else
                   "libemf2svg.so"
                 end

  ffi_lib File.expand_path("emf2svg/#{lib_filename}", __dir__)
    .gsub("/", File::ALT_SEPARATOR || File::SEPARATOR)

  attach_function :emf2svg,
                  [
                    :pointer,
                    :size_t,
                    :pointer,
                    :pointer,
                    GeneratorOptions.by_ref,
                  ],
                  :int

  class << self
    def from_file(path)
      content = File.read(path, mode: "rb")
      from_binary_string(content)
    end

    def from_binary_string(content)
      svg_out = FFI::MemoryPointer.new(:pointer)
      svg_out_len = FFI::MemoryPointer.new(:pointer)
      content_ptr = FFI::MemoryPointer.from_string(content)

      ret = emf2svg(content_ptr, content.size, svg_out, svg_out_len, options)
      raise Error, "emf2svg failed with error code: #{ret}" unless ret == 1

      svg_out.read_pointer.read_bytes(svg_out_len.read_int)
    end

    private

    def options
      GeneratorOptions.new.tap do |opts|
        opts[:verbose] = false
        opts[:emfplus] = true
        opts[:svgDelimiter] = true
        opts[:imgHeight] = 0
        opts[:imgWidth] = 0
      end
    end
  end
end

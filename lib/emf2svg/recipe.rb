require "rbconfig"
require "mini_portile2"
require "pathname"
require "tmpdir"

module Emf2svg
  class Recipe < MiniPortileCMake
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libemf2svg", "1.6.0")

      @files << {
        url: "https://github.com/metanorma/libemf2svg/releases/download/v1.6.0/libemf2svg.tar.gz",
        sha256: "0f186f40b98c06acdec1278a314cEc1f093e7504d34f7a15b697ebfe6c4d3097", # rubocop:disable Layout/LineLength
      }

      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      super

      FileUtils.touch(checkpoint)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def host_platform
      @host_platform ||=
        case @host
        when /\Ax86_64.*mingw32/
          "x64-mingw32"
        when /\Ai[3-6]86.*mingw32/
          "x86-mingw32"
        when /\Ax86_64.*linux/
          "x86_64-linux"
        when /\A(arm64|aarch64).*linux/
          "arm64-linux"
        when /\Ai[3-6]86.*linux/
          "x86-linux"
        when /\Ax86_64.*(darwin|macos|osx)/
          "x86_64-darwin"
        when /\A(arm64|aarch64).*(darwin|macos|osx)/
          "arm64-darwin"
        else
          @host
        end
    end

    def target_platform
      @target_platform ||=
        case ENV["target_platform"]
        when /\A(arm64|aarch64).*(darwin|macos|osx)/
          "arm64-darwin"
        when /\Ac86_64.*(darwin|macos|osx)/
          "x86_64-darwin"
        when /\A(arm64|aarch64).*linux/
          "arm64-linux"
        else
          ENV["target_platform"] || host_platform
        end
    end

    def target_triplet
      @target_triplet ||=
        case target_platform
        when "arm64-darwin"
          "arm64-osx"
        when "x86_64-darwin"
          "x86_64-osx"
        else
          target_platform
        end
    end

    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def cross_compiling?
      not host_platform.eql? target_platform
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{target_platform}.installed")
    end

    def configure_defaults
      opts = []

      opts << "-DCMAKE_BUILD_TYPE=Release"

      if MiniPortile.windows? || cross_compiling?
        opts << "-DCMAKE_TOOLCHAIN_FILE=vcpkg/scripts/buildsystems/vcpkg.cmake"
      end

      if cross_compiling? && (not MiniPortile.windows?)
        message("Cross-compiling on #{host_platform} for #{target_platform}\n")
        opts << "-DVCPKG_TARGET_TRIPLET=#{target_triplet}"
      end

      opts
    end

    def compile
      execute("compile", "#{make_cmd} --target emf2svg")
    end

    def make_cmd
      "cmake --build #{File.expand_path(work_path)} --config Release"
    end

    def install
      libs = if MiniPortile.windows?
               Dir.glob(File.join(work_path, "Release", "*.dll"))
             else
               Dir.glob(File.join(work_path, "libemf2svg.{so,dylib}"))
                 .grep(/\/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib)$/)
             end

      FileUtils.cp_r(libs, ROOT.join("lib", "emf2svg"), verbose: true)
    end

    def execute(action, command, command_opts = {})
      super(action, command, command_opts.merge(debug: true))
    end

    def message(text)
      return super unless text.start_with?("\rDownloading")

      match = text.match(/(\rDownloading .*)\(\s*\d+%\)/)
      pattern = match ? match[1] : text
      return if @printed[pattern]

      @printed[pattern] = true
      super
    end

    private

    def tmp_path
      @tmp_path ||= Dir.mktmpdir
    end

    def port_path
      "port"
    end
  end
end

require "rbconfig"
require "mini_portile2"
require "pathname"
require "tmpdir"

module Emf2svg
  class Recipe < MiniPortileCMake
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libemf2svg", "1.4.0")

      @files << {
        url: "https://github.com/metanorma/libemf2svg/releases/download/v1.4.0/libemf2svg.tar.gz",
        sha256: "e05081986a0ec6c5bd494068825c7b55dd21fa1814942a61293b225af2d957d2", # rubocop:disable Layout/LineLength
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
        when /\Ax86_64.*darwin/
          "x86_64-darwin"
        when /\Aarm64.*darwin/
          "arm64-darwin"
        else
          @host
        end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def target_platform
      @target_platform = ENV["target_platform"] || host_platform
    end

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
        opts << "-DVCPKG_TARGET_TRIPLET=#{target_platform}"
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

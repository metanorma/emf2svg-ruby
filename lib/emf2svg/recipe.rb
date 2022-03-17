require "mini_portile2"
require "pathname"
require "tmpdir"

module Emf2svg
  class Recipe < MiniPortileCMake
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libemf2svg", "1.3.1")

      @files << {
        url: "https://github.com/metanorma/libemf2svg/releases/download/1.3.1/libemf2svg.tar.gz",
        sha256: "732c60c54d0692a8634221e6ffb0733ad0bb1d9a246a03ba2433c535441eb73e", # rubocop:disable Layout/LineLength
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

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def configure_defaults
      opts = []

      opts << "-DCMAKE_BUILD_TYPE=Release"

      if MiniPortile.windows?
        opts << "-DCMAKE_TOOLCHAIN_FILE=vcpkg/scripts/buildsystems/vcpkg.cmake"
        opts << "-GVisual Studio 16 2019"
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

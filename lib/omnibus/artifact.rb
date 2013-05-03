module Omnibus
  class Artifact

    attr_reader :path
    attr_reader :platforms
    attr_reader :config

    def initialize(path, platforms, config)
      @path = path
      @platforms = platforms
      @config = config
    end

    # Adds the package to +release_manifest+, which is a Hash. The result is in this form:
    #   "el" => {
    #     "5" => { "x86_64" => { "11.4.0-1" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm" } }
    #   }
    # This method mutates the argument (hence the `!` at the end). The updated
    # release manifest is returned.
    def add_to_release_manifest!(release_manifest)
      platforms.each do |distro, version, arch|
        release_manifest[distro] ||= {}
        release_manifest[distro][version] ||= {}
        release_manifest[distro][version][arch] = { build_version => relpath }
        # TODO: when adding checksums, the desired format is like this:
        # build_support_json[platform][platform_version][machine_architecture][options[:version]]["relpath"] = build_location
      end
      release_manifest
    end

    # Adds the package to +release_manifest+, which is a Hash. The result is in this form:
    #   "el" => {
    #     "5" => {
    #       "x86_64" => {
    #         "11.4.0-1" => {
    #           "relpath" => "/el/5/x86_64/demoproject-11.4.0-1.el5.x86_64.rpm",
    #           "md5" => "123f00d...",
    #           "sha256" => 456beef..."
    #         }
    #       }
    #     }
    #   }
    # This method mutates the argument (hence the `!` at the end). The updated
    # release manifest is returned.
    def add_to_v2_release_manifest!(release_manifest)
      platforms.each do |distro, version, arch|
        pkg_info = {
          "relpath" => relpath,
          "md5" => md5,
          "sha256" => sha256
        }

        release_manifest[distro] ||= {}
        release_manifest[distro][version] ||= {}
        release_manifest[distro][version][arch] = { build_version => pkg_info  }
      end
      release_manifest
    end

    def flat_metadata
      distro, version, arch = build_platform
      {
        "platform" => distro,
        "platform_version" => version,
        "arch" => arch,
        "version" => build_version,
        "basename" => File.basename(path),
        "md5" => md5,
        "sha256" => sha256
      }
    end

    def build_platform
      platforms.first
    end

    def build_version
      config[:version]
    end

    def relpath
      # upload build to build platform directory
      "/#{build_platform.join('/')}/#{path.split('/').last}"
    end

    def md5
      @md5 ||= digest(Digest::MD5)
    end

    def sha256
      @sha256 ||= digest(Digest::SHA256)
    end

    private

    def digest(digest_class)
      digest = digest_class.new
      File.open(path) do |io|
        while chunk = io.read(1024 * 8)
          digest.update(chunk)
        end
      end
      digest.hexdigest
    end
  end
end


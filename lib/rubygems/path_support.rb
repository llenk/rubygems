# frozen_string_literal: true

##
#
# Gem::PathSupport facilitates the GEM_HOME and GEM_PATH environment settings
# to the rest of RubyGems.
#
class Gem::PathSupport
  ##
  # The default system path for managing Gems.
  attr_reader :home

  ##
  # Array of paths to search for Gems.
  attr_reader :path

  ##
  # Directory with spec cache
  attr_reader :spec_cache_dir # :nodoc:

  ##
  #
  # Constructor. Takes a single argument which is to be treated like a
  # hashtable, or defaults to ENV, the system environment.
  #
  def initialize(env)
    @home = env["GEM_HOME"] || Gem.default_dir

    if File::ALT_SEPARATOR
      @home = @home.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
    end

    @home = expand(@home)

    # If @home (aka Gem.paths.home) exists, but we can't write to it,
    # fall back to Gem.user_dir (the directory used for user installs).
    if File.exist?(@home) && !File.writable?(@home)
      warn "The default GEM_HOME (#{@home}) is not" \
            " writable, so rubygems is falling back to installing" \
            " under your home folder. To get rid of this warning" \
            " permanently either fix your GEM_HOME folder permissions" \
            " or add the following to your ~/.gemrc file:\n" \
            "    gem: --install-dir #{Gem.user_dir}"

      @home = Gem.user_dir
    end

    @path = split_gem_path env["GEM_PATH"], @home

    @spec_cache_dir = env["GEM_SPEC_CACHE"] || Gem.default_spec_cache_dir

    @spec_cache_dir = @spec_cache_dir.dup.tap(&Gem::UNTAINT)
  end

  private

  ##
  # Split the Gem search path (as reported by Gem.path).

  def split_gem_path(gpaths, home)
    # FIX: it should be [home, *path], not [*path, home]

    gem_path = []

    if gpaths
      gem_path = gpaths.split(Gem.path_separator)
      # Handle the path_separator being set to a regexp, which will cause
      # end_with? to error
      if /#{Gem.path_separator}\z/.match?(gpaths)
        gem_path += default_path
      end

      if File::ALT_SEPARATOR
        gem_path.map! do |this_path|
          this_path.gsub File::ALT_SEPARATOR, File::SEPARATOR
        end
      end

      gem_path << home
    else
      gem_path = default_path
    end

    gem_path.map {|path| expand(path) }.uniq
  end

  # Return the default Gem path
  def default_path
    Gem.default_path + [@home]
  end

  def expand(path)
    if File.directory?(path)
      File.realpath(path)
    else
      path
    end
  end
end

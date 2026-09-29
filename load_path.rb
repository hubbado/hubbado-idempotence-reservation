bundler_standalone_loader = ENV["BUNDLER_STANDALONE_LOADER"] || "gems/bundler/setup"

begin
  require_relative bundler_standalone_loader
rescue LoadError
  warn "WARNING: Standalone bundle loader is not at #{bundler_standalone_loader}. Using Bundler to load gems."
  require "bundler/setup"
  Bundler.require
end

libraries_dir = ENV["LIBRARIES_HOME"]
unless libraries_dir.nil?
  libraries_dir = File.expand_path(libraries_dir)
  $LOAD_PATH.unshift libraries_dir unless $LOAD_PATH.include?(libraries_dir)

  # A dangling link loads the installed gem instead, with no error of its own
  Dir.glob("**/*", base: libraries_dir).each do |entry|
    link = File.join(libraries_dir, entry)

    if File.symlink?(link) && !File.exist?(link)
      warn "WARNING: LIBRARIES_HOME link is dangling: #{link} -> #{File.readlink(link)}"
    end
  end
end

# The bundle already put this lib on the load path, behind LIBRARIES_HOME, which
# can link another checkout of this same project
lib_dir = File.expand_path("lib", __dir__)
$LOAD_PATH.delete(lib_dir)
$LOAD_PATH.unshift(lib_dir)

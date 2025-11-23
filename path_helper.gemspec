# frozen_string_literal: true

require_relative "exe/path_helper"

Gem::Specification.new do |spec|
  spec.name          = "path_helper"
  spec.version       = PathHelper::VERSION
  spec.authors       = ["Iain Barnett"]
  spec.email         = ["helpful-iain@theprintedbird.com"]

  spec.summary       = "A better path_helper - manages environment variable paths with per-user support"
  spec.description   = <<~DESC
    A replacement for Apple's /usr/libexec/path_helper that fixes significant issues
    and extends functionality. Features include: per-user paths (not just system-wide),
    support for multiple environment variables (PATH, MANPATH, C_INCLUDE_PATH, PKG_CONFIG_PATH,
    DYLD_FALLBACK_LIBRARY_PATH, DYLD_FALLBACK_FRAMEWORK_PATH), helpful debugging output,
    and no side effects (returns paths without eval or setting variables internally).
  DESC
  spec.homepage      = "https://github.com/yb66/path_helper"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.3.7"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yb66/path_helper"
  spec.metadata["changelog_uri"] = "https://github.com/yb66/path_helper/blob/master/CHANGES.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/yb66/path_helper/issues"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "exe/**/*",
    "LICENCE",
    "README.md",
    "CHANGES.md"
  ]
  spec.bindir        = "exe"
  spec.executables   = ["path_helper"]
  spec.require_paths = [] # No lib directory, this is a standalone script

  # No runtime dependencies - uses only Ruby standard library
end

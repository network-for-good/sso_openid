source 'https://rubygems.org'

# Declare your gem's dependencies in sso_openid.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

# Pin transitive dependencies to patched versions to resolve SCA findings
# (NFG-4216). These are indirect dependencies of the gemspec dependencies
# that ship versions vulnerable to the CVEs listed below.
gem 'rack', '= 2.2.24'            # CVE-2025-46727, CVE-2025-59830, CVE-2026-34830
gem 'thor', '= 1.4.0'             # CVE-2025-54314
gem 'addressable', '= 2.9.0'      # CVE-2026-35611
gem 'faraday', '= 2.14.3'         # CVE-2026-54297
gem 'websocket-driver', '= 0.8.2' # CVE-2026-61666


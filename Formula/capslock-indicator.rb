# Homebrew formula for capslock-indicator.
#
# Builds from a pinned git revision rather than GitHub's auto-generated source
# tarball: those tarballs are not byte-stable (their sha256 drifts across CDN
# nodes), which would make `brew install` fail intermittently. A git tag +
# revision is immutable and needs no sha256.
#
# To cut a new version: push a tag, then update `tag` and `revision` below.
#   git rev-parse vX.Y.Z^{commit}
#
# Publish this file in a tap repo named `homebrew-tap`; users then run:
#   brew install spacegauch0/tap/capslock-indicator
class CapslockIndicator < Formula
  desc "Claude Code agent status indicator using keyboard LEDs"
  homepage "https://github.com/spacegauch0/capslock-indicator"
  url "https://github.com/spacegauch0/capslock-indicator.git",
      tag:      "v0.1.0",
      revision: "3a9db387e566a552bc5c9313f2043533c518566c"
  version "0.1.0"
  license "MIT"
  head "https://github.com/spacegauch0/capslock-indicator.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "capslock-indicator", shell_output("#{bin}/capslock-indicator --help")
    assert_predicate bin/"capslock-indicator", :exist?
  end
end

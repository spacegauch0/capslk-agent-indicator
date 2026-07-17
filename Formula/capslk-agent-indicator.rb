# Homebrew formula for capslk-agent-indicator.
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
#   brew install spacegauch0/tap/capslk-agent-indicator
class CapslkAgentIndicator < Formula
  desc "Claude Code agent status indicator using keyboard LEDs"
  homepage "https://github.com/spacegauch0/capslk-agent-indicator"
  url "https://github.com/spacegauch0/capslk-agent-indicator.git",
      tag:      "v0.2.0",
      revision: "7c2a1761f28861a1e11beb85aa7b6eae86295cf0"
  version "0.2.0"
  license "MIT"
  head "https://github.com/spacegauch0/capslk-agent-indicator.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "capslock-indicator", shell_output("#{bin}/capslock-indicator --help")
    assert_predicate bin/"capslock-indicator", :exist?
  end
end

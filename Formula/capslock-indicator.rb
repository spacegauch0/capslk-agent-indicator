# Homebrew formula for capslock-indicator.
#
# After tagging a release (e.g. v0.1.0), fill in `sha256` with:
#   curl -sL https://github.com/spacegauch0/capslock-indicator/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
#
# Publish this file in a tap repo named `homebrew-tap`, then users run:
#   brew install spacegauch0/tap/capslock-indicator
class CapslockIndicator < Formula
  desc "Claude Code agent status indicator using keyboard LEDs"
  homepage "https://github.com/spacegauch0/capslock-indicator"
  url "https://github.com/spacegauch0/capslock-indicator/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"
  head "https://github.com/spacegauch0/capslock-indicator.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "capslock-indicator", shell_output("#{bin}/capslock-indicator --help")
    # `status` exits cleanly and prints on/off/unknown on a headless runner.
    assert_predicate bin/"capslock-indicator", :exist?
  end
end

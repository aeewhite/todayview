class Todayview < Formula
  desc "View the days events from OS X System Calendar"
  homepage "https://github.com/aeewhite/todayview"
  url "https://github.com/aeewhite/todayview/archive/0.2.tar.gz"
  sha256 "9d12fb2efac90dca2ab24ad9e9f5c4988f74a868a5d705d32c9fa3fd4015a24f"
  head "https://github.com/aeewhite/todayview.git"

  depends_on :xcode => :build

  def install
    system "make", "-s"
    bin.install "todayview"
  end

  test do
    system "#{bin}/todayview", "-h"
  end
end

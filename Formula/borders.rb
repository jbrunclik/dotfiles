# JankyBorders, patched so the border windows stay out of screen-share
# pickers. Each border is a separate window owned by `borders`, so Zoom's
# "Windows" list showed a blank "borders" tile for every open window
# (upstream: FelixKratz/JankyBorders#31, #166, closed as Zoom's to fix).
#
# The patch below:
# - lifts the border windows from layer 0 to 1. Zoom lists only layer-0
#   windows, and ignores sharing state. The catch: a border now draws over
#   any normal window covering its target, not under it.
# - turns off sharing for them, which keeps the border out of screenshots,
#   recordings and full-screen shares too.
#
# Otherwise this is the upstream formula (felixkratz/formulae). To update,
# bump url and sha256 to the new tag; if the patch no longer applies,
# regenerate it against that tag.
class Borders < Formula
  desc "Window border system for macOS"
  homepage "https://github.com/FelixKratz/JankyBorders"
  url "https://github.com/FelixKratz/JankyBorders/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "70b5bff531b67a082cc0108d88a8355ba5e7c8326285533143c185efdf21769f"
  license "GPL-3.0-only"

  env :std

  patch :DATA

  def install
    # The makefile sets its own flags
    ENV.delete("CFLAGS")
    ENV.delete("LDFLAGS")
    ENV.delete("CXXFLAGS")
    system "make"
    system "codesign", "--force", "-s", "-", "bin/borders"
    bin.install "bin/borders"
    man1.install "docs/borders.1"
  end

  service do
    run opt_bin/"borders"
    environment_variables PATH: std_service_path_env, LANG: "en_US.UTF-8"
    keep_alive true
    process_type :interactive
    log_path var/"log/borders/borders.out.log"
    error_log_path var/"log/borders/borders.err.log"
  end

  test do
    assert_path_exists bin/"borders"
  end
end

__END__
diff --git a/src/border.c b/src/border.c
index 0c0a28e..5bb4fc1 100644
--- a/src/border.c
+++ b/src/border.c
@@ -193,6 +193,7 @@ void border_update_internal(struct border* border, struct settings* settings) {
   } 
 
   int level = window_level(cid, border->target_wid);
+  if (level == 0) level = 1;
   int sub_level = window_sub_level(cid, border->target_wid);
 
   if (!border->wid) {
diff --git a/src/misc/extern.h b/src/misc/extern.h
index b41137b..e9d5671 100644
--- a/src/misc/extern.h
+++ b/src/misc/extern.h
@@ -20,6 +20,7 @@ extern CGError SLSReleaseConnection(int cid);
 extern CGError SLSWindowIsOrderedIn(int cid, uint32_t wid, bool* shown);
 extern CGError SLSGetWindowBounds(int cid, uint32_t wid, CGRect *frame);
 extern CGError CGSNewRegionWithRect(CGRect *rect, CFTypeRef *outRegion);
+extern CGError SLSSetWindowSharingState(int cid, uint32_t wid, int state);
 extern CGError SLSNewWindow(int cid, int type, float x, float y, CFTypeRef region, uint32_t *wid);
 extern CGError SLSNewWindowWithOpaqueShapeAndContext(int cid, int type, CFTypeRef region, CFTypeRef opaque_shape, int options, uint64_t *tags, float x, float y, int tag_size, uint32_t *wid, void *context);
 extern CGError SLSReleaseWindow(int cid, uint32_t wid);
diff --git a/src/misc/window.h b/src/misc/window.h
index 6203f3d..bb2f6db 100644
--- a/src/misc/window.h
+++ b/src/misc/window.h
@@ -266,6 +266,7 @@ static inline uint32_t window_create(int cid, CGRect frame, bool hidpi, bool unm
   SLSSetWindowTags(cid, wid, &set_tags, 64);
   SLSClearWindowTags(cid, wid, &clear_tags, 64);
   SLSSetWindowOpacity(cid, wid, 0);
+  SLSSetWindowSharingState(cid, wid, kCGWindowSharingNone);
 
   CFIndex shadow_density = 0;
   CFNumberRef shadow_density_cf = CFNumberCreate(kCFAllocatorDefault,

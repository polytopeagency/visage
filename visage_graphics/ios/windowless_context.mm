/* iOS windowless context — provides a CAMetalLayer for offscreen rendering
 * MIT License (same as parent project)
 */

#include "windowless_context.h"

#import <MetalKit/MetalKit.h>

namespace visage {
  class WindowlessMetalLayer {
  public:
    static CAMetalLayer* layer() { return instance().metal_layer_; }

  private:
    static WindowlessMetalLayer& instance() {
      static WindowlessMetalLayer instance;
      return instance;
    }

    WindowlessMetalLayer() {
      metal_layer_ = [CAMetalLayer layer];
      metal_layer_.device = MTLCreateSystemDefaultDevice();
      metal_layer_.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }

    CAMetalLayer* metal_layer_ = nullptr;
  };

  void* windowlessContext() {
    return (__bridge void*)WindowlessMetalLayer::layer();
  }
}

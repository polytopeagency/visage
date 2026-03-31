/* iOS Windowing for Visage — CAMetalLayer-based rendering
 * MIT License (same as parent project)
 */

#pragma once

#if VISAGE_IOS
#include "windowing.h"

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

namespace visage {
  class WindowIOS;
}

@interface VisageIOSView : MTKView
@property(nonatomic) visage::WindowIOS* visage_window;
- (instancetype)initWithFrame:(CGRect)frame inWindow:(visage::WindowIOS*)window;
@end

@interface VisageIOSViewDelegate : NSObject <MTKViewDelegate>
@property(nonatomic) visage::WindowIOS* visage_window;
@property long long start_microseconds;
@end

namespace visage {
  class WindowIOS : public Window {
  public:
    WindowIOS(int width, int height, float scale, void* parent_handle);
    ~WindowIOS() override;

    void* nativeHandle() const override { return (__bridge void*)view_; }
    void* initWindow() const override;

    void runEventLoop() override {}  // iOS uses CADisplayLink via MTKView, not manual loop
    void windowContentsResized(int width, int height) override;
    void show() override;
    void showMaximized() override { show(); }
    void hide() override;
    void close() override;
    bool isShowing() const override;

    void setWindowTitle(const std::string& title) override {}
    IPoint maxWindowDimensions() const override;
    void setAlwaysOnTop(bool on_top) override {}

    void handleNativeResize(int width, int height);

  private:
    UIView* parent_view_ = nullptr;
    VisageIOSView* view_ = nullptr;
    VisageIOSViewDelegate* view_delegate_ = nullptr;
  };
}

#endif

/* iOS Windowing for Visage — CAMetalLayer-based rendering
 * MIT License (same as parent project)
 */

#if VISAGE_IOS

#include "windowing_ios.h"
#include "visage_utils/time_utils.h"

namespace visage {

  // ============================================================================
  // Platform free functions required by windowing.h
  // ============================================================================

  std::string readClipboardText() {
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string)
      return [pasteboard.string UTF8String];
    return "";
  }

  void setClipboardText(const std::string& text) {
    [UIPasteboard generalPasteboard].string = [NSString stringWithUTF8String:text.c_str()];
  }

  void setCursorStyle(MouseCursor style) {
    // No cursor on iOS
  }

  void setCursorVisible(bool visible) {
    // No cursor on iOS
  }

  Point cursorPosition() {
    return { 0.0f, 0.0f };
  }

  void setCursorPosition(Point window_position) {
    // No cursor on iOS
  }

  void setCursorScreenPosition(Point screen_position) {
    // No cursor on iOS
  }

  bool isMobileDevice() {
    return true;
  }

  void showMessageBox(std::string title, std::string message) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString* ns_title = [NSString stringWithUTF8String:title.c_str()];
      NSString* ns_message = [NSString stringWithUTF8String:message.c_str()];
      UIAlertController* alert = [UIAlertController alertControllerWithTitle:ns_title
                                                                    message:ns_message
                                                             preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

      UIWindow* window = nil;
      for (UIScene* scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
          UIWindowScene* ws = (UIWindowScene*)scene;
          window = ws.windows.firstObject;
          break;
        }
      }
      [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
  }

  float defaultDpiScale() {
    return [[UIScreen mainScreen] scale];
  }

  IBounds computeWindowBounds(const Dimension& x, const Dimension& y, const Dimension& w,
                              const Dimension& h) {
    float scale = defaultDpiScale();
    CGRect screen = [[UIScreen mainScreen] bounds];
    int sw = screen.size.width * scale;
    int sh = screen.size.height * scale;
    int width = w.computeInt(scale, sw, sh, 0);
    int height = h.computeInt(scale, sw, sh, 0);
    int xp = x.computeInt(scale, sw, sh, 0);
    int yp = y.computeInt(scale, sw, sh, 0);
    return { xp, yp, width, height };
  }

  std::unique_ptr<Window> createWindow(const Dimension& x, const Dimension& y, const Dimension& width,
                                       const Dimension& height, Window::Decoration decoration) {
    float scale = defaultDpiScale();
    IBounds bounds = computeWindowBounds(x, y, width, height);
    return std::make_unique<WindowIOS>(bounds.width(), bounds.height(), scale, nullptr);
  }

  std::unique_ptr<Window> createPluginWindow(const Dimension& width, const Dimension& height,
                                             void* parent_handle) {
    float scale = defaultDpiScale();
    IBounds bounds = computeWindowBounds({}, {}, width, height);
    return std::make_unique<WindowIOS>(bounds.width(), bounds.height(), scale, parent_handle);
  }

  void closeApplication() {
    // iOS apps don't programmatically exit
  }

  // ============================================================================
  // VisageIOSViewDelegate — MTKViewDelegate for render callbacks
  // ============================================================================

} // namespace visage (close for ObjC implementations)

@implementation VisageIOSViewDelegate

- (instancetype)init {
  self = [super init];
  self.start_microseconds = visage::time::microseconds();
  return self;
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
  if (self.visage_window) {
    int w = static_cast<int>(size.width);
    int h = static_cast<int>(size.height);
    self.visage_window->handleNativeResize(w, h);
  }
}

- (void)drawInMTKView:(MTKView*)view {
  if (!self.visage_window)
    return;

  long long now = visage::time::microseconds();
  double seconds = (now - self.start_microseconds) / 1000000.0;
  self.visage_window->drawCallback(seconds);
}

@end

// ============================================================================
// VisageIOSView — MTKView subclass with touch handling
// ============================================================================

@implementation VisageIOSView

- (instancetype)initWithFrame:(CGRect)frame inWindow:(visage::WindowIOS*)window {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  self = [super initWithFrame:frame device:device];
  if (self) {
    self.visage_window = window;
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    self.sampleCount = 1;
    self.preferredFramesPerSecond = 30;  // iPad power-efficient default
    self.multipleTouchEnabled = YES;
    self.userInteractionEnabled = YES;
    self.layer.opaque = YES;
  }
  return self;
}

+ (Class)layerClass {
  return [CAMetalLayer class];
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  if (!self.visage_window) return;
  for (UITouch* touch in touches) {
    CGPoint loc = [touch locationInView:self];
    float scale = self.contentScaleFactor;
    int x = static_cast<int>(loc.x * scale);
    int y = static_cast<int>(loc.y * scale);
    self.visage_window->handleMouseDown(visage::kMouseButtonLeft, x, y, 0, 0);
  }
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  if (!self.visage_window) return;
  for (UITouch* touch in touches) {
    CGPoint loc = [touch locationInView:self];
    float scale = self.contentScaleFactor;
    int x = static_cast<int>(loc.x * scale);
    int y = static_cast<int>(loc.y * scale);
    self.visage_window->handleMouseMove(x, y, visage::kMouseButtonLeft, 0);
  }
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  if (!self.visage_window) return;
  for (UITouch* touch in touches) {
    CGPoint loc = [touch locationInView:self];
    float scale = self.contentScaleFactor;
    int x = static_cast<int>(loc.x * scale);
    int y = static_cast<int>(loc.y * scale);
    self.visage_window->handleMouseUp(visage::kMouseButtonLeft, x, y, 0, 0);
  }
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  [self touchesEnded:touches withEvent:event];
}

@end

namespace visage {

  // ============================================================================
  // WindowIOS — Window implementation for iOS
  // ============================================================================

  WindowIOS::WindowIOS(int width, int height, float scale, void* parent_handle)
      : Window(width, height) {
    parent_view_ = (__bridge UIView*)parent_handle;

    CGRect frame = CGRectMake(0, 0, width / scale, height / scale);
    view_ = [[VisageIOSView alloc] initWithFrame:frame inWindow:this];
    view_.contentScaleFactor = scale;

    view_delegate_ = [[VisageIOSViewDelegate alloc] init];
    view_delegate_.visage_window = this;
    view_.delegate = view_delegate_;

    if (parent_view_) {
      [parent_view_ addSubview:view_];
      view_.frame = parent_view_.bounds;
      view_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    setDpiScale(scale);
  }

  WindowIOS::~WindowIOS() {
    if (view_) {
      [view_ removeFromSuperview];
      view_.delegate = nil;
      view_ = nil;
    }
    view_delegate_ = nil;
  }

  void* WindowIOS::initWindow() const {
    return (__bridge void*)view_.device;
  }

  void WindowIOS::windowContentsResized(int width, int height) {
    handleResized(width, height);
  }

  void WindowIOS::show() {
    if (view_)
      view_.hidden = NO;
    handleWindowShown();
  }

  void WindowIOS::hide() {
    if (view_)
      view_.hidden = YES;
    handleWindowHidden();
  }

  void WindowIOS::close() {
    hide();
  }

  bool WindowIOS::isShowing() const {
    return view_ && !view_.hidden;
  }

  IPoint WindowIOS::maxWindowDimensions() const {
    UIScreen* screen = [UIScreen mainScreen];
    CGRect bounds = screen.bounds;
    float scale = screen.scale;
    return { static_cast<int>(bounds.size.width * scale),
             static_cast<int>(bounds.size.height * scale) };
  }

  void WindowIOS::handleNativeResize(int width, int height) {
    handleResized(width, height);
  }

} // namespace visage

#endif // VISAGE_IOS

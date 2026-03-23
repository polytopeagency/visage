/* Windowless rendering context for Windows (DirectX 11/12)
 *
 * Creates a hidden 1x1 HWND that bgfx can bind to for offscreen rendering.
 * This is the Windows equivalent of macOS's CAMetalLayer windowless context.
 */

#include "../windowless_context.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace visage {
  class WindowlessHwnd {
  public:
    static HWND hwnd() { return instance().hwnd_; }

  private:
    static WindowlessHwnd& instance() {
      static WindowlessHwnd instance;
      return instance;
    }

    WindowlessHwnd() {
      WNDCLASSEXW wc = {};
      wc.cbSize = sizeof(WNDCLASSEXW);
      wc.lpfnWndProc = DefWindowProcW;
      wc.hInstance = GetModuleHandleW(nullptr);
      wc.lpszClassName = L"VisageWindowlessContext";

      RegisterClassExW(&wc);

      hwnd_ = CreateWindowExW(0, wc.lpszClassName, L"", 0,
                              0, 0, 1, 1,
                              HWND_MESSAGE, nullptr, wc.hInstance, nullptr);
    }

    ~WindowlessHwnd() {
      if (hwnd_)
        DestroyWindow(hwnd_);
    }

    HWND hwnd_ = nullptr;
  };

  void* windowlessContext() {
    return static_cast<void*>(WindowlessHwnd::hwnd());
  }
}

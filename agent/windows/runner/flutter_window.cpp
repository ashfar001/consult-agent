#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <algorithm>
#include <cstdint>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

bool ResizeTimerBar(HWND window, int width_dip, int height_dip, bool center) {
  const HMONITOR previous = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
  HMONITOR monitor = previous;
  POINT cursor;
  if (center && GetCursorPos(&cursor)) {
    monitor = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  }

  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  RECT current;
  if (!GetMonitorInfo(monitor, &info) || !GetWindowRect(window, &current)) {
    return false;
  }

  // Both the work area and SetWindowPos use physical screen coordinates.
  // Scale the size using the destination monitor, keeping clear of the taskbar.
  const RECT& work = info.rcWork;
  const int dpi = FlutterDesktopGetDpiForMonitor(monitor);
  const LONG width = std::min<LONG>(MulDiv(width_dip, dpi, 96),
                                   work.right - work.left);
  const int height = MulDiv(height_dip, dpi, 96);
  const LONG left = center
      ? work.left + (work.right - work.left - width) / 2
      : std::clamp(current.left, work.left, work.right - width);
  const auto place = [&]() {
    return SetWindowPos(window, nullptr, left, work.top, width, height,
                        SWP_NOACTIVATE | SWP_NOZORDER);
  };
  // A monitor change can apply the WM_DPICHANGED suggested bounds first.
  return place() && (monitor == previous || place());
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter::MethodChannel<> bar_channel(
      flutter_controller_->engine()->messenger(), "consult_agent/timer_bar",
      &flutter::StandardMethodCodec::GetInstance());
  bar_channel.SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "resize") {
      result->NotImplemented();
      return;
    }
    const auto* args = std::get_if<flutter::EncodableList>(call.arguments());
    if (args == nullptr || args->size() != 3) {
      result->Error("invalid_args", "Expected width, height and center.");
      return;
    }
    const auto* width = std::get_if<int32_t>(&(*args)[0]);
    const auto* height = std::get_if<int32_t>(&(*args)[1]);
    const auto* center = std::get_if<bool>(&(*args)[2]);
    if (width == nullptr || height == nullptr || center == nullptr ||
        *width <= 0 || *height <= 0) {
      result->Error("invalid_args", "Invalid timer bar dimensions.");
      return;
    }
    if (!ResizeTimerBar(GetHandle(), *width, *height, *center)) {
      result->Error("resize_failed", "Could not position the timer bar.");
      return;
    }
    result->Success();
  });

  // Window visibility belongs to DesktopWindowService. Showing the native
  // window on the first Flutter frame races its initial hide() call and can
  // leave a blank window over the worker's desktop.
  // Still request a frame so Flutter can paint before Dart shows the prompt.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

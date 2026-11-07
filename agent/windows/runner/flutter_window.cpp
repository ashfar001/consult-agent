#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <algorithm>
#include <cmath>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"

namespace {

constexpr double kDockTabWidthDip = 6;
constexpr double kDockPanelWidthDip = 400;
constexpr int kDockHeightDip = 104;
constexpr double kDockOpenMs = 160;
constexpr UINT_PTR kDockAnimationTimer = 0xCA01;
constexpr UINT kDockReposition = WM_APP + 0x101;

}  // namespace

bool FlutterWindow::PlaceTimerDock(HWND window) {
  const HMONITOR previous = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  if (dock_monitor_ == nullptr || !GetMonitorInfo(dock_monitor_, &info)) {
    POINT cursor;
    dock_monitor_ = GetCursorPos(&cursor)
                        ? MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST)
                        : previous;
    if (!GetMonitorInfo(dock_monitor_, &info)) return false;
  }

  // Work area, cursor and SetWindowPos are all in physical screen pixels.
  // Using the target monitor DPI keeps the tab 6 × 104 DIP at every scale.
  const RECT& work = info.rcWork;
  const auto scale = FlutterDesktopGetDpiForMonitor(dock_monitor_) / 96.0;
  const LONG width = std::min<LONG>(
      std::lround(dock_width_dip_ * scale), work.right - work.left);
  const LONG height = std::lround(kDockHeightDip * scale);
  const LONG left = dock_left_ ? work.left : work.right - width;
  const LONG top = work.top + (work.bottom - work.top - height) / 2;

  const auto place = [&]() {
    RECT current;
    if (IsWindowVisible(window) && GetWindowRect(window, &current) &&
        current.left == left && current.top == top &&
        current.right == left + width && current.bottom == top + height) {
      return true;
    }
    return SetWindowPos(window, HWND_TOPMOST, left, top, width, height,
                        SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOOWNERZORDER) !=
           FALSE;
  };
  // A monitor change can apply the WM_DPICHANGED suggested bounds first.
  return place() && (dock_monitor_ == previous || place());
}

void FlutterWindow::AnimateTimerDock(HWND window) {
  const auto elapsed = static_cast<double>(GetTickCount64() - dock_animation_start_);
  const double t = std::min(1.0, elapsed / kDockOpenMs);
  const double remaining = 1 - t;
  const double progress = 1 - remaining * remaining * remaining;
  dock_width_dip_ = kDockTabWidthDip + (kDockPanelWidthDip - kDockTabWidthDip) * progress;
  if (!PlaceTimerDock(window) || t >= 1) KillTimer(window, kDockAnimationTimer);
}

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
    const auto& method = call.method_name();
    const HWND window = GetHandle();
    bool placed = true;
    if (method == "enter" || method == "move") {
      const auto* edge = std::get_if<std::string>(call.arguments());
      if (edge == nullptr || (*edge != "left" && *edge != "right")) {
        result->Error("invalid_args", "Expected a left or right dock edge.");
        return;
      }
      if (method == "enter") {
        KillTimer(window, kDockAnimationTimer);
        dock_active_ = true;
        dock_width_dip_ = kDockTabWidthDip;
      }
      dock_left_ = *edge == "left";
      placed = dock_active_ && PlaceTimerDock(window);
    } else if (method == "leave") {
      dock_active_ = false;
      KillTimer(window, kDockAnimationTimer);
      ShowWindow(window, SW_HIDE);
    } else if (!dock_active_) {
      result->Success();
      return;
    } else if (method == "input") {
      POINT cursor;
      RECT bounds;
      const bool pointer_inside = IsWindowVisible(window) &&
          GetCursorPos(&cursor) && GetWindowRect(window, &bounds) &&
          PtInRect(&bounds, cursor) &&
          GetAncestor(WindowFromPoint(cursor), GA_ROOT) == window;
      const bool keyboard_focus = GetForegroundWindow() == window;
      result->Success(flutter::EncodableValue(flutter::EncodableList{
          flutter::EncodableValue(pointer_inside),
          flutter::EncodableValue(keyboard_focus),
      }));
      return;
    } else if (method == "expand") {
      BOOL animations_enabled = TRUE;
      SystemParametersInfo(SPI_GETCLIENTAREAANIMATION, 0, &animations_enabled, 0);
      dock_animation_start_ = GetTickCount64();
      if (!animations_enabled || !SetTimer(window, kDockAnimationTimer, 16, nullptr)) {
        dock_width_dip_ = kDockPanelWidthDip;
        placed = PlaceTimerDock(window);
      }
    } else if (method == "collapse") {
      KillTimer(window, kDockAnimationTimer);
      dock_width_dip_ = kDockTabWidthDip;
      // Hide invoked by keyboard or click releases focus back to Windows.
      if (GetForegroundWindow() == window) ShowWindow(window, SW_HIDE);
      placed = PlaceTimerDock(window);
    } else {
      result->NotImplemented();
      return;
    }
    if (!placed) {
      result->Error("resize_failed", "Could not position the timer dock.");
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
  if (message == kDockReposition) {
    if (dock_active_) PlaceTimerDock(hwnd);
    return 0;
  }
  if (dock_active_) {
    if (message == WM_TIMER && wparam == kDockAnimationTimer) {
      AnimateTimerDock(hwnd);
      return 0;
    }
    if (message == WM_NCHITTEST) return HTCLIENT;
    if (message == WM_MOUSEACTIVATE && dock_width_dip_ <= kDockTabWidthDip) {
      return MA_NOACTIVATE;
    }
    if (message == WM_DPICHANGED || message == WM_DISPLAYCHANGE ||
        message == WM_SETTINGCHANGE) {
      // Re-anchor after Flutter and Win32 process the new monitor geometry.
      PostMessage(hwnd, kDockReposition, 0, 0);
    }
  }

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
      if (flutter_controller_) flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

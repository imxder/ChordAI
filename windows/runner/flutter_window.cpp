#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Atributos do Windows 11 (build 22000) pra cor da barra de título e do texto
// dela. Definidos aqui caso o SDK do Windows seja mais antigo. No Windows 10 o
// DwmSetWindowAttribute só devolve erro e a barra fica como está.
constexpr DWORD kCaptionColor = 35;  // DWMWA_CAPTION_COLOR
constexpr DWORD kTextColor = 36;     // DWMWA_TEXT_COLOR

// O Flutter manda a cor como 0xAARRGGBB; o Windows quer 0x00BBGGRR.
COLORREF ToColorRef(int64_t argb) {
  const auto value = static_cast<uint32_t>(argb);
  return RGB((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF);
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

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "chordai/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() != "setTitleBarColors") {
          result->NotImplemented();
          return;
        }
        const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (args == nullptr) {
          result->Error("args", "Esperava background e text.");
          return;
        }
        auto color = [args](const char* key) -> std::optional<COLORREF> {
          auto it = args->find(flutter::EncodableValue(key));
          if (it == args->end()) return std::nullopt;
          return ToColorRef(it->second.LongValue());
        };
        HWND hwnd = GetHandle();
        if (auto background = color("background")) {
          DwmSetWindowAttribute(hwnd, kCaptionColor, &*background,
                                sizeof(COLORREF));
        }
        if (auto text = color("text")) {
          DwmSetWindowAttribute(hwnd, kTextColor, &*text, sizeof(COLORREF));
        }
        result->Success();
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
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

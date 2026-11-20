#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Tamanhos em pixels lógicos (com zoom de 150% no Windows, a janela fica
  // 1,5x maior). 1200 x 800 dá folga pro layout de computador; 800 x 560
  // ainda cabe num notebook 1366 x 768 com zoom de 125%.
  constexpr unsigned int kInitialWidth = 1200;
  constexpr unsigned int kInitialHeight = 800;
  constexpr unsigned int kMinimumWidth = 800;
  constexpr unsigned int kMinimumHeight = 560;

  // Abre centralizada na área livre do monitor principal (sem a barra de
  // tarefas). Se a tela for menor que 1200 x 800, a janela diminui até caber.
  HMONITOR monitor = ::MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitor_info = {sizeof(MONITORINFO)};
  ::GetMonitorInfo(monitor, &monitor_info);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const RECT work = monitor_info.rcWork;
  const unsigned int work_width =
      static_cast<unsigned int>((work.right - work.left) / scale);
  const unsigned int work_height =
      static_cast<unsigned int>((work.bottom - work.top) / scale);
  const unsigned int width = std::min(kInitialWidth, work_width);
  const unsigned int height = std::min(kInitialHeight, work_height);
  Win32Window::Point origin(
      static_cast<unsigned int>(work.left / scale) + (work_width - width) / 2,
      static_cast<unsigned int>(work.top / scale) + (work_height - height) / 2);
  Win32Window::Size size(width, height);

  FlutterWindow window(project);
  window.SetMinimumSize(Win32Window::Size(kMinimumWidth, kMinimumHeight));
  if (!window.Create(L"ChordAI", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

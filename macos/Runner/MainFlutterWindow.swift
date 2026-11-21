import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  static let titleBarHeight: CGFloat = 28

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = .clear

    let container = TranslucentContainerViewController()
    self.contentViewController = container
    container.addChild(flutterViewController)
    flutterViewController.view.frame = container.view.bounds
    flutterViewController.view.autoresizingMask = [.width, .height]
    container.view.addSubview(flutterViewController.view)

    let dragStrip = TitleBarDragStrip()
    dragStrip.frame = NSRect(
      x: 0, y: container.view.bounds.height - Self.titleBarHeight,
      width: container.view.bounds.width, height: Self.titleBarHeight)
    dragStrip.autoresizingMask = [.width, .minYMargin]
    container.view.addSubview(dragStrip)

    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    let initial = NSSize(width: 1200, height: 800)
    let minimum = NSSize(width: 800, height: 560)
    let visible = self.screen?.visibleFrame.size ?? initial
    self.setContentSize(
      NSSize(width: min(initial.width, visible.width), height: min(initial.height, visible.height)))
    self.contentMinSize = minimum
    self.title = "ChordAI"
    self.center()

    let channel = FlutterMethodChannel(
      name: "chordai/window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setAppearance",
        let args = call.arguments as? [String: Any],
        let dark = args["dark"] as? Bool
      {
        self?.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

class TranslucentContainerViewController: NSViewController {
  override func loadView() {
    let background = NSVisualEffectView()
    background.material = .sidebar
    background.blendingMode = .behindWindow
    background.state = .followsWindowActiveState
    background.frame = NSRect(x: 0, y: 0, width: 1200, height: 800)
    self.view = background
  }
}

class TitleBarDragStrip: NSView {
  override var mouseDownCanMoveWindow: Bool { true }

  override func mouseDown(with event: NSEvent) {
    if event.clickCount == 2 {
      window?.performZoom(nil)
    } else {
      window?.performDrag(with: event)
    }
  }
}

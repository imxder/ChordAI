import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let initial = NSSize(width: 1200, height: 800)
    let minimum = NSSize(width: 800, height: 560)
    let visible = self.screen?.visibleFrame.size ?? initial
    self.setContentSize(
      NSSize(width: min(initial.width, visible.width), height: min(initial.height, visible.height)))
    self.contentMinSize = minimum
    self.title = "ChordAI"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let origin = self.frame.origin
    self.contentViewController = flutterViewController
    // Room for the feed's side panel; narrower windows switch to the phone layout.
    self.setFrame(NSRect(x: origin.x, y: origin.y, width: 1100, height: 760), display: true)
    self.minSize = NSSize(width: 420, height: 560)
    self.title = "AirReply"
    // Closing hides the window instead of releasing it, so the Dock icon can bring it back.
    self.isReleasedWhenClosed = false

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

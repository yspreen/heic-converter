import Foundation
import AppKit

class heic {
	let fileManager = FileManager.default
	let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

	func run() {
		verifyLaunchLocation()
		setupLaunchAgent()
		startMainLoop()
	}

	private func verifyLaunchLocation() {
		let bundlePath = Bundle.main.bundleURL.path
		guard bundlePath.hasPrefix("/Applications/") else {
			showPathWarning()
			exit(EXIT_FAILURE)
		}
	}

	private func showPathWarning() {
		// Replace the AppleScript with native AppKit alert
		NSApplication.shared.setActivationPolicy(.accessory)
		NSApplication.shared.activate(ignoringOtherApps: true)

		let alert = NSAlert()
		alert.messageText = "Launch Error"
		alert.informativeText = "Please run from /Applications"
		alert.addButton(withTitle: "Quit")
		alert.alertStyle = .critical

		alert.runModal()
		NSApp.terminate(nil)
	}

	private func setupLaunchAgent() {
		let launchAgentsDir = fileManager.homeDirectoryForCurrentUser
			.appendingPathComponent("Library/LaunchAgents")

		let plistDest = launchAgentsDir
			.appendingPathComponent("co.spreen.heic.plist")

		guard !fileManager.fileExists(atPath: plistDest.path) else { return }

		do {
			try fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
			let plistURL = Bundle.module.url(forResource: "heic", withExtension: "plist")!
			try fileManager.copyItem(at: plistURL, to: plistDest)

			let loadTask = Process()
			loadTask.launchPath = "/bin/launchctl"
			loadTask.arguments = ["load", plistDest.path]
			loadTask.launch()
		} catch {
			print("Error installing launch agent: \(error)")
			exit(EXIT_FAILURE)
		}
	}

	private func startMainLoop() {
		// Replace with your actual functionality
		self.monitorDownloads()
		Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
			self.monitorDownloads()
		}

		RunLoop.current.run()
	}

	private func monitorDownloads() {
		do {
			let files = try fileManager.contentsOfDirectory(at: downloadsURL,
																											includingPropertiesForKeys: nil)
			print("Current downloads: \(files.map { $0.lastPathComponent })")
		} catch {
			print("Download monitoring error: \(error)")
		}
	}
}

heic().run()

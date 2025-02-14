import AppKit
import Foundation
import ImageIO

class heic {
	let fileManager = FileManager.default
	let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
		.first!

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

		let plistDest =
			launchAgentsDir
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
		Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
			self.monitorDownloads()
		}

		RunLoop.current.run()
	}

	private func hasJPGVersion(for heicURL: URL) -> Bool {
		let jpgPath = heicURL.deletingPathExtension().appendingPathExtension("jpg").path
		return fileManager.fileExists(atPath: jpgPath)
	}

	private func convertHEICtoJPG(at sourceURL: URL) {
		guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
			print("Failed to create image source")
			return
		}

		guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
			let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
				as? [String: Any],
			let orientationNumber = properties[kCGImagePropertyOrientation as String] as? UInt32
		else {
			print("Failed to read HEIC file: \(sourceURL.lastPathComponent)")
			return
		}

		let destination = sourceURL.deletingPathExtension().appendingPathExtension("jpg")
		let destData = NSMutableData()
		guard
			let imageDestination = CGImageDestinationCreateWithData(
				destData,
				"public.jpeg" as CFString,
				1,
				nil
			)
		else {
			print("Failed to create image destination")
			return
		}

		let options: [CFString: Any] = [
			kCGImageDestinationLossyCompressionQuality: 0.85,
			kCGImagePropertyOrientation: orientationNumber,
		]

		CGImageDestinationAddImage(imageDestination, image, options as CFDictionary)

		if CGImageDestinationFinalize(imageDestination) {
			try? destData.write(to: destination, options: .atomic)
			print("Converted: \(sourceURL.lastPathComponent) → \(destination.lastPathComponent)")
		}
	}

	private func monitorDownloads() {
		do {
			let files = try fileManager.contentsOfDirectory(
				at: downloadsURL,
				includingPropertiesForKeys: nil)

			let heicFiles = files.filter { url in
				let ext = url.pathExtension.lowercased()
				return ext == "heic"
			}

			for heicURL in heicFiles {
				if !hasJPGVersion(for: heicURL) {
					convertHEICtoJPG(at: heicURL)
				}
			}
		} catch {
			print("Download monitoring error: \(error)")
		}
	}
}

heic().run()

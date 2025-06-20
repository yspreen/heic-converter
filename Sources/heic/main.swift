import AppKit
import Foundation
import ImageIO

class heic {
	let fileManager = FileManager.default
	let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
		.first!
	let appExecutablePath = URL(fileURLWithPath: "/Applications/heic.app/Contents/MacOS/heic")
	let referenceDate: Date

	init() {
		// Get the modification date of the app executable once during initialization
		if let attributes = try? fileManager.attributesOfItem(atPath: appExecutablePath.path),
			let modDate = attributes[.modificationDate] as? Date
		{
			referenceDate = modDate
		} else {
			// If we can't get the date for some reason, use current time as fallback
			referenceDate = Date()
			print("Warning: Couldn't get app modification date, using current time instead")
		}
	}

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

		while true {
			RunLoop.current.run()
		}
	}

	private func isWebPSupported() -> Bool {
		let supportedTypes = CGImageSourceCopyTypeIdentifiers()
		for i in 0..<CFArrayGetCount(supportedTypes) {
			let typeID = CFArrayGetValueAtIndex(supportedTypes, i)
			let typeString = Unmanaged<CFString>.fromOpaque(typeID!).takeUnretainedValue() as String
			if typeString == "org.webmproject.webp" {
				return true
			}
		}
		return false
	}

	private func hasJPGVersion(for sourceURL: URL) -> Bool {
		let jpgPath = sourceURL.deletingPathExtension().appendingPathExtension("jpg").path
		return fileManager.fileExists(atPath: jpgPath)
	}

	private func convertToJPG(at sourceURL: URL) {
		let fileExtension = sourceURL.pathExtension.lowercased()
		
		// Check if WebP is supported by the system for WebP files
		if fileExtension == "webp" && !isWebPSupported() {
			print("WebP format not supported on this macOS version (requires macOS 11+)")
			return
		}
		
		guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
			print("Failed to create image source for: \(sourceURL.lastPathComponent)")
			return
		}

		guard let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
			print("Failed to read image file: \(sourceURL.lastPathComponent)")
			return
		}

		// Get properties and orientation (with fallback to default)
		let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
		let orientationNumber = properties?[kCGImagePropertyOrientation as String] as? UInt32 ?? 1

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

	private func getDateAdded(forFileAt path: String) -> Date? {
		let path = path.replacingOccurrences(of: "file://", with: "")
		guard let mdItem = MDItemCreate(nil, path as CFString) else {
			print("Could not create MDItem", path)
			return nil
		}

		// Get the date added attribute
		let attribute = MDItemCopyAttribute(mdItem, kMDItemDateAdded)

		// Convert to Date and return
		return attribute as? Date
	}

	private func isFileNewerThanReference(fileURL: URL) -> Bool {
		do {
			let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
			if
				let fileDate = fileAttributes[.creationDate] as? Date,
				fileDate >= referenceDate
			{
				return true
			}
			if
				let fileDate = fileAttributes[.modificationDate] as? Date,
				fileDate >= referenceDate
			{
				return true
			}
			if
				let fileDate = getDateAdded(forFileAt: fileURL.absoluteString),
				fileDate >= referenceDate
			{
				return true
			}


			return false
		} catch {
			print("Error getting file date: \(error)")
			return false
		}
	}

	private func monitorDownloads() {
		do {
			let files = try fileManager.contentsOfDirectory(
				at: downloadsURL,
				includingPropertiesForKeys: nil)

			let supportedFiles = files.filter { url in
				let ext = url.pathExtension.lowercased()
				if ext == "heic" {
					return true
				}
				if ext == "webp" {
					return isWebPSupported()
				}
				return false
			}

			for fileURL in supportedFiles {
				if !hasJPGVersion(for: fileURL) && isFileNewerThanReference(fileURL: fileURL) {
					convertToJPG(at: fileURL)
				}
			}
		} catch {
			print("Download monitoring error: \(error)")
		}
	}
}

heic().run()

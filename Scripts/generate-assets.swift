// Run on macOS from the repository root: swift Scripts/generate-assets.swift
// Bundle rendered library symbols so the board doesn't depend on a simulator/device emoji font download.
import AppKit
let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets.xcassets")
// Read the catalog so image assets and searchable entries cannot drift apart.
let source = try String(contentsOfFile: "Sources/PictureLibrary.swift", encoding: .utf8)
let pattern = try NSRegularExpression(pattern: #"emoji: "([^"]+)""#)
let matches = pattern.matches(in: source, range: NSRange(source.startIndex..., in: source))
let symbols = Array(Set(matches.compactMap { match -> String? in
    guard let range = Range(match.range(at: 1), in: source) else { return nil }
    return String(source[range])
})).sorted()

for symbol in symbols {
    let name = "picture-" + symbol.unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: "-")
    let directory = output.appendingPathComponent(name + ".imageset")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    bitmap.size = NSSize(width: 256, height: 256)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let text = NSAttributedString(string: symbol, attributes: [.font: NSFont(name: "AppleColorEmoji", size: 180) ?? NSFont.systemFont(ofSize: 180)])
    let size = text.size()
    text.draw(at: NSPoint(x: (256 - size.width) / 2, y: (256 - size.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("picture.png"))
    let json = "{\"images\":[{\"filename\":\"picture.png\",\"idiom\":\"universal\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}"
    try json.write(to: directory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}
print("Rendered \(symbols.count) library symbols.")

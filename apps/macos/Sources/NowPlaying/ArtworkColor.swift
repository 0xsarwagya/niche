import AppKit

/// Derives a vivid accent colour from album artwork for tinting the notch. Rather than averaging
/// (which muddies toward grey), it downsamples, buckets colours, rejects near-black / near-white /
/// greys, and picks the most prevalent *saturated* one — then lifts it for the black background.
enum ArtworkColor {
    static func accent(from image: NSImage) -> NSColor? {
        guard let pixels = downsample(image, to: 32) else { return nil }
        return dominantVivid(in: pixels)
    }

    /// Picks the dominant vivid colour from RGBA8 pixels. Internal for testing.
    static func dominantVivid(in pixels: [UInt8]) -> NSColor? {
        var score: [Int: Double] = [:]
        var sum: [Int: (r: Double, g: Double, b: Double, n: Double)] = [:]
        var fallback = (r: 0.0, g: 0.0, b: 0.0, n: 0.0)

        var i = 0
        while i + 3 < pixels.count {
            let r = Double(pixels[i]) / 255
            let g = Double(pixels[i + 1]) / 255
            let b = Double(pixels[i + 2]) / 255
            let a = Double(pixels[i + 3]) / 255
            i += 4
            guard a > 0.5 else { continue }
            fallback = (fallback.r + r, fallback.g + g, fallback.b + b, fallback.n + 1)

            let value = max(r, g, b)
            let saturation = value == 0 ? 0 : (value - min(r, g, b)) / value
            guard value > 0.12, value < 0.92, saturation > 0.22 else { continue }

            let bucket = Int(r * 5) * 36 + Int(g * 5) * 6 + Int(b * 5)
            score[bucket, default: 0] += saturation * saturation
            let prior = sum[bucket] ?? (0, 0, 0, 0)
            sum[bucket] = (prior.r + r, prior.g + g, prior.b + b, prior.n + 1)
        }

        if let best = score.max(by: { $0.value < $1.value })?.key, let acc = sum[best], acc.n > 0 {
            return vivid(NSColor(red: acc.r / acc.n, green: acc.g / acc.n, blue: acc.b / acc.n, alpha: 1))
        }
        guard fallback.n > 0 else { return nil }
        return vivid(NSColor(red: fallback.r / fallback.n, green: fallback.g / fallback.n, blue: fallback.b / fallback.n, alpha: 1))
    }

    /// Lifts saturation and brightness so the accent stays legible on the black notch.
    static func vivid(_ color: NSColor) -> NSColor {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return color }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        rgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return NSColor(
            hue: hue,
            saturation: min(1, max(saturation, 0.55)),
            brightness: min(1, max(brightness, 0.75)),
            alpha: 1
        )
    }

    private static func downsample(_ image: NSImage, to side: Int) -> [UInt8]? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32
        ) else {
            return nil
        }
        rep.size = NSSize(width: side, height: side)
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.current = context
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        context.flushGraphics()
        guard let data = rep.bitmapData else { return nil }
        return Array(UnsafeBufferPointer(start: data, count: side * side * 4))
    }
}

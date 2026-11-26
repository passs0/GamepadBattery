import AppKit
import SwiftUI

@main
struct RenderScreenshots {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.appearance = NSAppearance(named: .darkAqua)

        let mockDevice = ControllerDevice(
            id: "preview_dualsense",
            name: "DualSense Wireless Controller",
            category: "DualSense",
            brand: .playStation,
            batteryLevel: 0.55,
            batteryState: .discharging,
            isAttachedToDevice: false
        )

        // 1. RENDER ACTUAL MENU VIEW POPOVER
        let popoverContent = MenuView(previewControllers: [mockDevice])
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.14, blue: 0.16))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .preferredColorScheme(.dark)

        let popHosting = NSHostingView(rootView: popoverContent)
        popHosting.appearance = NSAppearance(named: .darkAqua)
        let fittingPop = popHosting.fittingSize
        let popSize = CGSize(width: 300, height: fittingPop.height)
        popHosting.frame = NSRect(origin: .zero, size: popSize)
        popHosting.wantsLayer = true
        popHosting.layer?.backgroundColor = NSColor.clear.cgColor
        popHosting.layoutSubtreeIfNeeded()

        let popWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: popSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        popWindow.appearance = NSAppearance(named: .darkAqua)
        popWindow.backgroundColor = .clear
        popWindow.isOpaque = false
        popWindow.hasShadow = false
        popWindow.contentView = popHosting
        popWindow.display()

        let popImg = NSImage(size: popSize)
        if let rep = popHosting.bitmapImageRepForCachingDisplay(in: popHosting.bounds) {
            popHosting.cacheDisplay(in: popHosting.bounds, to: rep)
            popImg.addRepresentation(rep)
        }

        let popPad: CGFloat = 28
        let popCanvasSize = CGSize(width: popSize.width + popPad * 2, height: popSize.height + popPad * 2)
        let popCanvas = NSImage(size: popCanvasSize)
        popCanvas.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.clear(CGRect(origin: .zero, size: popCanvasSize))
            let shadowPath = CGPath(
                roundedRect: CGRect(x: popPad + 1, y: popPad + 1, width: popSize.width - 2, height: popSize.height - 2),
                cornerWidth: 14,
                cornerHeight: 14,
                transform: nil
            )
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: NSColor.black.withAlphaComponent(0.38).cgColor)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.addPath(shadowPath)
            ctx.fillPath()
            ctx.restoreGState()

            popImg.draw(
                in: CGRect(x: popPad, y: popPad, width: popSize.width, height: popSize.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
        }
        popCanvas.unlockFocus()

        if let tiff = popCanvas.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/Users/pascal/.gemini/antigravity/scratch/LifeBar/assets/popover.png"))
            print("Rendered assets/popover.png (\(Int(popSize.width))x\(Int(popSize.height)))")
        }

        // 2. RENDER HUD PILL NOTIFICATION (matching LowBatteryHUDView layout in dark glass)
        let controllerImg = NSImage(contentsOfFile: "/System/Library/PrivateFrameworks/CoreBluetoothUI.framework/Versions/A/Resources/Generic-GameController.png")
        let hudContent = HStack(spacing: 12) {
            if let img = controllerImg {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 26)
            } else {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1.5) {
                Text("Low Battery")
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(.white)

                Text("Plug-in soon to recharge")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.68))
            }

            Spacer(minLength: 10)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 2.2)
                    .frame(width: 26, height: 26)

                Circle()
                    .trim(from: 0, to: 0.06)
                    .stroke(
                        Color(red: 1.0, green: 0.27, blue: 0.23),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 26, height: 26)

                Text("6")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .frame(width: 296, height: 52)
        .background(
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.19, green: 0.19, blue: 0.21),
                                Color(red: 0.13, green: 0.13, blue: 0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Capsule()
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
            }
        )
        .clipShape(Capsule())
        .preferredColorScheme(.dark)

        let hudSize = CGSize(width: 296, height: 52)
        let hudHosting = NSHostingView(rootView: hudContent)
        hudHosting.appearance = NSAppearance(named: .darkAqua)
        hudHosting.frame = NSRect(origin: .zero, size: hudSize)
        hudHosting.wantsLayer = true
        hudHosting.layer?.backgroundColor = NSColor.clear.cgColor
        hudHosting.layoutSubtreeIfNeeded()

        let hudWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: hudSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        hudWindow.appearance = NSAppearance(named: .darkAqua)
        hudWindow.backgroundColor = .clear
        hudWindow.isOpaque = false
        hudWindow.hasShadow = false
        hudWindow.contentView = hudHosting
        hudWindow.display()

        let hudImg = NSImage(size: hudSize)
        if let rep = hudHosting.bitmapImageRepForCachingDisplay(in: hudHosting.bounds) {
            hudHosting.cacheDisplay(in: hudHosting.bounds, to: rep)
            hudImg.addRepresentation(rep)
        }

        let hudPad: CGFloat = 20
        let hudCanvasSize = CGSize(width: hudSize.width + hudPad * 2, height: hudSize.height + hudPad * 2)
        let hudCanvas = NSImage(size: hudCanvasSize)
        hudCanvas.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.clear(CGRect(origin: .zero, size: hudCanvasSize))
            let pillPath = CGPath(
                roundedRect: CGRect(x: hudPad + 1, y: hudPad + 1, width: hudSize.width - 2, height: hudSize.height - 2),
                cornerWidth: 25,
                cornerHeight: 25,
                transform: nil
            )
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: NSColor.black.withAlphaComponent(0.35).cgColor)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.addPath(pillPath)
            ctx.fillPath()
            ctx.restoreGState()

            hudImg.draw(
                in: CGRect(x: hudPad, y: hudPad, width: hudSize.width, height: hudSize.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
        }
        hudCanvas.unlockFocus()

        if let tiff = hudCanvas.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: "/Users/pascal/.gemini/antigravity/scratch/LifeBar/assets/hud.png"))
            print("Rendered assets/hud.png (\(Int(hudSize.width))x\(Int(hudSize.height)))")
        }
    }
}

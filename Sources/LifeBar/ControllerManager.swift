import Foundation
import GameController
import SwiftUI

@MainActor
public final class ControllerManager: ObservableObject {
    public static let shared = ControllerManager()

    @Published public private(set) var controllers: [ControllerDevice] = []
    @Published public var lowBatteryThreshold: Int {
        didSet {
            UserDefaults.standard.set(lowBatteryThreshold, forKey: "lowBatteryThreshold")
            refreshControllers()
        }
    }
    @Published public var showPercentageInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showPercentageInMenuBar, forKey: "showPercentageInMenuBar")
        }
    }

    private var pollTimer: Timer?
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?
    private var alertedControllerIDs: Set<String> = []

    private init() {
        let savedThreshold = UserDefaults.standard.integer(forKey: "lowBatteryThreshold")
        self.lowBatteryThreshold = savedThreshold > 0 ? savedThreshold : 20
        self.showPercentageInMenuBar = UserDefaults.standard.bool(forKey: "showPercentageInMenuBar")

        setupObservers()
        startDiscovery()
        refreshControllers()
    }

    deinit {
        pollTimer?.invalidate()
        if let connectObserver {
            NotificationCenter.default.removeObserver(connectObserver)
        }
        if let disconnectObserver {
            NotificationCenter.default.removeObserver(disconnectObserver)
        }
    }

    private func setupObservers() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshControllers()
            }
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshControllers()
            }
        }
    }

    private func updatePollTimer(hasControllers: Bool) {
        if hasControllers {
            guard pollTimer == nil else { return }
            pollTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshControllers()
                }
            }
        } else {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    public func startDiscovery() {
        GCController.startWirelessControllerDiscovery()
    }

    public func refreshControllers() {
        let gcList = GCController.controllers()
        var updated: [ControllerDevice] = []

        for (index, c) in gcList.enumerated() {
            let name = c.vendorName ?? "Wireless Game Controller"
            let category = c.productCategory
            let brand = ControllerDevice.detectBrand(name: name, category: category)
            let id = "\(name)_\(index)"

            let level = c.battery?.batteryLevel
            let state = c.battery?.batteryState ?? .unknown

            let device = ControllerDevice(
                id: id,
                name: name,
                category: category,
                brand: brand,
                batteryLevel: level,
                batteryState: state,
                isAttachedToDevice: c.isAttachedToDevice
            )
            updated.append(device)

            // Check for low battery alert
            checkLowBattery(for: device)
        }

        if updated != self.controllers {
            self.controllers = updated
        }
        updatePollTimer(hasControllers: !updated.isEmpty)
    }

    private func checkLowBattery(for device: ControllerDevice) {
        guard let percent = device.batteryPercent else { return }

        // If charging or above threshold, clear alerted flag
        if device.isCharging || percent > lowBatteryThreshold {
            alertedControllerIDs.remove(device.id)
            return
        }

        // If discharging and percent <= threshold
        if percent <= lowBatteryThreshold && !alertedControllerIDs.contains(device.id) {
            alertedControllerIDs.insert(device.id)
            LowBatteryHUDController.shared.show(
                controllerName: device.name,
                batteryPercent: percent,
                brand: device.brand
            )
        }
    }

    public var statusItemText: String? {
        guard showPercentageInMenuBar, let first = controllers.first, let percent = first.batteryPercent else {
            return nil
        }
        return "\(percent)%"
    }

    public var statusItemTooltip: String {
        if controllers.isEmpty {
            return "Game Controllers (None connected)"
        }
        let list = controllers.map { dev in
            if let p = dev.batteryPercent {
                return "\(dev.name): \(p)%"
            } else {
                return dev.name
            }
        }.joined(separator: "\n")
        return "Connected Game Controllers:\n\(list)"
    }
}

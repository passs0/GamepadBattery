import SwiftUI
import ServiceManagement

public struct MenuView: View {
    @ObservedObject var manager = ControllerManager.shared
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    public var previewControllers: [ControllerDevice]? = nil

    private var activeControllers: [ControllerDevice] {
        previewControllers ?? manager.controllers
    }

    public init(previewControllers: [ControllerDevice]? = nil) {
        self.previewControllers = previewControllers
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
                .opacity(0.4)

            ScrollView(showsIndicators: activeControllers.count > 3) {
                VStack(spacing: 4) {
                    if activeControllers.isEmpty {
                        emptyStateView
                            .padding(.vertical, 14)
                    } else {
                        ForEach(activeControllers) { controller in
                            controllerCard(controller)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .frame(maxHeight: 210)
            .padding(.horizontal, 10)

            Divider()
                .opacity(0.4)

            VStack(alignment: .leading, spacing: 2) {
                MenuToggleRow(
                    icon: "percent",
                    iconColor: .secondary,
                    title: "Show Battery Percentage",
                    isOn: $manager.showPercentageInMenuBar
                )

                HStack(spacing: 10) {
                    Image(systemName: "battery.25")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    Text("Low Battery Alert")
                        .font(.body)

                    Spacer()

                    Picker("", selection: $manager.lowBatteryThreshold) {
                        ForEach([10, 15, 20, 25, 30], id: \.self) { pct in
                            Text("\(pct)%").tag(pct)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

                MenuToggleRow(
                    icon: "arrow.up.right.square",
                    iconColor: .secondary,
                    title: "Open at Login",
                    isOn: Binding(
                        get: { launchAtLogin },
                        set: { newValue in
                            launchAtLogin = newValue
                            setLaunchAtLogin(enabled: newValue)
                        }
                    )
                )
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)

            Divider()
                .opacity(0.4)

            VStack(alignment: .leading, spacing: 2) {
                MenuActionRow(
                    icon: "gearshape",
                    iconColor: .secondary,
                    title: "Game Controller Settings…"
                ) {
                    openGameControllerSettings()
                }

                MenuActionRow(
                    icon: "power",
                    iconColor: .secondary,
                    title: "Quit Gamepad Battery"
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .frame(width: 300)
        .onAppear {
            manager.refreshControllers()
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Game Controllers")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
    }

    // MARK: - Controller Row
    private func controllerCard(_ controller: ControllerDevice) -> some View {
        HStack(spacing: 10) {
            Image(systemName: controller.brand.iconName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(controller.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: controller.batterySymbolName)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            controller.isLowBattery ? .red :
                            (controller.isCharging ? .green : .secondary)
                        )

                    Text(controller.isCharging ? "Charging" : "Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let percent = controller.batteryPercent {
                Text("\(percent)%")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(controller.isLowBattery ? .red : .primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Controllers Connected")
                .font(.body)
                .foregroundColor(.primary.opacity(0.85))

            Text("Connect a Bluetooth controller or plug in via USB")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func openGameControllerSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Game-Controllers-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

// MARK: - Apple Style Menu Components

struct MenuActionRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    let accessory: () -> Accessory

    @State private var isHovered = false

    init(
        icon: String,
        iconColor: Color = .secondary,
        title: String,
        action: @escaping () -> Void,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.action = action
        self.accessory = accessory
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 20)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                accessory()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct MenuToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3.5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

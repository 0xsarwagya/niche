import SwiftUI

/// The preferences window: toggle each notch module, pick an accent, tune the HUD.
struct SettingsView: View {
    @Bindable private var prefs = Preferences.shared

    var body: some View {
        Form {
            Section("Modules") {
                moduleRow("music.note", "Now Playing", "Track, controls, and scrubber", $prefs.showNowPlaying)
                moduleRow("cloud.sun", "Weather", "A glance when the notch is idle", $prefs.showWeather)
                moduleRow("speaker.wave.2", "Volume & Brightness", "Replace the system HUD", $prefs.showHUD)
                moduleRow("battery.25", "Battery alerts", "Charging and low-battery warnings", $prefs.showBattery)
            }

            Section("Accent") {
                Toggle("Custom accent colour", isOn: $prefs.useCustomAccent)
                ColorPicker("Colour", selection: $prefs.customAccent, supportsOpacity: false)
                    .disabled(!prefs.useCustomAccent)
            }

            Section("HUD") {
                LabeledContent("Stay on screen") {
                    HStack {
                        Slider(value: $prefs.hudSeconds, in: 0.8...3, step: 0.1)
                            .frame(width: 160)
                        Text("\(prefs.hudSeconds, specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Motion") {
                Picker("Animation", selection: $prefs.motion) {
                    Text("System").tag(MotionLevel.system)
                    Text("Reduced").tag(MotionLevel.reduced)
                    Text("Expressive").tag(MotionLevel.expressive)
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 470)
    }

    private func moduleRow(_ icon: String, _ title: String, _ subtitle: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

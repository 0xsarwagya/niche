import SwiftUI

/// The preferences window: toggle each notch module, pick an accent, tune the HUD.
struct SettingsView: View {
    @Bindable private var prefs = Preferences.shared

    var body: some View {
        Form {
            Section("Modules") {
                Toggle("Now Playing", isOn: $prefs.showNowPlaying)
                Toggle("Weather glance", isOn: $prefs.showWeather)
                Toggle("Volume & brightness HUD", isOn: $prefs.showHUD)
                Toggle("Battery alerts", isOn: $prefs.showBattery)
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
        .frame(width: 380, height: 400)
    }
}

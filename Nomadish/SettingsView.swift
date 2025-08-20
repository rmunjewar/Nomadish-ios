import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("useMetricSystem") private var useMetricSystem = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("autoClassifyPhotos") private var autoClassifyPhotos = true
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nomadish")
                                .font(.headline)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Preferences") {
                    Toggle("Use Metric System", isOn: $useMetricSystem)
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    Toggle("Auto-classify Photos", isOn: $autoClassifyPhotos)
                }
                
                Section("Map") {
                    NavigationLink(destination: MapSettingsView()) {
                        Label("Map Settings", systemImage: "map")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy & Sharing", systemImage: "lock.shield")
                    }
                }
                
                Section("Help & Support") {
                    Button(action: showTutorial) {
                        Label("Show Tutorial", systemImage: "questionmark.circle")
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: contactSupport) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    .foregroundColor(.primary)
                    
                    Link(destination: URL(string: "https://nomadish.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }
                    
                    Link(destination: URL(string: "https://nomadish.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                Section("Account") {
                    Button(action: resetApp) {
                        Label("Reset App", systemImage: "arrow.clockwise")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: signOut) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func showTutorial() {
        hasSeenWelcome = false
        dismiss()
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@nomadish.app") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetApp() {
        hasSeenWelcome = false
        useMetricSystem = false
        enableNotifications = true
        autoClassifyPhotos = true
        dismiss()
    }
    
    private func signOut() {
        dismiss()
    }
}

struct MapSettingsView: View {
    @AppStorage("defaultMapType") private var defaultMapType = 0
    @AppStorage("showTraffic") private var showTraffic = false
    @AppStorage("showBuildings") private var showBuildings = true
    
    private let mapTypes = ["Standard", "Satellite", "Hybrid"]
    
    var body: some View {
        List {
            Section("Map Display") {
                Picker("Default Map Type", selection: $defaultMapType) {
                    ForEach(0..<mapTypes.count, id: \.self) { index in
                        Text(mapTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Show Traffic", isOn: $showTraffic)
                Toggle("Show Buildings", isOn: $showBuildings)
            }
            
            Section("Map Behavior") {
                Toggle("Auto-center on Location", isOn: .constant(true))
                Toggle("Show Compass", isOn: .constant(true))
                Toggle("Show Scale", isOn: .constant(true))
            }
        }
        .navigationTitle("Map Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @AppStorage("shareLocation") private var shareLocation = false
    @AppStorage("publicProfile") private var publicProfile = false
    @AppStorage("allowFriendRequests") private var allowFriendRequests = true
    
    var body: some View {
        List {
            Section("Location Privacy") {
                Toggle("Share Location with Friends", isOn: $shareLocation)
                Toggle("Public Location Sharing", isOn: $publicProfile)
            }
            
            Section("Social Features") {
                Toggle("Allow Friend Requests", isOn: $allowFriendRequests)
                Toggle("Show Profile to Public", isOn: $publicProfile)
            }
            
            Section("Data Usage") {
                Toggle("Analytics & Improvements", isOn: .constant(true))
                Toggle("Crash Reporting", isOn: .constant(true))
            }
        }
        .navigationTitle("Privacy & Sharing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}

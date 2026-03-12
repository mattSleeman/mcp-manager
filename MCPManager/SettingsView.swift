import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configService: ConfigService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let settings = configService.settings {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Model
                        if let model = settings.model {
                            SettingsSection(title: "Model") {
                                Text(model)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }

                        // Permissions
                        if let perms = settings.permissions {
                            if let allow = perms.allow, !allow.isEmpty {
                                SettingsSection(title: "Allowed Tools") {
                                    ForEach(allow, id: \.self) { rule in
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text(rule)
                                                .font(.system(.caption, design: .monospaced))
                                        }
                                    }
                                }
                            }

                            if let deny = perms.deny, !deny.isEmpty {
                                SettingsSection(title: "Denied Tools") {
                                    ForEach(deny, id: \.self) { rule in
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                            Text(rule)
                                                .font(.system(.caption, design: .monospaced))
                                        }
                                    }
                                }
                            }
                        }

                        // Env
                        if let env = settings.env, !env.isEmpty {
                            SettingsSection(title: "Environment") {
                                ForEach(env.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(key)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text("=")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(value)
                                            .font(.system(.caption, design: .monospaced))
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .frame(maxHeight: 300)
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No settings configured")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("~/.claude/settings.json not found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }

            Divider()

            // Footer toolbar
            HStack {
                Spacer()
                Button {
                    configService.openInEditor(url: configService.settingsFileURL)
                } label: {
                    Label("Open settings.json", systemImage: "square.and.arrow.up")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - SettingsSection

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
    }
}

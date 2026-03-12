import SwiftUI
import SwiftUI
import AppKit

struct ServersView: View {
    @EnvironmentObject var configService: ConfigService
    @State private var expandedServer: String? = nil
    @State private var searchText = ""

    var filteredServers: [MCPServer] {
        if searchText.isEmpty {
            return configService.servers
        }
        return configService.servers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if configService.servers.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No MCP servers configured")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a server or edit ~/.claude.json")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("Search servers...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.callout)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredServers) { server in
                            ServerRowView(
                                server: server,
                                isExpanded: expandedServer == server.id,
                                onToggleExpand: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        expandedServer = expandedServer == server.id ? nil : server.id
                                    }
                                },
                                onEdit: {
                                    openEditWindow(for: server)
                                },
                                onDelete: {
                                    showDeleteConfirmation(for: server)
                                }
                            )
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Bottom toolbar
            HStack {
                Button {
                    openAddWindow()
                } label: {
                    Label("Add Server", systemImage: "plus")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Button {
                    configService.openInEditor(url: configService.claudeJSONFileURL)
                } label: {
                    Label("Open .claude.json", systemImage: "square.and.arrow.up")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Delete Confirmation
    
    private func showDeleteConfirmation(for server: MCPServer) {
        let alert = NSAlert()
        alert.messageText = "Delete Server"
        alert.informativeText = "Are you sure you want to delete '\(server.name)'? This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            configService.removeServer(server)
        }
    }
    
    // MARK: - Window Management
    
    private func openAddWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Add Server"
        window.center()
        window.isReleasedWhenClosed = false
        
        let hostingView = NSHostingView(rootView: 
            AddServerView(onDismiss: {
                window.close()
            }, editingServer: nil)
            .environmentObject(configService)
            .padding()
        )
        
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openEditWindow(for server: MCPServer) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Edit Server"
        window.center()
        window.isReleasedWhenClosed = false
        
        let hostingView = NSHostingView(rootView: 
            AddServerView(onDismiss: {
                window.close()
            }, editingServer: server)
            .environmentObject(configService)
            .padding()
        )
        
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - ServerRowView

struct ServerRowView: View {
    @EnvironmentObject var configService: ConfigService
    let server: MCPServer
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 8) {
                // Expand chevron
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                }
                .buttonStyle(.plain)

                // Server name
                Text(server.name)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Type badge
                TypeBadge(type: server.serverType)

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { server.isEnabled },
                    set: { _ in configService.toggleServer(server) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleExpand)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let cmd = server.displayCommand {
                        DetailRow(label: "Command", value: cmd)
                    }
                    if let url = server.config.url {
                        DetailRow(label: "URL", value: url)
                    }
                    if let env = server.config.env, !env.isEmpty {
                        DetailRow(label: "Env keys", value: env.keys.sorted().joined(separator: ", "))
                    }

                    HStack(spacing: 12) {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 10)
            }
        }
        .background(isExpanded ? Color(NSColor.controlBackgroundColor) : Color.clear)
    }
}

// MARK: - TypeBadge

struct TypeBadge: View {
    let type: ServerType

    var badgeColor: Color {
        switch type {
        case .stdio: return .green
        case .http: return .blue
        case .sse: return .orange
        case .unknown: return .gray
        }
    }

    var body: some View {
        Text(type.rawValue)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(badgeColor.opacity(0.3), lineWidth: 0.5)
            )
    }
}

// MARK: - DetailRow

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(3)
                .textSelection(.enabled)
        }
    }
}

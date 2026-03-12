import Foundation
import AppKit

@MainActor
class ConfigService: ObservableObject {
    @Published var servers: [MCPServer] = []
    @Published var settings: ClaudeSettings? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading = false

    private let claudeJSONURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude.json")
    private let settingsURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")

    // Raw top-level dict so we preserve all unknown fields on write
    private var rawGlobalConfig: [String: Any] = [:]

    private var fileWatcher: DispatchSourceFileSystemObject?
    private var settingsWatcher: DispatchSourceFileSystemObject?
    private var reloadWorkItem: DispatchWorkItem?

    init() {
        loadGlobalConfig()
        loadSettings()
        startFileWatching()
    }

    // MARK: - Load

    func loadGlobalConfig() {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard FileManager.default.fileExists(atPath: claudeJSONURL.path) else {
            rawGlobalConfig = [:]
            servers = []
            return
        }

        do {
            let data = try Data(contentsOf: claudeJSONURL)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "Invalid JSON in ~/.claude.json"
                return
            }
            rawGlobalConfig = dict

            var result: [MCPServer] = []

            // Enabled servers
            if let enabled = dict["mcpServers"] as? [String: Any] {
                for (name, rawVal) in enabled {
                    if let rawCfg = rawVal as? [String: Any] {
                        let server = makeServer(name: name, rawConfig: rawCfg, enabled: true)
                        result.append(server)
                    }
                }
            }

            // Disabled servers (stored under _disabledMcpServers)
            if let disabled = dict["_disabledMcpServers"] as? [String: Any] {
                for (name, rawVal) in disabled {
                    if let rawCfg = rawVal as? [String: Any] {
                        let server = makeServer(name: name, rawConfig: rawCfg, enabled: false)
                        result.append(server)
                    }
                }
            }

            result.sort { $0.name < $1.name }
            servers = result

        } catch {
            errorMessage = "Failed to read ~/.claude.json: \(error.localizedDescription)"
        }
    }

    func loadSettings() {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            settings = nil
            return
        }
        do {
            let data = try Data(contentsOf: settingsURL)
            settings = try JSONDecoder().decode(ClaudeSettings.self, from: data)
        } catch {
            // Non-fatal — settings are display-only
            settings = nil
        }
    }

    // MARK: - Toggle

    func toggleServer(_ server: MCPServer) {
        guard let idx = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[idx].isEnabled.toggle()
        saveGlobalConfig()
    }

    // MARK: - Add

    func addServer(name: String, config: [String: Any]) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let cfgData = (try? JSONSerialization.data(withJSONObject: config)) ?? Data()
        let decoded = (try? JSONDecoder().decode(MCPServerConfig.self, from: cfgData)) ?? MCPServerConfig()
        let server = MCPServer(id: trimmed, config: decoded, rawConfig: config, isEnabled: true)

        // Replace if exists, otherwise append
        if let idx = servers.firstIndex(where: { $0.id == trimmed }) {
            servers[idx] = server
        } else {
            servers.append(server)
        }
        saveGlobalConfig()
    }

    // MARK: - Remove

    func removeServer(_ server: MCPServer) {
        servers.removeAll { $0.id == server.id }
        saveGlobalConfig()
    }

    // MARK: - Save

    func saveGlobalConfig() {
        var enabledDict: [String: Any] = [:]
        var disabledDict: [String: Any] = [:]

        for server in servers {
            if server.isEnabled {
                enabledDict[server.name] = server.rawConfig
            } else {
                disabledDict[server.name] = server.rawConfig
            }
        }

        rawGlobalConfig["mcpServers"] = enabledDict

        if disabledDict.isEmpty {
            rawGlobalConfig.removeValue(forKey: "_disabledMcpServers")
        } else {
            rawGlobalConfig["_disabledMcpServers"] = disabledDict
        }

        do {
            let data = try JSONSerialization.data(
                withJSONObject: rawGlobalConfig,
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: claudeJSONURL, options: .atomic)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Open in Editor

    func openInEditor(url: URL) {
        NSWorkspace.shared.open(url)
    }

    var claudeJSONFileURL: URL { claudeJSONURL }
    var settingsFileURL: URL { settingsURL }

    // MARK: - File Watching

    private func startFileWatching() {
        watchFile(url: claudeJSONURL, watcher: &fileWatcher) { [weak self] in
            self?.debouncedReload()
        }
        
        watchFile(url: settingsURL, watcher: &settingsWatcher) { [weak self] in
            self?.debouncedReloadSettings()
        }
    }
    
    private func watchFile(url: URL, watcher: inout DispatchSourceFileSystemObject?, onChange: @escaping () -> Void) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        source.setEventHandler(handler: onChange)
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }
    
    private func debouncedReload() {
        reloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.loadGlobalConfig()
        }
        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func debouncedReloadSettings() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadSettings()
        }
    }

    // MARK: - Helpers

    private func makeServer(name: String, rawConfig: [String: Any], enabled: Bool) -> MCPServer {
        let data = (try? JSONSerialization.data(withJSONObject: rawConfig)) ?? Data()
        let decoded = (try? JSONDecoder().decode(MCPServerConfig.self, from: data)) ?? MCPServerConfig()
        return MCPServer(id: name, config: decoded, rawConfig: rawConfig, isEnabled: enabled)
    }
}

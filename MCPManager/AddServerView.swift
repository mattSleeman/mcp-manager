import SwiftUI

struct AddServerView: View {
    @EnvironmentObject var configService: ConfigService
    var onDismiss: () -> Void
    var editingServer: MCPServer?

    @State private var name = ""
    @State private var serverTypeIndex = 0  // 0=stdio, 1=http, 2=sse
    @State private var command = ""
    @State private var args = ""
    @State private var url = ""
    @State private var envVars: [EnvVar] = []

    private var serverTypes = ["Local (stdio)", "HTTP", "SSE"]
    
    struct EnvVar: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }
    
    init(onDismiss: @escaping () -> Void, editingServer: MCPServer? = nil) {
        self.onDismiss = onDismiss
        self.editingServer = editingServer
        
        if let server = editingServer {
            _name = State(initialValue: server.name)
            _serverTypeIndex = State(initialValue: server.serverType == .stdio ? 0 : server.serverType == .http ? 1 : 2)
            _command = State(initialValue: server.config.command ?? "")
            _args = State(initialValue: server.config.args?.joined(separator: " ") ?? "")
            _url = State(initialValue: server.config.url ?? "")
            _envVars = State(initialValue: (server.config.env ?? [:]).map { EnvVar(key: $0.key, value: $0.value) }.sorted { $0.key < $1.key })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(editingServer == nil ? "Add Server" : "Edit Server")
                .font(.headline)
                .padding(.bottom, 2)

            // Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.caption).foregroundColor(.secondary)
                TextField("e.g. my-server", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .disabled(editingServer != nil)
            }

            // Type
            VStack(alignment: .leading, spacing: 4) {
                Text("Type").font(.caption).foregroundColor(.secondary)
                Picker("", selection: $serverTypeIndex) {
                    ForEach(0..<serverTypes.count, id: \.self) { i in
                        Text(serverTypes[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Conditional fields
            if serverTypeIndex == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Command").font(.caption).foregroundColor(.secondary)
                    TextField("e.g. npx", text: $command)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arguments (space-separated, use quotes for spaces)").font(.caption).foregroundColor(.secondary)
                    TextField("e.g. -y @modelcontextprotocol/server-filesystem /tmp", text: $args)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL").font(.caption).foregroundColor(.secondary)
                    TextField("e.g. http://localhost:3000", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            // Environment Variables
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Environment Variables").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button {
                        envVars.append(EnvVar(key: "", value: ""))
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                
                if !envVars.isEmpty {
                    ForEach($envVars) { $envVar in
                        HStack(spacing: 4) {
                            TextField("KEY", text: $envVar.key)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 100)
                            
                            Text("=").font(.caption).foregroundColor(.secondary)
                            
                            TextField("value", text: $envVar.value)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                            
                            Button {
                                envVars.removeAll { $0.id == envVar.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Buttons
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button(editingServer == nil ? "Add Server" : "Save Changes") {
                    addServer()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func addServer() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if editingServer == nil && configService.servers.contains(where: { $0.name == trimmedName }) {
            return
        }
        
        if serverTypeIndex == 0 {
            guard !command.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        } else {
            let trimmedURL = url.trimmingCharacters(in: .whitespaces)
            guard !trimmedURL.isEmpty, URL(string: trimmedURL) != nil else { return }
        }
        
        var config: [String: Any] = [:]

        if serverTypeIndex == 0 {
            config["command"] = command.trimmingCharacters(in: .whitespaces)
            let argList = parseArguments(args.trimmingCharacters(in: .whitespaces))
            if !argList.isEmpty {
                config["args"] = argList
            }
        } else {
            config["url"] = url.trimmingCharacters(in: .whitespaces)
        }
        
        let envDict = Dictionary(uniqueKeysWithValues: envVars
            .filter { !$0.key.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { ($0.key.trimmingCharacters(in: .whitespaces), $0.value) })
        
        if !envDict.isEmpty {
            config["env"] = envDict
        }

        configService.addServer(name: trimmedName, config: config)
        onDismiss()
    }
    
    private func parseArguments(_ input: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var escapeNext = false
        
        for char in input {
            if escapeNext {
                current.append(char)
                escapeNext = false
                continue
            }
            
            if char == "\\" {
                escapeNext = true
                continue
            }
            
            if char == "\"" {
                inQuotes.toggle()
                continue
            }
            
            if char == " " && !inQuotes {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                continue
            }
            
            current.append(char)
        }
        
        if !current.isEmpty {
            result.append(current)
        }
        
        return result
    }
}


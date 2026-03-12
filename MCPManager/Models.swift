import Foundation

// MARK: - MCPServerConfig

struct MCPServerConfig: Codable {
    var type: String?
    var command: String?
    var args: [String]?
    var env: [String: String]?
    var url: String?
    var headers: [String: String]?
}

// MARK: - ServerType

enum ServerType: String {
    case stdio = "Local"
    case http = "HTTP"
    case sse = "SSE"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .stdio: return "green"
        case .http: return "blue"
        case .sse: return "orange"
        case .unknown: return "gray"
        }
    }
}

// MARK: - MCPServer

struct MCPServer: Identifiable {
    let id: String  // server name
    var config: MCPServerConfig
    var rawConfig: [String: Any]
    var isEnabled: Bool

    var name: String { id }

    var serverType: ServerType {
        if let t = config.type {
            switch t.lowercased() {
            case "http": return .http
            case "sse": return .sse
            case "stdio": return .stdio
            default: break
            }
        }
        if config.url != nil { return .http }
        if config.command != nil { return .stdio }
        return .unknown
    }

    var displayCommand: String? {
        guard let cmd = config.command else { return nil }
        var parts = [cmd]
        if let args = config.args { parts += args }
        return parts.joined(separator: " ")
    }
}

// MARK: - ClaudeSettings

struct ClaudeSettings: Codable {
    var model: String?
    var permissions: Permissions?
    var env: [String: String]?

    struct Permissions: Codable {
        var allow: [String]?
        var deny: [String]?
    }
}

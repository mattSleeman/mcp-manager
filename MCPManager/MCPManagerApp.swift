import SwiftUI

@main
struct MCPManagerApp: App {
    @StateObject var configService = ConfigService()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(configService)
        } label: {
            Image(systemName: "server.rack")
        }
        .menuBarExtraStyle(.window)
    }
}

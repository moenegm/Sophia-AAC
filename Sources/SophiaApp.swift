import SwiftUI
import SwiftData

@main struct SophiaApp: App {
    private let storage: Result<ModelContainer, Error>
    private let demo = ProcessInfo.processInfo.arguments.contains("--demo")

    init() {
        let isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
        storage = Result {
            if !isDemo {
                let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let schema = Schema([ChildProfile.self, BoardCategory.self, CommunicationCard.self])
            let cloudEnabled = Bundle.main.object(forInfoDictionaryKey: "SophiaCloudSyncEnabled") as? String == "YES"
            let configuration = ModelConfiguration("Sophia", schema: schema,
                isStoredInMemoryOnly: isDemo,
                cloudKitDatabase: cloudEnabled && !isDemo ? .automatic : .none)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if isDemo {
                let profile = ChildProfile(name: "Alex")
                container.mainContext.insert(profile)
                StarterBoard.add(to: profile, in: container.mainContext)
                try container.mainContext.save()
            }
            return container
        }
    }

    var body: some Scene {
        WindowGroup {
            switch storage {
            case .success(let container):
                BoardView(isDemo: demo).modelContainer(container)
            case .failure:
                ContentUnavailableView {
                    Label("Your boards couldn’t be opened", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Please close and reopen Sophia. Your saved data has not been reset or replaced.")
                }
            }
        }
    }
}

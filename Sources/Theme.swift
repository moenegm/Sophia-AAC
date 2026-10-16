import SwiftUI

extension Color {
    static let sophiaInk = Color(red: 0.12, green: 0.23, blue: 0.25)
    static let sophiaTeal = Color(red: 0.16, green: 0.39, blue: 0.36)
    static let sophiaCanvas = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let sophiaTints: [Color] = [
        Color(red: 0.89, green: 0.94, blue: 0.87), Color(red: 0.98, green: 0.90, blue: 0.82),
        Color(red: 0.86, green: 0.93, blue: 0.97), Color(red: 0.96, green: 0.88, blue: 0.89),
        Color(red: 0.92, green: 0.89, blue: 0.97)]
    static func boardTint(_ index: Int) -> Color {
        sophiaTints[((index % sophiaTints.count) + sophiaTints.count) % sophiaTints.count]
    }
}

struct BrandMark: View {
    var body: some View {
        Image(systemName: "bubble.left.and.bubble.right.fill")
            .font(.system(size: 25, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(Color.sophiaTeal, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityHidden(true)
    }
}

struct Picture: View {
    let data: Data?
    var emoji = "💬"
    var libraryID: String? = nil
    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let entry = PictureLibrary.picture(for: libraryID ?? emoji),
                  let symbol = PictureImageStore.image(for: entry) {
            Image(uiImage: symbol).resizable().scaledToFit().padding(8)
        } else {
            Text(emoji).font(.system(size: 64)).minimumScaleFactor(0.6)
        }
    }
}

struct ParentGate: View {
    @Environment(\.dismiss) private var dismiss
    let onUnlock: () -> Void
    @State private var answer = ""
    @State private var incorrect = false
    @FocusState private var answerFocused: Bool
    @State private var a = Int.random(in: 5...9)
    @State private var b = Int.random(in: 3...8)
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("For parents and caregivers", systemImage: "lock.fill").font(.headline)
                    Text("Solve this to open editing and settings.")
                    Text("\(a) + \(b) = ?").font(.largeTitle.bold())
                    TextField("Answer", text: $answer).keyboardType(.numberPad)
                        .accessibilityIdentifier("parentAnswer").focused($answerFocused)
                    if incorrect { Text("Try that again.").foregroundStyle(.red) }
                }
            }
            .navigationTitle("Parent check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Open") {
                        if Int(answer) == a + b { answerFocused = false; onUnlock() }
                        else { incorrect = true }
                    }.accessibilityIdentifier("unlockParent")
                }
            }
        }.presentationDetents([.large])
    }
}

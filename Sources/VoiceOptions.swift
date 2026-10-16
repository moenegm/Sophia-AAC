import SwiftUI
import AVFoundation

@MainActor enum VoiceOptions {
    static func available(for language: String) -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language && isAllowed(identifier: $0.identifier, traits: $0.voiceTraits) }
            .sorted { a, b in
                a.quality.rawValue == b.quality.rawValue ? a.name < b.name : a.quality.rawValue > b.quality.rawValue
            }
    }
    // Apple exposes Novelty as a trait; Eloquence identifies its provider in the voice ID.
    static func isAllowed(identifier: String, traits: AVSpeechSynthesisVoice.Traits) -> Bool {
        !traits.contains(.isNoveltyVoice) && !identifier.lowercased().split(separator: ".").contains("eloquence")
    }
    static func quality(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        default: return "Standard"
        }
    }
    static func resolve(identifier: String?, language: String) -> AVSpeechSynthesisVoice? {
        if let identifier, !identifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: identifier), voice.language == language, isAllowed(identifier: voice.identifier, traits: voice.voiceTraits) {
            return voice
        }
        let choices = available(for: language)
        if let preferred = choices.first(where: { $0.name.lowercased().hasPrefix("samantha") }) ?? choices.first { return preferred }
        guard let fallback = AVSpeechSynthesisVoice(language: language),
              isAllowed(identifier: fallback.identifier, traits: fallback.voiceTraits) else { return nil }
        return fallback
    }
}

struct VoicePicker: View {
    @Binding var identifier: String
    let language: String
    let rate: Double
    @State private var voices: [AVSpeechSynthesisVoice] = []
    @State private var speech = SpeechController()
    var body: some View {
        List {
            Section {
                if voices.isEmpty {
                    Text("No app-compatible voices are currently available for this language on this iPad. Sophia will use the system voice. See the download instructions below.")
                }
                ForEach(voices, id: \.identifier) { voice in
                    HStack(spacing: 14) {
                        Button { identifier = voice.identifier } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.name).font(.headline)
                                    Text(VoiceOptions.quality(voice)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if identifier == voice.identifier { Image(systemName: "checkmark.circle.fill") }
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("select-voice-\(voice.identifier)").accessibilityValue(identifier == voice.identifier ? "Selected" : "Not selected")
                        Button {
                            speech.speak(language == "ar-SA" ? "مرحباً. هذا صوتي." : "Hello. This is my voice. I would like some water.",
                                         rate: rate, language: language, voiceIdentifier: voice.identifier)
                        } label: { Image(systemName: "play.circle.fill").font(.title).padding(6) }
                        .buttonStyle(.borderless).accessibilityLabel("Preview \(voice.name), \(VoiceOptions.quality(voice))")
                    }
                }
            } header: { Text("Available on this iPad") } footer: {
                Text("The selected voice is used for all cards and sentences on this iPad. If it is removed, Sophia uses an available fallback voice for this language.")
            }
            Section("More natural voices") {
                Text("Download additional voices, including Enhanced or Premium versions when offered, in iPad Settings → Accessibility → Read & Speak (called Spoken Content on some versions) → Voices. Return here after the download finishes.")
                Button("Refresh voices", systemImage: "arrow.clockwise") { refresh() }
                Text("Sophia lists voices Apple makes available to apps for the selected language, excluding Eloquence and Novelty. Siri voices cannot be used by this app. Downloaded voices can be used offline; availability varies by language and iPadOS version.").font(.caption).foregroundStyle(.secondary)
            }
            if !identifier.isEmpty && !voices.contains(where: { $0.identifier == identifier }) {
                Text("Your selected voice is unavailable. Sophia is using an available fallback voice.").foregroundStyle(.secondary)
            }
        }.navigationTitle("Choose a voice")
            .task { refresh() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in refresh() }
            .onReceive(NotificationCenter.default.publisher(for: AVSpeechSynthesizer.availableVoicesDidChangeNotification)) { _ in refresh() }
            .onDisappear { speech.stop() }
            .alert("Audio", isPresented: Binding(get: { speech.error != nil }, set: { if !$0 { speech.error = nil } })) {
                Button("OK") { speech.error = nil }
            } message: { Text(speech.error ?? "") }
    }
    private func refresh() { voices = VoiceOptions.available(for: language) }
}

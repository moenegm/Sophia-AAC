import SwiftUI

struct LibraryPictureButton: View {
    let picture: LibraryPicture
    let selected: Bool
    let choose: () -> Void
    var body: some View {
        Button(action: choose) {
            VStack(spacing: 6) {
                Image(picture.assetName).resizable().scaledToFit().frame(height: 64)
                    .padding(8).frame(maxWidth: .infinity)
                    .background(Color.sophiaCanvas, in: RoundedRectangle(cornerRadius: 12))
                HStack(spacing: 3) {
                    Text(picture.name).font(.caption.weight(.medium)).lineLimit(2)
                    if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.sophiaTeal) }
                }.frame(minHeight: 30)
            }
            .padding(7)
            .background(selected ? Color.boardTint(0) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(selected ? Color.sophiaTeal : .clear, lineWidth: 2))
        }.buttonStyle(.plain).foregroundStyle(Color.sophiaInk)
            .accessibilityLabel(picture.name)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("library-picture-\(picture.name)")
    }
}

struct PictureLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    let selectedSymbol: String
    let onSelect: (LibraryPicture) -> Void

    init(initialQuery: String, selectedSymbol: String, onSelect: @escaping (LibraryPicture) -> Void) {
        _query = State(initialValue: initialQuery)
        self.selectedSymbol = selectedSymbol
        self.onSelect = onSelect
    }
    var body: some View {
        NavigationStack {
            let results = PictureLibrary.search(query)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose a picture that represents the message for your child.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                        Button("Show all pictures") { query = "" }
                            .frame(maxWidth: .infinity).buttonStyle(.bordered)
                        Text("You can also go back and choose your own photo.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("\(results.count) pictures").font(.caption).foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 12)], spacing: 12) {
                            ForEach(results) { picture in
                                LibraryPictureButton(picture: picture, selected: selectedSymbol == picture.emoji) {
                                    onSelect(picture)
                                    dismiss()
                                }
                            }
                        }
                    }
                }.padding(20)
            }.navigationTitle("Picture library")
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search pictures, e.g. apple or shoes")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.tint(.sophiaTeal)
    }
}

import SwiftUI

struct TripSouvenirsScreen: View {
    @EnvironmentObject private var store: TripStore
    var tripId: String?
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}

    private var trip: Trip? {
        if let tripId, let match = store.trips.first(where: { $0.id == tripId }) { return match }
        return store.activeTrip
    }

    var body: some View {
        ScreenShell(motif: false) {
            Group {
                if let trip {
                    VStack(spacing: 0) {
                        TripSubpageTopBar(
                            title: "Souvenirs",
                            subtitle: trip.homeDestinationTitle,
                            onBack: onBack
                        )

                        ScrollView(showsIndicators: false) {
                            TripSouvenirsGallery(trip: trip)
                                .padding(.horizontal, 18)
                                .padding(.top, 4)
                                .padding(.bottom, 24)
                        }
                        .tripnestScrollBounceWhenNeeded()
                    }
                } else {
                    missingTripState
                }
            }
        }
        .swipeBack(enabled: true, onBack: onBack)
        .onAppear {
            if let tripId { store.selectTrip(id: tripId) }
        }
    }

    private var missingTripState: some View {
        VStack(spacing: 0) {
            TripSubpageTopBar(title: "Souvenirs", subtitle: "Voyage introuvable", onBack: onBack)
            Spacer()
            TIcon(glyph: .gallery, size: 36, stroke: .tRose)
            Text("Impossible de charger ce voyage.")
                .font(.tText(15, weight: .semibold))
                .padding(.top, 12)
            Spacer()
        }
    }
}

// MARK: - Galerie + texte par photo

private struct SouvenirPhotoEntry: Identifiable {
    let id: Int
    var image: UIImage
    var memory: TripPhotoMemory
}

struct TripSouvenirsGallery: View {
    @EnvironmentObject private var store: TripStore
    let trip: Trip

    @State private var entries: [SouvenirPhotoEntry] = []
    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false
    @State private var editingEntryId: Int?

    @State private var editTitle = ""
    @State private var editCaption = ""
    @State private var editPhotoDate = Date()

    private let maxPhotos = 48
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            addPhotoActions

            if entries.isEmpty {
                TCard(padding: 28) {
                    VStack(spacing: 12) {
                        TIcon(glyph: .gallery, size: 40, stroke: .tRose)
                        Text("Aucune photo pour l’instant")
                            .font(.tText(17, weight: .bold))
                        Text("Ajoute une photo, une date, un titre et une description (150 lignes max).")
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("\(entries.count) photo\(entries.count > 1 ? "s" : "")")
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.tTextMute)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(entries) { entry in
                        photoCard(entry)
                    }
                }
            }
        }
        .onAppear { reloadEntries() }
        .onChange(of: trip.photoCount) { _, _ in reloadEntries() }
        .sheet(isPresented: $showGalleryPicker) {
            GalleryPhotoPicker(
                onImage: { image in
                    showGalleryPicker = false
                    appendPhoto(image)
                },
                onCancel: { showGalleryPicker = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraImagePicker(
                onImage: { image in
                    showCameraPicker = false
                    appendPhoto(image)
                },
                onCancel: { showCameraPicker = false }
            )
        }
        .sheet(isPresented: editSheetBinding) {
            photoEditSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var editSheetBinding: Binding<Bool> {
        Binding(
            get: { editingEntryId != nil },
            set: { if !$0 { editingEntryId = nil } }
        )
    }

    private var photoEditSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let id = editingEntryId, let entry = entries.first(where: { $0.id == id }) {
                        Image(uiImage: entry.image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text("Titre")
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tTextMute)
                        TextField("Titre du souvenir", text: $editTitle)
                            .font(.tText(16, weight: .semibold))
                            .padding(12)
                            .background(fieldBg)

                        Text("Date")
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tTextMute)
                        DatePicker(
                            "",
                            selection: $editPhotoDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                        .tint(.tAccent2)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(fieldBg)

                        HStack {
                            Text("Description")
                                .font(.tText(10, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.tTextMute)
                            Spacer()
                            Text("\(TripPhotoMemory.lineCount(for: editCaption))/\(TripPhotoMemory.maxCaptionLines) lignes")
                                .font(.tText(11, weight: .semibold))
                                .foregroundColor(
                                    TripPhotoMemory.lineCount(for: editCaption) > TripPhotoMemory.maxCaptionLines
                                        ? .tRose : .tTextMute
                                )
                        }
                        TextField(
                            "Raconte ce moment…",
                            text: $editCaption,
                            axis: .vertical
                        )
                        .font(.tText(14))
                        .lineLimit(8...150)
                        .padding(12)
                        .background(fieldBg)
                        .onChange(of: editCaption) { _, newValue in
                            if TripPhotoMemory.lineCount(for: newValue) > TripPhotoMemory.maxCaptionLines {
                                editCaption = TripPhotoMemory.clampedCaption(newValue)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle("Détail photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { editingEntryId = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveEditedPhoto() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.tSurface)
    }

    private var addPhotoActions: some View {
        HStack(spacing: 10) {
            Button { showGalleryPicker = true } label: {
                actionTile(glyph: .gallery, title: "Galerie", subtitle: "Importer", accent: .tRose)
            }
            .buttonStyle(TripnestPressStyle())
            .disabled(entries.count >= maxPhotos)
            .opacity(entries.count >= maxPhotos ? 0.45 : 1)

            Button { showCameraPicker = true } label: {
                actionTile(glyph: .plus, title: "Photo", subtitle: "Appareil", accent: .tAccent2)
            }
            .buttonStyle(TripnestPressStyle())
            .disabled(entries.count >= maxPhotos)
            .opacity(entries.count >= maxPhotos ? 0.45 : 1)
        }
    }

    private func actionTile(glyph: TIcon.Glyph, title: String, subtitle: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TIcon(glyph: glyph, size: 20, stroke: accent)
            Text(title).font(.tText(14, weight: .bold)).foregroundColor(.tText)
            Text(subtitle).font(.tText(11)).foregroundColor(.tTextMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
    }

    private func photoCard(_ entry: SouvenirPhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: entry.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { openEditor(for: entry) }

                Button {
                    deletePhoto(id: entry.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, Color.black.opacity(0.45))
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let date = entry.memory.photoDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.tText(11, weight: .semibold))
                    .foregroundColor(.tRose)
            }

            Text(entry.memory.title.isEmpty ? "Sans titre" : entry.memory.title)
                .font(.tText(14, weight: .bold))
                .foregroundColor(.tText)
                .lineLimit(2)

            if !entry.memory.caption.isEmpty {
                Text(entry.memory.caption)
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .lineLimit(3)
            } else {
                Text("Ajouter titre & description")
                    .font(.tText(11, weight: .semibold))
                    .foregroundColor(.tAccent2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { openEditor(for: entry) }
    }

    private func openEditor(for entry: SouvenirPhotoEntry) {
        editingEntryId = entry.id
        editTitle = entry.memory.title
        editCaption = entry.memory.caption
        editPhotoDate = entry.memory.photoDate ?? Date()
    }

    private func saveEditedPhoto() {
        guard let id = editingEntryId,
              let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].memory.title = String(editTitle.prefix(120))
        entries[index].memory.caption = TripPhotoMemory.clampedCaption(editCaption)
        entries[index].memory.photoDateKey = TripPlanCalendar.dayKey(for: editPhotoDate)
        persistAll()
        editingEntryId = nil
        Haptics.success()
    }

    private func deletePhoto(id: Int) {
        entries.removeAll { $0.id == id }
        reindexEntries()
        persistAll()
        Haptics.selection()
    }

    private func reindexEntries() {
        entries = entries.enumerated().map { offset, entry in
            SouvenirPhotoEntry(id: offset, image: entry.image, memory: entry.memory)
        }
    }

    private func reloadEntries() {
        let images = TripPhotoStore.loadAll(tripId: trip.id, count: trip.photoCount)
        let memories = TripPhotoStore.loadMemories(tripId: trip.id, count: images.count)
        entries = images.enumerated().map { index, image in
            SouvenirPhotoEntry(
                id: index,
                image: image,
                memory: index < memories.count ? memories[index] : TripPhotoMemory()
            )
        }
    }

    private func appendPhoto(_ image: UIImage) {
        guard entries.count < maxPhotos else { return }
        var memory = TripPhotoMemory()
        memory.photoDateKey = TripPlanCalendar.dayKey(for: Date())
        entries.append(SouvenirPhotoEntry(id: entries.count, image: image, memory: memory))
        persistAll()
        Haptics.success()
    }

    private func persistAll() {
        reindexEntries()
        TripPhotoStore.deleteAll(tripId: trip.id, count: max(trip.photoCount, entries.count + 4))
        for (index, entry) in entries.enumerated() {
            TripPhotoStore.save(entry.image, tripId: trip.id, index: index)
        }
        TripPhotoStore.saveMemories(tripId: trip.id, memories: entries.map(\.memory))
        store.updateTripPhotoCount(tripId: trip.id, count: entries.count)
    }
}

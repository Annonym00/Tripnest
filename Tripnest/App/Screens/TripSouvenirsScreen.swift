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
            TripSubpageTopBar(title: "Souvenirs", subtitle: L("Voyage introuvable"), onBack: onBack)
            Spacer()
            TIcon(glyph: .gallery, size: 36, stroke: .tRose)
            Text(L("Impossible de charger ce voyage."))
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
    @State private var pendingCropImage: UIImage? = nil
    @State private var editingEntryId: Int?
    @State private var fullscreenEntry: SouvenirPhotoEntry?

    @State private var editTitle = ""
    @State private var editCaption = ""
    @State private var editPhotoDate = Date()
    @State private var showDatePicker = false
    @State private var photoToDeleteId: Int? = nil

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
                        Text(L("Aucune photo pour l'instant"))
                            .font(.tText(17, weight: .bold))
                        Text(L("Ajoute une photo, une date, un titre et une description (150 lignes max)."))
                            .font(.tText(13))
                            .foregroundColor(.tTextMute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text(entries.count > 1 ? L("%d photos", entries.count) : L("%d photo", entries.count))
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        pendingCropImage = image
                    }
                },
                onCancel: { showGalleryPicker = false }
            )
            .ignoresSafeArea()
        }

        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraImagePicker(
                onImage: { image in
                    showCameraPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        pendingCropImage = image
                    }
                },
                onCancel: { showCameraPicker = false }
            )
        }

        .fullScreenCover(
            isPresented: Binding(
                get: { pendingCropImage != nil },
                set: { if !$0 { pendingCropImage = nil } }
            )
        ) {
            if let img = pendingCropImage {
                SouvenirCropSheet(
                    image: img,
                    onConfirm: { cropped in
                        pendingCropImage = nil
                        appendPhoto(cropped)
                    },
                    onCancel: { pendingCropImage = nil }
                )
            }
        }

        // Sheet édition titre / date / description
        .sheet(isPresented: editSheetBinding) {
            photoEditSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }

        // Affichage plein écran au tap sur l'image
        .fullScreenCover(item: $fullscreenEntry) { entry in
            FullscreenPhotoViewer(entry: entry)
        }

        // Confirmation suppression
        .confirmationDialog(
            L("Supprimer cette photo ?"),
            isPresented: Binding(
                get: { photoToDeleteId != nil },
                set: { if !$0 { photoToDeleteId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L("Supprimer"), role: .destructive) {
                if let id = photoToDeleteId { deletePhoto(id: id) }
                photoToDeleteId = nil
            }
            Button(L("Annuler"), role: .cancel) { photoToDeleteId = nil }
        } message: {
            Text(L("Cette photo sera définitivement supprimée."))
        }
    }

    // MARK: - Edit sheet

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
                        // Aperçu carré dans la sheet d'édition
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(uiImage: entry.image)
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text(L("Titre"))
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tTextMute)
                        TextField(L("Titre du souvenir"), text: $editTitle)
                            .font(.tText(16, weight: .semibold))
                            .padding(12)
                            .background(fieldBg)

                        Text(L("Date"))
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tTextMute)

                        VStack(spacing: 0) {
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.tAccent2)
                                    Text(editPhotoDate.formatted(.dateTime.day().month(.wide).year()))
                                        .font(.tText(15, weight: .semibold))
                                        .foregroundColor(.tText)
                                        .environment(\.locale, Locale(identifier: "fr_FR"))
                                    Spacer()
                                }
                                .padding(14)
                            }
                            .buttonStyle(.plain)

                            if showDatePicker {
                                DatePicker("", selection: $editPhotoDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(.tAccent2)
                                    .environment(\.locale, Locale(identifier: "fr_FR"))
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                            }
                        }
                        .background(fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        HStack {
                            Text(L("Note"))
                                .font(.tText(11, weight: .semibold))
                                .foregroundColor(.tTextMute)
                            Spacer()
                            Text(L("%d/%d lignes", TripPhotoMemory.lineCount(for: editCaption), TripPhotoMemory.maxCaptionLines))
                                .font(.tText(11, weight: .semibold))
                                .foregroundColor(
                                    TripPhotoMemory.lineCount(for: editCaption) > TripPhotoMemory.maxCaptionLines
                                        ? .tRose : .tTextMute
                                )
                        }
                        TextField(
                            L("Raconte ce moment…"),
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Annuler")) { editingEntryId = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Enregistrer")) { saveEditedPhoto() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.tSurface)
    }

    // MARK: - Add actions

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

    // MARK: - Photo card

    private func photoCard(_ entry: SouvenirPhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image carrée propre — tap → plein écran
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(uiImage: entry.image)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { fullscreenEntry = entry }

                // Bouton suppression
                Button {
                    photoToDeleteId = entry.id
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, Color.black.opacity(0.45))
                }
                .buttonStyle(.plain)
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Zone texte — tap → éditeur
            VStack(alignment: .leading, spacing: 4) {
                if let date = entry.memory.photoDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.tText(11, weight: .semibold))
                        .foregroundColor(.tRose)
                        .allowsHitTesting(false)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.memory.title.isEmpty ? L("Sans titre") : entry.memory.title)
                        .font(.tText(14, weight: .bold))
                        .foregroundColor(.tText)
                        .lineLimit(2)

                    if !entry.memory.caption.isEmpty {
                        Text(entry.memory.caption)
                            .font(.tText(12))
                            .foregroundColor(.tTextMute)
                            .lineLimit(3)
                    } else {
                        Text(L("Ajouter titre & description"))
                            .font(.tText(11, weight: .semibold))
                            .foregroundColor(.tAccent2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { openEditor(for: entry) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

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
        let tripId = trip.id
        let count = trip.photoCount
        Task {
            let (images, memories) = await Task.detached(priority: .userInitiated) {
                let imgs = TripPhotoStore.loadAll(tripId: tripId, count: count)
                let mems = TripPhotoStore.loadMemories(tripId: tripId, count: imgs.count)
                return (imgs, mems)
            }.value
            guard tripId == trip.id else { return }
            entries = images.enumerated().map { index, image in
                SouvenirPhotoEntry(
                    id: index,
                    image: image,
                    memory: index < memories.count ? memories[index] : TripPhotoMemory()
                )
            }
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
        let tripId = trip.id
        let snapshot = entries
        let previousCount = trip.photoCount
        let memories = snapshot.map(\.memory)
        Task {
            await Task.detached(priority: .utility) {
                TripPhotoStore.deleteAll(tripId: tripId, count: max(previousCount, snapshot.count + 4))
                for (index, entry) in snapshot.enumerated() {
                    TripPhotoStore.save(entry.image, tripId: tripId, index: index)
                }
                TripPhotoStore.saveMemories(tripId: tripId, memories: memories)
            }.value
            guard tripId == trip.id else { return }
            store.updateTripPhotoCount(tripId: tripId, count: snapshot.count)
        }
    }
}

// MARK: - Recadrage carré

private struct SouvenirCropSheet: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var drag: CGSize = .zero
    @State private var lastDrag: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let base = baseSize(side: side)
            let buttonH: CGFloat = 80 + geo.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: base.width * scale, height: base.height * scale)
                    .offset(drag)
                    .frame(width: side, height: side)
                    .clipped()
                    .contentShape(Rectangle())
                    .frame(width: geo.size.width, height: geo.size.height - buttonH)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { v in scale = max(1, lastScale * v) }
                                .onEnded { _ in
                                    lastScale = scale
                                    clamp(side: side, base: base)
                                },
                            DragGesture()
                                .onChanged { v in
                                    drag = CGSize(
                                        width: lastDrag.width + v.translation.width,
                                        height: lastDrag.height + v.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    clamp(side: side, base: base)
                                }
                        )
                    )

                HStack {
                    Button(L("Annuler"), action: onCancel)
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Button(L("Utiliser")) { confirm(side: side, base: base) }
                        .foregroundColor(.tAccent2)
                        .fontWeight(.bold)
                }
                .font(.system(size: 17))
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                .frame(height: buttonH)
                .background(Color.black)
            }
        }
        .ignoresSafeArea()
    }

    private func baseSize(side: CGFloat) -> CGSize {
        let a = image.size.width / image.size.height
        return a >= 1
            ? CGSize(width: side * a, height: side)
            : CGSize(width: side, height: side / a)
    }

    private func clamp(side: CGFloat, base: CGSize) {
        let maxX = max(0, (base.width * scale - side) / 2)
        let maxY = max(0, (base.height * scale - side) / 2)
        drag = CGSize(
            width: min(maxX, max(-maxX, drag.width)),
            height: min(maxY, max(-maxY, drag.height))
        )
        lastDrag = drag
    }

    private func confirm(side: CGFloat, base: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let cropped = renderer.image { _ in
            let w = base.width * scale
            let h = base.height * scale
            image.draw(in: CGRect(
                x: (side - w) / 2 + drag.width,
                y: (side - h) / 2 + drag.height,
                width: w, height: h
            ))
        }
        onConfirm(cropped)
    }
}

// MARK: - Visionneuse plein écran

private struct FullscreenPhotoViewer: View {
    let entry: SouvenirPhotoEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: entry.image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            // Titre / date en bas
            if !entry.memory.title.isEmpty || entry.memory.photoDate != nil {
                VStack {
                    Spacer()
                    VStack(spacing: 4) {
                        if let date = entry.memory.photoDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.tText(12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if !entry.memory.title.isEmpty {
                            Text(entry.memory.title)
                                .font(.tText(17, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        // Tap simple → fermer immédiatement
        .onTapGesture { dismiss() }
    }
}

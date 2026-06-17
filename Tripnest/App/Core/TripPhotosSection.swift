import SwiftUI

struct TripPhotosSection: View {
    @EnvironmentObject private var store: TripStore
    let trip: Trip

    @State private var photos: [UIImage] = []
    @State private var showGalleryPicker = false
    @State private var showCameraPicker = false

    private let maxPhotos = 24

    var body: some View {
        TCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L("PHOTOS DU VOYAGE"))
                        .font(.tText(10, weight: .bold))
                        .tracking(1.1)
                        .foregroundColor(.tTextMute)
                    Spacer()
                    Text("\(photos.count)/\(maxPhotos)")
                        .font(.tText(11, weight: .semibold))
                        .foregroundColor(.tAccent2)
                }

                if photos.isEmpty {
                    Text(L("Ajoute tes souvenirs : paysages, billets, moments…"))
                        .font(.tText(13))
                        .foregroundColor(.tTextMute)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: photos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Button {
                                    photos.remove(at: index)
                                    persistPhotos()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white, Color.black.opacity(0.5))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }

                        if photos.count < maxPhotos {
                            Menu {
                                Button {
                                    showGalleryPicker = true
                                } label: {
                                    Label(L("Galerie"), systemImage: "photo.on.rectangle.angled")
                                }
                                Button {
                                    showCameraPicker = true
                                } label: {
                                    Label(L("Appareil photo"), systemImage: "camera.fill")
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    TIcon(glyph: .plus, size: 20, stroke: .tAccent2)
                                    Text(L("Ajouter"))
                                        .font(.tText(11, weight: .semibold))
                                        .foregroundColor(.tAccent2)
                                }
                                .frame(width: 96, height: 96)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.tAccent2.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.tAccent2.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                )
                            }
                        }
                    }
                }
            }
        }
        .onAppear { reloadPhotos() }
        .onChange(of: trip.photoCount) { _, _ in reloadPhotos() }
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
    }

    private func reloadPhotos() {
        // Lecture + décodage disque hors main thread : ouvrir un voyage avec des photos
        // ne doit jamais geler l'UI. Les images arrivent dès qu'elles sont prêtes.
        let tripId = trip.id
        let count = trip.photoCount
        Task {
            let loaded = await Task.detached(priority: .userInitiated) {
                TripPhotoStore.loadAll(tripId: tripId, count: count)
            }.value
            guard tripId == trip.id else { return }
            photos = loaded
        }
    }

    private func appendPhoto(_ image: UIImage) {
        guard photos.count < maxPhotos else { return }
        photos.append(image)
        persistPhotos()
        Haptics.success()
    }

    private func persistPhotos() {
        // Encodage JPEG + écritures disque hors main thread (sinon gel à chaque ajout).
        let tripId = trip.id
        let snapshot = photos
        let oldCount = max(trip.photoCount, snapshot.count)
        Task {
            await Task.detached(priority: .utility) {
                TripPhotoStore.deleteAll(tripId: tripId, count: oldCount)
                for (index, photo) in snapshot.enumerated() {
                    TripPhotoStore.save(photo, tripId: tripId, index: index)
                }
            }.value
            guard tripId == trip.id else { return }
            store.updateTripPhotoCount(tripId: tripId, count: snapshot.count)
        }
    }
}

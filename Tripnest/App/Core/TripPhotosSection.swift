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
                    Text("PHOTOS DU VOYAGE")
                        .font(.tText(10, weight: .bold))
                        .tracking(1.1)
                        .foregroundColor(.tTextMute)
                    Spacer()
                    Text("\(photos.count)/\(maxPhotos)")
                        .font(.tText(11, weight: .semibold))
                        .foregroundColor(.tAccent2)
                }

                if photos.isEmpty {
                    Text("Ajoute tes souvenirs : paysages, billets, moments…")
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
                                    Label("Galerie", systemImage: "photo.on.rectangle.angled")
                                }
                                Button {
                                    showCameraPicker = true
                                } label: {
                                    Label("Appareil photo", systemImage: "camera.fill")
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    TIcon(glyph: .plus, size: 20, stroke: .tAccent2)
                                    Text("Ajouter")
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
        photos = TripPhotoStore.loadAll(tripId: trip.id, count: trip.photoCount)
    }

    private func appendPhoto(_ image: UIImage) {
        guard photos.count < maxPhotos else { return }
        photos.append(image)
        persistPhotos()
        Haptics.success()
    }

    private func persistPhotos() {
        TripPhotoStore.deleteAll(tripId: trip.id, count: max(trip.photoCount, photos.count))
        for (index, photo) in photos.enumerated() {
            TripPhotoStore.save(photo, tripId: trip.id, index: index)
        }
        store.updateTripPhotoCount(tripId: trip.id, count: photos.count)
    }
}

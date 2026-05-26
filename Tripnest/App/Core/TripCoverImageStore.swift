import PhotosUI
import SwiftUI
import UIKit

enum TripCoverKind: String, Codable, Hashable {
    /// Fond coloré uniquement (legacy : même rendu que `none`).
    case automatic
    case custom
    case none
}

/// Format fixe des couvertures (carte accueil 16:9) — le recadrage évite les bugs d’affichage.
enum TripCoverLayout {
    static let aspectRatio: CGFloat = 16 / 9
    static let exportPixelSize = CGSize(width: 1280, height: 720)
}

struct PendingCoverCrop: Identifiable {
    let id = UUID()
    let image: UIImage
}

enum TripCoverImageStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("TripCovers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(tripId: String) -> URL {
        directoryURL.appendingPathComponent("\(tripId).jpg")
    }

    @discardableResult
    static func save(_ image: UIImage, tripId: String) -> Bool {
        let normalized = preparedForStorage(image)
        guard let data = normalized.jpegData(compressionQuality: 0.86) else { return false }
        do {
            try data.write(to: fileURL(tripId: tripId), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func load(tripId: String) -> UIImage? {
        let url = fileURL(tripId: tripId)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    static func delete(tripId: String) {
        let url = fileURL(tripId: tripId)
        try? FileManager.default.removeItem(at: url)
    }

    /// Recadre au format carte puis redimensionne pour un rendu identique partout.
    static func preparedForStorage(_ image: UIImage) -> UIImage {
        let upright = image.trip_coverOrientedUp()
        let fitted = upright.trip_coverCenterCropped(toAspect: TripCoverLayout.aspectRatio)
        return fitted.trip_coverResized(to: TripCoverLayout.exportPixelSize)
    }

    static func exportCroppedImage(
        _ image: UIImage,
        cropSizePoints: CGSize,
        userScale: CGFloat,
        offset: CGSize
    ) -> UIImage {
        let upright = image.trip_coverOrientedUp()
        let iw = upright.size.width
        let ih = upright.size.height
        guard iw > 0, ih > 0, cropSizePoints.width > 0, cropSizePoints.height > 0 else {
            return preparedForStorage(image)
        }

        let base = max(cropSizePoints.width / iw, cropSizePoints.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let originX = (cropSizePoints.width - dw) / 2 + offset.width
        let originY = (cropSizePoints.height - dh) / 2 + offset.height

        let visibleW = cropSizePoints.width
        let visibleH = cropSizePoints.height
        let nx = max(0, -originX) / dw
        let ny = max(0, -originY) / dh
        let nw = min(1, visibleW / dw) - nx
        let nh = min(1, visibleH / dh) - ny

        let cropRect = CGRect(
            x: nx * iw,
            y: ny * ih,
            width: max(1, nw * iw),
            height: max(1, nh * ih)
        ).integral

        guard let cg = upright.cgImage?.cropping(to: cropRect) else {
            return preparedForStorage(image)
        }
        let cropped = UIImage(cgImage: cg, scale: upright.scale, orientation: .up)
        return cropped.trip_coverResized(to: TripCoverLayout.exportPixelSize)
    }
}

// MARK: - Recadrage couverture

struct TripCoverCropSheet: View {
    let sourceImage: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var userScale: CGFloat = 1
    @State private var lastUserScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSizePoints: CGSize = .zero

    private var oriented: UIImage { sourceImage.trip_coverOrientedUp() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Pince pour zoomer, glisse pour repositionner.")
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                GeometryReader { geo in
                    let crop = Self.cropFrame(in: geo.size)
                    ZStack {
                        Color.black.opacity(0.92)
                        cropEditor(cropSize: crop)
                    }
                    .onAppear { cropSizePoints = crop }
                    .onChange(of: geo.size) { _, newSize in
                        cropSizePoints = Self.cropFrame(in: newSize)
                    }
                }

                HStack(spacing: 12) {
                    Button("Annuler", action: onCancel)
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)

                    Button {
                        let exported = TripCoverImageStore.exportCroppedImage(
                            oriented,
                            cropSizePoints: cropSizePoints,
                            userScale: userScale,
                            offset: offset
                        )
                        onConfirm(exported)
                    } label: {
                        Text("Utiliser")
                            .font(.tText(15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.tAccent)
                            )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle("Recadrer la couverture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tBg0, for: .navigationBar)
        }
    }

    private func cropEditor(cropSize: CGSize) -> some View {
        let iw = oriented.size.width
        let ih = oriented.size.height
        let base = max(cropSize.width / iw, cropSize.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let clamped = clampedOffset(offset, crop: cropSize, displayW: dw, displayH: dh)

        return ZStack {
            Image(uiImage: oriented)
                .resizable()
                .frame(width: dw, height: dh)
                .offset(clamped)
                .gesture(dragGesture(crop: cropSize, displayW: dw, displayH: dh))
                .simultaneousGesture(magnifyGesture)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                .frame(width: cropSize.width, height: cropSize.height)

            VStack {
                Text("Format carte")
                    .font(.tText(10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .padding(.top, 10)
                Spacer()
            }
            .frame(width: cropSize.width, height: cropSize.height)
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                userScale = min(4, max(1, lastUserScale * value.magnification))
            }
            .onEnded { _ in
                lastUserScale = userScale
            }
    }

    private func dragGesture(crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposed, crop: crop, displayW: displayW, displayH: displayH)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func clampedOffset(_ proposed: CGSize, crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> CGSize {
        let maxX = max(0, (displayW - crop.width) / 2)
        let maxY = max(0, (displayH - crop.height) / 2)
        return CGSize(
            width: min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    private static func cropFrame(in container: CGSize) -> CGSize {
        let maxW = max(0, container.width - 44)
        let maxH = max(0, container.height - 24)
        var w = maxW
        var h = w / TripCoverLayout.aspectRatio
        if h > maxH {
            h = maxH
            w = h * TripCoverLayout.aspectRatio
        }
        return CGSize(width: max(200, w), height: max(112, h))
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    func trip_coverOrientedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func trip_coverCenterCropped(toAspect aspect: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return self }
        let current = w / h
        var crop = CGRect(origin: .zero, size: size)
        if current > aspect {
            let newW = h * aspect
            crop.origin.x = (w - newW) / 2
            crop.size.width = newW
        } else if current < aspect {
            let newH = w / aspect
            crop.origin.y = (h - newH) / 2
            crop.size.height = newH
        }
        crop = crop.integral
        guard let cg = cgImage?.cropping(to: crop) else { return self }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }

    func trip_coverResized(to target: CGSize) -> UIImage {
        guard target.width > 0, target.height > 0 else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Pickers

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onCancel: onCancel) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

/// Sélecteur galerie en sheet — évite le style `.compact` de `PhotosPicker` qui casse la mise en page du formulaire.
struct GalleryPhotoPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onCancel: onCancel) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onCancel()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self.onImage(image)
                    } else {
                        self.onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Photos de voyage (galerie)

enum TripPhotoStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("TripPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(tripId: String, index: Int) -> URL {
        directoryURL.appendingPathComponent("\(tripId)_\(index).jpg")
    }

    @discardableResult
    static func save(_ image: UIImage, tripId: String, index: Int) -> Bool {
        let resized = image.trip_coverResized(to: CGSize(width: 1280, height: 1280))
        guard let data = resized.jpegData(compressionQuality: 0.84) else { return false }
        do {
            try data.write(to: fileURL(tripId: tripId, index: index), options: .atomic)
            return true
        } catch { return false }
    }

    static func load(tripId: String, index: Int) -> UIImage? {
        let url = fileURL(tripId: tripId, index: index)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func loadAll(tripId: String, count: Int) -> [UIImage] {
        (0..<count).compactMap { load(tripId: tripId, index: $0) }
    }

    static func deleteAll(tripId: String, count: Int) {
        for i in 0..<max(count, 48) {
            try? FileManager.default.removeItem(at: fileURL(tripId: tripId, index: i))
        }
        try? FileManager.default.removeItem(at: memoriesURL(tripId: tripId))
    }

    static func memoriesURL(tripId: String) -> URL {
        directoryURL.appendingPathComponent("\(tripId)_memories.json")
    }

    static func loadMemories(tripId: String, count: Int) -> [TripPhotoMemory] {
        let url = memoriesURL(tripId: tripId)
        guard let data = try? Data(contentsOf: url),
              let stored = try? JSONDecoder().decode([TripPhotoMemory].self, from: data) else {
            return Array(repeating: TripPhotoMemory(), count: count)
        }
        var result = stored
        while result.count < count { result.append(TripPhotoMemory()) }
        if result.count > count { result = Array(result.prefix(count)) }
        return result
    }

    static func saveMemories(tripId: String, memories: [TripPhotoMemory]) {
        let normalized = memories.map { memory in
            var m = memory
            m.title = String(m.title.prefix(120))
            m.caption = TripPhotoMemory.clampedCaption(m.caption)
            return m
        }
        guard let data = try? JSONEncoder().encode(normalized) else { return }
        try? data.write(to: memoriesURL(tripId: tripId), options: .atomic)
    }
}

// MARK: - Spot photos

enum SpotImageStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SpotPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(spotId: String, index: Int) -> URL {
        directoryURL.appendingPathComponent("\(spotId)_\(index).jpg")
    }

    @discardableResult
    static func save(_ image: UIImage, spotId: String, index: Int) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return false }
        do {
            try data.write(to: fileURL(spotId: spotId, index: index), options: .atomic)
            return true
        } catch { return false }
    }

    static func load(spotId: String, index: Int) -> UIImage? {
        let url = fileURL(spotId: spotId, index: index)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func loadAll(spotId: String, count: Int) -> [UIImage] {
        (0..<count).compactMap { load(spotId: spotId, index: $0) }
    }

    static func deleteAll(spotId: String, count: Int) {
        for i in 0..<count {
            try? FileManager.default.removeItem(at: fileURL(spotId: spotId, index: i))
        }
    }
}

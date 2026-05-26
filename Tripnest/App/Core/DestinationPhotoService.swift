import SwiftUI
import UIKit

// MARK: - TripPhoto (fond voyage)

struct TripPhoto: View {
    let destination: String
    let country: String
    var hue: Double = 270
    var radius: CGFloat = 16
    var showBorder: Bool = true
    var coverKind: TripCoverKind = .none
    var tripId: String? = nil
    var previewImage: UIImage? = nil

    @State private var storedCustomImage: UIImage?

    private var usesColorOnly: Bool {
        switch coverKind {
        case .custom: return false
        case .automatic, .none: return true
        }
    }

    private var displayedImage: UIImage? {
        guard coverKind == .custom else { return nil }
        return previewImage ?? storedCustomImage
    }

    var body: some View {
        ZStack {
            colorCover

            if let img = displayedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .layoutPriority(-1)
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            if showBorder {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.tBorder, lineWidth: 1)
            }
        }
        .task(id: customLoadKey) {
            await loadCustomImageIfNeeded()
        }
    }

    private var colorCover: some View {
        let base = Color(hue: hue / 360, saturation: 0.42, brightness: 0.50)
        let deep = Color(hue: (hue + 14) / 360, saturation: 0.48, brightness: 0.30)
        return Rectangle().fill(
            LinearGradient(
                colors: [base, deep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var customLoadKey: String {
        "\(coverKind.rawValue)|\(tripId ?? "")|\(usesColorOnly)"
    }

    @MainActor
    private func loadCustomImageIfNeeded() async {
        guard coverKind == .custom, previewImage == nil, let tripId else {
            storedCustomImage = nil
            return
        }
        // Disk I/O on background — never block the main thread for image loads.
        let loaded = await Task.detached(priority: .userInitiated) {
            TripCoverImageStore.load(tripId: tripId)
        }.value
        storedCustomImage = loaded
    }
}

// MARK: - Cadre 16:9 (identique avec ou sans photo galerie)

/// Réserve toujours un rectangle 16:9 : le dégradé seul ne rétrécit plus sans image.
struct TripCoverAspectContainer<Content: View>: View {
    var maxHeight: CGFloat = 148
    var cornerRadius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        Color.clear
            .aspectRatio(TripCoverLayout.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: maxHeight)
            .overlay {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Carte hero accueil (layout fixe, indépendant du fond)

private enum TripHeroLayout {
    static let cardHeight: CGFloat = 220
    static let topBandHeight: CGFloat = 54
    static let bottomBandHeight: CGFloat = 96
    static let bottomBandHeightWithReturn: CGFloat = 108
}

/// Même logique que les puces « Mes voyages » : statut en haut, infos groupées en bas — sans `Spacer` central.
struct TripHomeHeroCard: View {
    let trip: Trip
    var height: CGFloat = TripHeroLayout.cardHeight
    var cornerRadius: CGFloat = Tk.radiusLg
    var onTap: () -> Void = {}

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                TripPhoto(
                    destination: trip.dest,
                    country: trip.country,
                    hue: trip.hue,
                    radius: 0,
                    showBorder: false,
                    coverKind: trip.coverKind,
                    tripId: trip.id
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: height)
                .clipped()

                heroReadabilityScrim
                    .frame(height: height)

                heroTopChrome
                    .frame(height: TripHeroLayout.topBandHeight, alignment: .top)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    heroBottomChrome
                }
                .frame(height: height)
                .animation(.easeOut(duration: 0.2), value: trip.hasReturn)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.tBorderStrong, lineWidth: 1)
            )
            .shadow(color: Color.tBg0.opacity(0.45), radius: 18, x: 0, y: 14)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture(perform: onTap)
        }
    }

    private var heroReadabilityScrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.58), location: 0),
                .init(color: .black.opacity(0.14), location: 0.38),
                .init(color: .black.opacity(0.48), location: 0.72),
                .init(color: .black.opacity(0.86), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var heroTopChrome: some View {
        HStack(alignment: .center) {
            Spacer(minLength: 8)

            TransportModeGlyph(mode: trip.transportMode, size: 22, stroke: .white)
                .frame(width: 28, height: 28)
                .padding(6)
                .background(Circle().fill(Color.black.opacity(0.34)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .zIndex(2)
    }

    /// Bloc infos calqué sur `tripChip` : titre + aller + retour + dates.
    private var heroBottomChrome: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(trip.homeDestinationTitle)
                .font(.tDisplay(22))
                .tracking(-0.4)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(trip.homeOutboundLine)
                .font(.tText(13, weight: .semibold))
                .foregroundColor(.white.opacity(0.94))
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.72)

            if let returnLine = trip.homeReturnLine {
                Text(returnLine)
                    .font(.tText(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.88))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.72)
            }

            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                Text(trip.homeDateLine)
                    .font(.tText(11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity)
        .frame(
            height: trip.hasReturn ? TripHeroLayout.bottomBandHeightWithReturn : TripHeroLayout.bottomBandHeight,
            alignment: .bottomLeading
        )
        .clipped()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

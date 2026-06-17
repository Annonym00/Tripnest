import SwiftUI

struct MemoriesScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    @State private var filterYear: String = "Tous"
    @AppStorage("tripnest.currency") private var defaultCurrency: String = "EUR"

    private func extractYear(from dates: String) -> String? {
        dates.components(separatedBy: .whitespacesAndNewlines)
            .first(where: { $0.count == 4 && Int($0).map { $0 > 2000 && $0 < 2100 } == true })
    }

    private var availableYears: [String] {
        Array(Set(store.pastTrips.compactMap { extractYear(from: $0.dates) })).sorted(by: >)
    }

    private var filteredTrips: [Trip] {
        guard filterYear != "Tous" else { return store.pastTrips }
        return store.pastTrips.filter { extractYear(from: $0.dates) == filterYear }
    }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("SOUVENIRS")).font(.tText(11, weight: .bold)).tracking(1.5).foregroundColor(.tTextMute)
                    Text(L("Mon carnet de voyages")).font(.tDisplay(26)).tracking(-0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 14)

                statsStrip.padding(.horizontal, 18).padding(.bottom, 16)

                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            TPill(label: "Tous", active: filterYear == "Tous", action: { filterYear = "Tous" })
                            ForEach(availableYears, id: \.self) { year in
                                TPill(label: year, active: filterYear == year, action: { filterYear = year })
                            }
                        }
                    }
                    Spacer()
                    Text(L("Plus récents ⌄")).font(.tText(12, weight: .semibold)).foregroundColor(.tTextMute)
                }
                .padding(.horizontal, 18).padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    if filteredTrips.isEmpty {
                        emptyMemories
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .tripnestTabBarScrollPadding()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)],
                                  spacing: 12) {
                            ForEach(Array(filteredTrips.enumerated()), id: \.element.id) { i, p in
                                polaroidCard(p, tilt: i % 2 == 0 ? -0.6 : 0.5)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .tripnestTabBarScrollPadding()
                    }
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                TabBar(active: .trips, onChange: onNav)
            }
        }
    }

    private var statsStrip: some View {
        let countries = Set(store.pastTrips.map { $0.country }).filter { $0 != "À définir" }.count
        let totalDays = store.pastTrips.reduce(0) { $0 + $1.days }
        let totalSpent = store.pastTrips.reduce(0) { $0 + $1.spent }
        return HStack(spacing: 8) {
            statItem("Pays", countries > 0 ? "\(countries)" : "—", .tAccent2)
            statItem("Voyages", "\(store.pastTrips.count)", .tRose)
            statItem("Jours", totalDays > 0 ? "\(totalDays)" : "—", .tGold)
            statItem(L("Dépensé"), totalSpent > 0 ? "\(totalSpent)\(defaultCurrency.currencySymbol)" : "—", .tBlue)
        }
    }

    private func statItem(_ l: String, _ v: String, _ c: Color) -> some View {
        VStack(spacing: 0) {
            Text(v).font(.tDisplay(22)).tracking(-0.5).foregroundColor(c)
            Text(l.uppercased()).font(.tText(10, weight: .semibold)).tracking(0.5).foregroundColor(.tTextMute)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.tSurface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
    }

    private func polaroidCard(_ p: Trip, tilt: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                TripPhoto(
                    destination: p.dest,
                    country: p.country,
                    hue: p.hue,
                    radius: 0,
                    showBorder: false,
                    coverKind: p.coverKind,
                    tripId: p.id,
                    solidColor: p.resolvedCoverColor
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 160)
                TIcon(glyph: .plane, size: 18, stroke: .white)
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .padding(10)
                HStack {
                    Spacer()
                    HStack(spacing: 3) {
                        TIcon(glyph: .star, size: 10, stroke: .tGold, fill: .tGold)
                        Text("\(p.rating, specifier: "%.1f")")
                            .font(.tText(11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(10)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(p.dest).font(.tText(14, weight: .bold)).tracking(-0.2)
                Text(p.dates).font(.tText(10)).foregroundColor(.tTextMute)
                HStack(spacing: 8) {
                    Text("\(p.days)j")
                    Text("·")
                    Text("\(p.spent)\(defaultCurrency.currencySymbol)")
                }
                .font(.tText(10)).foregroundColor(.tTextMute).padding(.top, 4)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .frame(height: 220, alignment: .topLeading)
        .background(Color.tBg2)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.tBg0.opacity(0.4), radius: 12, x: 0, y: 12)
        .rotationEffect(.degrees(tilt))
    }

    private var emptyMemories: some View {
        TCard(padding: 22) {
            VStack(spacing: 12) {
                TIcon(glyph: .star, size: 36, stroke: .tGold)
                Text(L("Aucun souvenir pour le moment")).font(.tDisplay(23))
                Text(L("Tes voyages terminés apparaîtront ici avec leurs vraies photos et notes."))
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

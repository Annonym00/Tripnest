import SwiftUI

struct FlightsScreen: View {
    @EnvironmentObject private var store: TripStore
    var onNav: (AppRoute) -> Void = { _ in }
    var onBack: () -> Void = {}
    @State private var showTicketEditor = false
    @State private var editingTicket = TravelTicketDraft()

    private var activeTrip: Trip? { store.activeTrip }

    private var tripTickets: [Flight] {
        guard let trip = activeTrip else { return [] }
        return store.tickets(for: trip)
    }

    private var transportMode: TransportMode { activeTrip?.transportMode ?? .plane }
    private var hasTicket: Bool { !tripTickets.isEmpty }

    var body: some View {
        ScreenShell {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) { IconBtn(glyph: .back) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Retour")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transportMode.ticketDetailScreenTitle).font(.tDisplay(24)).tracking(-0.5)
                        Text("\(tripTickets.count) billet(s) · \(activeTrip?.dest ?? "—")")
                            .font(.tText(13)).foregroundColor(.tTextMute)
                    }
                    Spacer()
                    Button(action: openTicketEditor) {
                        HStack(spacing: 6) {
                            TIcon(
                                glyph: hasTicket ? .edit : .plus,
                                size: 14,
                                stroke: .white,
                                strokeWidth: hasTicket ? 2 : 2.5
                            )
                            Text(hasTicket ? "Modifier" : "Ajouter").font(.tText(13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tAccent))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.activeTrip == nil)
                    .opacity(store.activeTrip == nil ? 0.45 : 1)
                }
                .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.activeTrip == nil {
                            emptyState(
                                title: "Aucun voyage sélectionné",
                                subtitle: "Choisis ou crée un voyage pour y rattacher tes vols."
                            )
                        } else if tripTickets.isEmpty {
                            emptyState(
                                title: "Aucun billet enregistré",
                                subtitle: "Ajoute ton \(transportMode.ticketNoun) pour retrouver horaires et détails ici.",
                                actionLabel: "Ajouter un billet",
                                action: openTicketEditor
                            )
                        } else {
                            ForEach(tripTickets) { flight in
                                flightCard(flight)
                                    .contextMenu {
                                        Button(role: .destructive) { Haptics.impact(.medium); store.deleteFlight(id: flight.id) } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .tripnestTabBarScrollPadding()
                }
                .tripnestScrollBounceWhenNeeded()
            }
            .safeAreaInset(edge: .bottom) {
                TabBar(active: .trips, onChange: onNav)
            }
        }
        .sheet(isPresented: $showTicketEditor) {
            TravelTicketEditorSheet(
                mode: transportMode,
                draft: $editingTicket,
                tripOrigin: activeTrip?.origin ?? "",
                tripDestination: activeTrip?.dest ?? "",
                tripDepartureDate: activeTrip?.departureDate,
                onDone: saveTicket
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
    }

    private func openTicketEditor() {
        guard let trip = activeTrip else { return }
        if let existing = store.primaryTicket(for: trip) {
            editingTicket = TravelTicketDraft(flight: existing)
        } else {
            var draft = TravelTicketDraft()
            draft.prefillFromTrip(
                origin: trip.origin,
                destination: trip.dest,
                departureDate: trip.departureDate
            )
            editingTicket = draft
        }
        showTicketEditor = true
    }

    private func saveTicket() {
        guard let trip = activeTrip, editingTicket.hasMinimumInfo else { return }
        store.replaceTicket(for: trip.id, mode: transportMode, draft: editingTicket)
        Haptics.success()
    }

    private func emptyState(
        title: String,
        subtitle: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        TCard(padding: 22) {
            VStack(spacing: 12) {
                TransportModeGlyph(mode: transportMode, size: 36, stroke: .tAccent2)
                Text(title).font(.tDisplay(24))
                Text(subtitle)
                    .font(.tText(14))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                if let actionLabel, let action {
                    CTA(label: actionLabel, action: action).padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func flightCard(_ flight: Flight) -> some View {
        BoardingPassCard(flight: flight)
    }
}

// MARK: - Boarding pass card

private struct BoardingPassCard: View {
    let flight: Flight

    private var companyInitials: String {
        let words = flight.company
            .split(whereSeparator: { $0.isWhitespace || $0 == "-" })
            .compactMap { $0.first }
            .prefix(2)
        let joined = String(words).uppercased()
        return joined.isEmpty ? "✈︎" : joined
    }

    private var statusColor: Color { .tMint }

    var body: some View {
        VStack(spacing: 0) {
            header
            route
            perforation
            detailGrid
            barcode
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x1e1238), Color(hex: 0x150a2a)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.tBorderStrong, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tBg0.opacity(0.55), radius: 22, x: 0, y: 18)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(colors: [.tAccent2, .tAccentDeep],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(companyInitials)
                        .font(.tText(12, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(0.6)
                }
                .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.company.isEmpty ? "Compagnie" : flight.company)
                        .font(.tText(13, weight: .bold))
                    Text(flight.code.isEmpty ? "—" : flight.code)
                        .font(.tText(11))
                        .foregroundColor(.tTextMute)
                }
                Spacer()
                Text("À L'HEURE")
                    .font(.tText(10, weight: .heavy))
                    .tracking(1.3)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(statusColor.opacity(0.12)))
                    .overlay(Capsule().stroke(statusColor.opacity(0.32), lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            DashedRule()
                .padding(.horizontal, 20)
        }
    }

    private var route: some View {
        HStack(alignment: .top, spacing: 8) {
            airport(city: flight.fromCity, code: flight.from, time: flight.departure, trailing: false)
            Spacer(minLength: 8)
            VStack(spacing: 8) {
                Text(flight.duration.isEmpty ? "--" : flight.duration)
                    .font(.tText(10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(.tTextDim)
                DashedArrowLine()
                    .frame(width: 80, height: 16)
                TIcon(glyph: .plane, size: 18, stroke: .tAccent2)
            }
            Spacer(minLength: 8)
            airport(city: flight.toCity, code: flight.to, time: flight.arrival, trailing: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 22)
    }

    private var perforation: some View {
        ZStack {
            Rectangle().fill(Color.clear).frame(height: 0)
            HStack {
                Circle().fill(Color.tBg0).frame(width: 22, height: 22).offset(x: -11)
                Spacer()
                Circle().fill(Color.tBg0).frame(width: 22, height: 22).offset(x: 11)
            }
            HStack(spacing: 0) {
                ForEach(0..<28, id: \.self) { _ in
                    Rectangle().fill(Color.tBorder).frame(width: 6, height: 1)
                    Spacer(minLength: 4)
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 1)
    }

    private var detailGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            detail("DATE", flight.date)
            detail("SIÈGE", flight.seat)
            detail("PORTE", flight.gate)
            detail("TERM.", flight.terminal)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    private var barcode: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 1) {
                ForEach(0..<54, id: \.self) { i in
                    Rectangle()
                        .fill(i % 7 == 0 ? Color.clear : Color.tText.opacity(0.85))
                        .frame(width: CGFloat(1 + (i % 3)))
                }
            }
            .frame(height: 38)
            Text(barcodeText)
                .font(.tMono(10))
                .tracking(2)
                .foregroundColor(.tTextMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var barcodeText: String {
        let code = flight.code.replacingOccurrences(of: " ", with: "").uppercased()
        let from = flight.from.uppercased()
        let to = flight.to.uppercased()
        let parts = [code, from, to, flight.date.uppercased(), flight.seat.uppercased()]
            .filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    private func airport(city: String, code: String, time: String, trailing: Bool) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 4) {
            Text(city.isEmpty ? "Ville" : city)
                .font(.tText(11))
                .foregroundColor(.tTextMute)
            Text(code.isEmpty ? "---" : code)
                .font(.tDisplay(40, weight: .heavy))
                .tracking(-1.8)
                .foregroundColor(.tText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(time.isEmpty ? "--:--" : time)
                .font(.tText(18, weight: .bold))
                .tracking(-0.4)
                .foregroundColor(.tText)
        }
        .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.tText(9, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(.tTextMute)
            Text(value.isEmpty ? "--" : value)
                .font(.tText(15, weight: .bold))
                .tracking(-0.2)
                .foregroundColor(.tText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashedRule: View {
    var body: some View {
        Canvas { ctx, rect in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: rect.height / 2))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            ctx.stroke(p, with: .color(.tBorder),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .frame(height: 1)
    }
}

private struct DashedArrowLine: View {
    var body: some View {
        Canvas { ctx, rect in
            let y = rect.height / 2
            var line = Path()
            line.move(to: CGPoint(x: 4, y: y))
            line.addLine(to: CGPoint(x: rect.width - 4, y: y))
            ctx.stroke(line, with: .color(.tAccent2),
                       style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            ctx.stroke(
                Path(ellipseIn: CGRect(x: 0, y: y - 3, width: 6, height: 6)),
                with: .color(.tAccent2),
                lineWidth: 1.5
            )
            var endDot = Path()
            endDot.addEllipse(in: CGRect(x: rect.width - 6, y: y - 3, width: 6, height: 6))
            ctx.fill(endDot, with: .color(.tAccent2))
        }
    }
}


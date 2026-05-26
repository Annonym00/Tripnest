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
        TCard(padding: 18) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.company.isEmpty ? "Compagnie" : flight.company)
                            .font(.tText(13, weight: .bold))
                        Text(flight.code.isEmpty ? "—" : flight.code)
                            .font(.tText(11)).foregroundColor(.tTextMute)
                    }
                    Spacer()
                    TransportModeGlyph(mode: flight.transportMode, size: 22, stroke: .tAccent2)
                }

                HStack(alignment: .center, spacing: 8) {
                    airport(city: flight.fromCity, code: flight.from, time: flight.departure)
                    Spacer()
                    VStack(spacing: 8) {
                        Text(flight.duration.isEmpty ? "--" : flight.duration)
                            .font(.tText(10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.tTextDim)
                        TIcon(glyph: .arrow, size: 18, stroke: .tAccent2)
                    }
                    Spacer()
                    airport(city: flight.toCity, code: flight.to, time: flight.arrival, trailing: true)
                }

                HStack {
                    detail("DATE", flight.date)
                    detail("SIEGE", flight.seat)
                    detail("PORTE", flight.gate)
                    detail("TERM.", flight.terminal)
                }
            }
        }
    }

    private func airport(city: String, code: String, time: String, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(city.isEmpty ? "Ville" : city).font(.tText(12)).foregroundColor(.tTextMute)
            Text(code.isEmpty ? "---" : code).font(.tDisplay(34)).tracking(-1.2)
            Text(time.isEmpty ? "--:--" : time).font(.tText(13, weight: .bold))
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.tText(10, weight: .bold)).tracking(1).foregroundColor(.tTextMute)
            Text(value.isEmpty ? "--" : value).font(.tText(14, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


import SwiftUI
import Factory

struct EarningsCalendarScreen: View {
  @Environment(\.colorScheme) private var colorScheme
  private var marketDataService: any MarketDataServicing { Container.shared.marketDataService() }
  
  @State private var selectedDate = Date()
  @State private var earnings: [EarningsEvent] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var selectedEvent: EarningsEvent?

  var body: some View {
    VStack(spacing: 0) {
      // Marked Calendar Picker
      EarningsMarkedCalendar(
        selectedDate: $selectedDate,
        markedDates: Set(earnings.map { $0.date })
      )
      .frame(height: 380)
      .background(AppTheme.Colors.cardBackground(for: colorScheme))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .padding()

      // Earnings List
      ZStack {
        if isLoading && earnings.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            Section("Earnings for \(selectedDate.formatted(date: .long, time: .omitted))") {
              let dayEarnings = earningsForSelectedDate
              if dayEarnings.isEmpty {
                ContentUnavailableView {
                  Label("No Earnings Today", systemImage: "calendar.badge.exclamationmark")
                } description: {
                  Text("No earnings releases found for the selected date.")
                }
                .listRowBackground(Color.clear)
              } else {
                ForEach(dayEarnings) { event in
                  Button {
                    selectedEvent = event
                  } label: {
                    EarningsRow(event: event)
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }
          .listStyle(.insetGrouped)
          .scrollContentBackground(.hidden)
          .refreshable {
            await loadEarnings()
          }
        }
      }
    }
    .sheet(item: $selectedEvent) { event in
      EarningsDetailView(event: event)
    }
    .task(id: selectedDate) {
      // Reload if we cross into a date we don't have cached in the current set
      await loadEarnings()
    }
    .overlay(alignment: .top) {
      if let errorMessage {
        ToastBanner(message: errorMessage, style: .error)
          .padding(.horizontal, 16)
          .padding(.top, 8)
      }
    }
  }

  private var earningsForSelectedDate: [EarningsEvent] {
    let dateString = formatISODateOnly(selectedDate)
    return earnings.filter { $0.date == dateString }
  }

  private func loadEarnings() async {
    let calendar = Calendar.current
    guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
          let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
      return
    }
    
    let from = formatISODateOnly(startOfMonth)
    let to = formatISODateOnly(endOfMonth)
    
    // Simple optimization: only fetch if we don't have any earnings for this range yet
    let currentDates = Set(earnings.map { $0.date })
    if earnings.isEmpty || !currentDates.contains(from) {
        isLoading = true
        errorMessage = nil
        
        do {
          let results = try await marketDataService.fetchEarningsCalendar(from: from, to: to)
          // Merge results to keep a local cache of this session's browsed months
          let newEarnings = (self.earnings + results).reduce(into: [String: EarningsEvent]()) { dict, event in
              dict[event.id] = event
          }.values
          self.earnings = Array(newEarnings)
        } catch {
          self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
  }

  private func formatISODateOnly(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}

// MARK: - Marked Calendar Implementation

struct EarningsMarkedCalendar: UIViewRepresentable {
    @Binding var selectedDate: Date
    let markedDates: Set<String> // Format: YYYY-MM-DD

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar(identifier: .gregorian)
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        calendarView.delegate = context.coordinator
        
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            selection.setSelected(components, animated: true)
        }
        
        // Refresh decorations
        uiView.reloadDecorations(forDateComponents: Array(markedDates).compactMap { dateString -> DateComponents? in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: dateString) else { return nil }
            return Calendar.current.dateComponents([.year, .month, .day], from: date)
        }, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: EarningsMarkedCalendar

        init(_ parent: EarningsMarkedCalendar) {
            self.parent = parent
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let date = dateComponents?.date else { return }
            parent.selectedDate = date
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateComponents.date else { return nil }
            let dateString = formatter.string(from: date)
            
            if parent.markedDates.contains(dateString) {
                // Use a star symbol for better visibility as requested
                return .customView {
                    let image = UIImage(systemName: "star.fill")
                    let imageView = UIImageView(image: image)
                    imageView.tintColor = .systemBlue
                    imageView.contentMode = .scaleAspectFit
                    imageView.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
                    return imageView
                }
            }
            return nil
        }
    }
}

// MARK: - Detail View

struct EarningsDetailView: View {
    let event: EarningsEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(event.symbol)
                            .typography(.hero, weight: .bold)
                        Text(event.date)
                            .typography(.label)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Financials Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailMetricCard(title: "EPS Actual", value: event.epsActual?.formatted() ?? "—", tint: .blue)
                        DetailMetricCard(title: "EPS Estimated", value: event.epsEstimated?.formatted() ?? "—", tint: .gray)
                        DetailMetricCard(title: "Revenue Actual", value: event.revenueActual?.formatted(.number.notation(.compactName)) ?? "—", tint: .green)
                        DetailMetricCard(title: "Revenue Estimated", value: event.revenueEstimated?.formatted(.number.notation(.compactName)) ?? "—", tint: .gray)
                    }
                    .padding(.horizontal)

                    // Metadata
                    if let lastUpdated = event.lastUpdated {
                        Text("Data last updated: \(lastUpdated)")
                            .typography(.nano)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Earnings Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(AppTheme.Colors.pageBackground(for: colorScheme).ignoresSafeArea())
        }
        .presentationDetents([.medium])
    }
}

private struct DetailMetricCard: View {
    let title: String
    let value: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .typography(.caption, weight: .semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .typography(.title, weight: .bold)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appGlassEffect(.rect(cornerRadius: 16), tint: tint.opacity(0.1))
    }
}

struct EarningsRow: View {
  let event: EarningsEvent
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(event.symbol)
          .typography(.headline, weight: .bold)
        Spacer()
        Text(event.date)
          .typography(.nano)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        EarningsMetricPill(
          title: "EPS Actual",
          value: event.epsActual?.formatted(.number.precision(.fractionLength(2))) ?? "--",
          tint: .blue
        )
        EarningsMetricPill(
          title: "EPS Estimated",
          value: event.epsEstimated?.formatted(.number.precision(.fractionLength(2))) ?? "--",
          tint: .gray
        )
      }

      HStack(spacing: 12) {
        EarningsMetricPill(
          title: "Revenue Actual",
          value: event.revenueActual?.formatted(.number.notation(.compactName)) ?? "--",
          tint: .green
        )
        EarningsMetricPill(
          title: "Revenue Estimated",
          value: event.revenueEstimated?.formatted(.number.notation(.compactName)) ?? "--",
          tint: .gray
        )
      }
    }
    .padding(.vertical, 8)
  }
}

struct EarningsMetricPill: View {
  let title: String
  let value: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .typography(.nano)
        .foregroundStyle(.secondary)
      Text(value)
        .typography(.small, weight: .semibold)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .appGlassEffect(.rect(cornerRadius: 12), tint: tint.opacity(0.1))
  }
}

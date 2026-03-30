import StockPlanShared
import SwiftUI

@MainActor
struct EditStockAnalysisSheet: View {
  let stock: StockResponse
  let onSave: @MainActor (String?) async -> String?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  @State private var analysis: String
  @State private var isSaving = false
  @State private var saveErrorMessage: String?
  @State private var successFeedbackTrigger = 0

  init(
    stock: StockResponse,
    onSave: @escaping @MainActor (String?) async -> String?
  ) {
    self.stock = stock
    self.onSave = onSave
    _analysis = State(initialValue: stock.notes ?? "")
  }

  var body: some View {
    VStack(spacing: 0) {
      FormSheetHeader(
        title: "Edit Analysis",
        subtitle: stock.symbol,
        onDismiss: { dismiss() }
      )

      ScrollView {
        VStack(spacing: 16) {
          HStack {
            FormInfoTag(text: stock.symbol, icon: "text.quote")
            Spacer()
          }

          FormCard(title: "Analysis") {
            VStack(alignment: .leading, spacing: 10) {
              Text("Write your thesis, key risks, and the signals that would make you add, trim, or exit.")
                .typography(.caption)
                .foregroundStyle(.secondary)

              ZStack(alignment: .topLeading) {
                if analysis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  Text("Add your own analysis")
                    .typography(.label)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }

                TextEditor(text: $analysis)
                  .frame(minHeight: 180)
                  .scrollContentBackground(.hidden)
                  .typography(.label)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
          }

          if let saveErrorMessage {
            FormErrorBanner(message: saveErrorMessage)
          }

          Spacer(minLength: 80)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
      }
      .scrollDismissesKeyboard(.interactively)

      FormActionBar(
        primaryLabel: isSaving ? "Saving…" : "Save analysis",
        isLoading: isSaving,
        isDisabled: isSaving
      ) {
        Task { @MainActor in
          await save()
        }
      }
    }
    .background(AppTheme.Colors.pageBackground(for: colorScheme).ignoresSafeArea())
    .presentationDragIndicator(.visible)
    .appSensoryFeedback(success: successFeedbackTrigger)
  }

  @MainActor
  private func save() async {
    isSaving = true
    defer { isSaving = false }

    if let message = await onSave(normalizedOptional(analysis)) {
      saveErrorMessage = message
    } else {
      saveErrorMessage = nil
      successFeedbackTrigger += 1
      dismiss()
    }
  }

  private func normalizedOptional(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

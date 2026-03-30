import SwiftUI
import AssistantKit

/// Compact indicator showing an input prompt was detected.
/// Appears as an overlay on the terminal pane.
struct InputIndicatorView: View {
    let result: DetectionResult
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Compact badge
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 10, weight: .bold))
                    Text(shortLabel)
                        .font(.system(size: 10, weight: .medium))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)

            // Expanded view with actions
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Matched text preview
                    Text(result.matchedText.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(3)
                        .foregroundColor(.primary)

                    // Quick actions
                    if !result.suggestedActions.isEmpty {
                        Divider()

                        HStack(spacing: 8) {
                            ForEach(Array(result.suggestedActions.prefix(3).enumerated()), id: \.offset) { _, action in
                                ActionButton(action: action)
                            }

                            Spacer()

                            Button(action: onDismiss) {
                                Text("Dismiss")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .frame(maxWidth: 280)
            }
        }
    }

    private var iconName: String {
        switch result.pattern.type {
        case .permission:
            return "lock.shield"
        case .yesNo:
            return "questionmark.circle"
        case .question:
            return "questionmark.bubble"
        case .raisedHand:
            return "hand.raised"
        case .continuePrompt:
            return "arrow.right.circle"
        case .selection:
            return "list.number"
        case .inputCursor:
            return "keyboard"
        case .toolUsage:
            return "gearshape"
        }
    }

    private var shortLabel: String {
        switch result.pattern.type {
        case .permission:
            return "Permission"
        case .yesNo:
            return "Y/N"
        case .question:
            return "Question"
        case .raisedHand:
            return "Attention"
        case .continuePrompt:
            return "Continue"
        case .selection:
            return "Select"
        case .inputCursor:
            return "Input"
        case .toolUsage:
            return "Tool"
        }
    }

    private var backgroundColor: Color {
        switch result.pattern.type {
        case .permission:
            return .orange
        case .yesNo, .question:
            return .blue
        case .raisedHand:
            return .red
        case .continuePrompt:
            return .green
        case .selection:
            return .purple
        case .inputCursor:
            return .gray
        case .toolUsage:
            return Color(nsColor: .systemGray)
        }
    }
}

/// Button for a suggested action
struct ActionButton: View {
    let action: SuggestedAction

    var body: some View {
        Button(action: {
            // Send the action input to the terminal
            // This would need to be wired up to the terminal view
            print("Action: \(action.label) -> send: \(action.input.debugDescription)")
        }) {
            HStack(spacing: 2) {
                Text(action.label)
                    .font(.system(size: 10, weight: action.isDefault ? .semibold : .regular))
                if let shortcut = action.shortcut {
                    Text(shortcut)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(action.isDefault ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Permission Alert") {
    let permissionPattern = try! InputPattern(
        id: "test-permission",
        pattern: "Allow",
        type: .permission,
        priority: 100
    )
    let result = DetectionResult(
        pattern: permissionPattern,
        matchedText: "? Allow Read access to config.json",
        range: "? Allow Read access to config.json".startIndex..<"? Allow Read access to config.json".endIndex,
        confidence: 1.0,
        suggestedActions: [.yes, .no]
    )

    return InputIndicatorView(result: result, onDismiss: {})
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
}

#Preview("Yes/No Alert") {
    let yesNoPattern = try! InputPattern(
        id: "test-yesno",
        pattern: "Continue",
        type: .yesNo,
        priority: 90
    )
    let result = DetectionResult(
        pattern: yesNoPattern,
        matchedText: "Continue? [Y/n]",
        range: "Continue? [Y/n]".startIndex..<"Continue? [Y/n]".endIndex,
        confidence: 1.0,
        suggestedActions: [.yes, .no]
    )

    return InputIndicatorView(result: result, onDismiss: {})
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
}

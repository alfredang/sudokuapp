import SwiftUI

/// One-time 18+ confirmation. The app carries an 18+ age rating, so the player must
/// confirm they are of age before playing. The choice is stored on-device.
struct AgeGateView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "18.circle.fill")
                .font(.system(size: 84, weight: .bold))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Sudoku")
                    .font(.largeTitle.bold())
                Text("This app is intended for players aged 18 and over.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.isAgeConfirmed = true
                } label: {
                    Text("I am 18 or older")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)

                Text("By continuing you confirm that you are at least 18 years old.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

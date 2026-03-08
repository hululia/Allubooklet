import SwiftUI

struct TripCardView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.7), .blue.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("\(dateText(trip.startDate)) - \(dateText(trip.endDate))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(10)
                }
                .frame(height: 210)

            Label("\(trip.photoCount) photos", systemImage: "photo.on.rectangle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func dateText(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}

#Preview {
    TripCardView(
        trip: Trip(
            startDate: .now.addingTimeInterval(-86_400 * 6),
            endDate: .now,
            photoIds: ["1", "2", "3"],
            city: "Tokyo",
            country: "Japan",
            title: "2024 Tokyo Trip",
            coverPhotoId: "1"
        )
    )
    .padding()
}

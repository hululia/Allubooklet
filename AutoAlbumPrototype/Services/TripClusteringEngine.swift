import Foundation
import CoreLocation

struct TripClusteringConfig {
    var newTripTimeGapHours: Double = 48
    var newTripDistanceKm: Double = 50
    var minTripPhotoCount: Int = 8
}

final class TripClusteringEngine {
    private let config: TripClusteringConfig

    init(config: TripClusteringConfig = .init()) {
        self.config = config
    }

    func groupPhotosByTrip(_ points: [PhotoPoint]) -> [Trip] {
        let sorted = points.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        var rawClusters: [[PhotoPoint]] = []
        var current: [PhotoPoint] = [sorted[0]]

        for point in sorted.dropFirst() {
            guard let previous = current.last else { continue }
            if shouldStartNewTrip(previous: previous, current: point) {
                rawClusters.append(current)
                current = [point]
            } else {
                current.append(point)
            }
        }

        if !current.isEmpty {
            rawClusters.append(current)
        }

        return rawClusters
            .filter { $0.count >= config.minTripPhotoCount }
            .compactMap(makeTrip(from:))
    }

    private func shouldStartNewTrip(previous: PhotoPoint, current: PhotoPoint) -> Bool {
        let dtHours = current.date.timeIntervalSince(previous.date) / 3600
        let movedKm = distanceKm(from: previous.location, to: current.location)
        return dtHours > config.newTripTimeGapHours && movedKm > config.newTripDistanceKm
    }

    private func distanceKm(from lhs: CLLocation?, to rhs: CLLocation?) -> Double {
        guard let lhs, let rhs else { return 0 }
        return lhs.distance(from: rhs) / 1000
    }

    private func makeTrip(from points: [PhotoPoint]) -> Trip? {
        guard let start = points.first?.date, let end = points.last?.date else { return nil }
        return Trip(
            startDate: start,
            endDate: end,
            photoIds: points.map(\.id),
            city: nil,
            country: nil,
            title: "Trip",
            coverPhotoId: points.first?.id
        )
    }
}

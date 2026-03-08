import Foundation
import CoreLocation

final class ReverseGeocodeService {
    private let geocoder = CLGeocoder()

    func cityInfo(for location: CLLocation?) async -> TripCityInfo {
        guard let location else { return TripCityInfo(city: nil, country: nil) }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let place = placemarks.first
            return TripCityInfo(city: place?.locality, country: place?.country)
        } catch {
            return TripCityInfo(city: nil, country: nil)
        }
    }
}

struct AlbumNamingService {
    func makeTitle(startDate: Date, city: String?, country: String?) -> String {
        let year = Calendar.current.component(.year, from: startDate)
        if let city, !city.isEmpty {
            return "\(year) \(city) Trip"
        }
        if let country, !country.isEmpty {
            return "\(year) \(country) Trip"
        }
        return "\(year) Trip"
    }
}

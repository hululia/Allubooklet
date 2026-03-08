import Foundation
import CoreLocation

struct PhotoPoint: Identifiable {
    let id: String
    let date: Date
    let location: CLLocation?
}

struct Trip: Identifiable {
    let id = UUID()
    var startDate: Date
    var endDate: Date
    var photoIds: [String]
    var city: String?
    var country: String?
    var title: String
    var coverPhotoId: String?

    var photoCount: Int { photoIds.count }
}

struct TripCityInfo {
    let city: String?
    let country: String?
}

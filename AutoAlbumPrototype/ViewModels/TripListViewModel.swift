import Foundation
import Photos
import CoreLocation

@MainActor
final class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var showPermissionAlert = false

    private let photoService: PhotoLibraryService
    private let clusteringEngine: TripClusteringEngine
    private let geocodeService: ReverseGeocodeService
    private let namingService: AlbumNamingService

    init(
        photoService: PhotoLibraryService = .init(),
        clusteringEngine: TripClusteringEngine = .init(),
        geocodeService: ReverseGeocodeService = .init(),
        namingService: AlbumNamingService = .init()
    ) {
        self.photoService = photoService
        self.clusteringEngine = clusteringEngine
        self.geocodeService = geocodeService
        self.namingService = namingService
    }

    func requestAccessIfNeeded() async {
        let granted = await photoService.requestReadPermission()
        showPermissionAlert = !granted
    }

    func regenerateTrips() async {
        guard !showPermissionAlert else { return }
        isLoading = true

        let assets = photoService.fetchImageAssets()
        let points = photoService.mapToPhotoPoints(assets)
        var generatedTrips = clusteringEngine.groupPhotosByTrip(points)

        for index in generatedTrips.indices {
            guard let firstLocation = points.first(where: { $0.id == generatedTrips[index].photoIds.first })?.location else {
                continue
            }
            let cityInfo = await geocodeService.cityInfo(for: firstLocation)
            generatedTrips[index].city = cityInfo.city
            generatedTrips[index].country = cityInfo.country
            generatedTrips[index].title = namingService.makeTitle(
                startDate: generatedTrips[index].startDate,
                city: cityInfo.city,
                country: cityInfo.country
            )
        }

        trips = generatedTrips.sorted { $0.startDate > $1.startDate }
        isLoading = false
    }
}

extension TripListViewModel {
    static var preview: TripListViewModel {
        let vm = TripListViewModel()
        vm.trips = [
            Trip(
                startDate: Date(timeIntervalSince1970: 1_589_000_000),
                endDate: Date(timeIntervalSince1970: 1_589_260_000),
                photoIds: (1...48).map { "photo-\($0)" },
                city: "Hawaii",
                country: "USA",
                title: "2020 Hawaii Trip",
                coverPhotoId: "photo-1"
            )
        ]
        return vm
    }
}

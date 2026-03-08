import Foundation
import Photos

final class PhotoLibraryService {
    func requestReadPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            return true
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return newStatus == .authorized || newStatus == .limited
    }

    func fetchImageAssets(limit: Int = 5000) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.fetchLimit = limit

        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func mapToPhotoPoints(_ assets: [PHAsset]) -> [PhotoPoint] {
        assets.compactMap { asset in
            guard let date = asset.creationDate else { return nil }
            return PhotoPoint(id: asset.localIdentifier, date: date, location: asset.location)
        }
    }
}

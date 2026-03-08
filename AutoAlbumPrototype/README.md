# AutoAlbumPrototype (SwiftUI + PhotoKit)

最小可运行原型结构，目标是把“自动成册”方案快速落地成可在 iPad/iOS 工程中接入的骨架。

## 包含模块
- `PhotoLibraryService`：照片权限 + `PHAsset` 拉取
- `TripClusteringEngine`：按时间/空间阈值切分 Trip
- `ReverseGeocodeService`：地点反查 + 城市/国家
- `AlbumNamingService`：`[Year] [City/Country] Trip` 命名
- `TripListViewModel`：串联数据流
- `TripCardView`：卡片式 Liquid 风格预览

## 快速接入
1. 在 Xcode 新建 **iOS App (SwiftUI)**。
2. 将本目录中的 `.swift` 文件拖入项目。
3. 在 target 中开启：
   - `Privacy - Photo Library Usage Description`
4. 真机运行（模拟器通常没有完整照片库）。

## 当前阈值（可调）
- 新旅程切分：`时间间隔 > 48h` 且 `位移 > 50km`
- 最小旅程照片数：`8`

> 这是 MVP 原型，后续可继续加入“陌生城市停留 >= 2 天”“Home City 抑制误判”“封面质量评分”等高级规则。

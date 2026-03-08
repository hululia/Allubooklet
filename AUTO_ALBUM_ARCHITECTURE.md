# 自动成册（Auto Trip Album）实现方案（iPad / SwiftUI）

## 1) 产品目标
在用户导入或授权相册后，App 自动从系统照片中识别“旅程事件（Trip Event）”，并生成类似 `2020 Hawaii Trip` 的智能相册。

核心体验：
- 不需要手动整理照片。
- 自动按“时间 + 空间”识别旅程。
- 自动命名并生成封面。
- 支持用户轻量修正（改名、合并、拆分）。

---

## 2) 数据来源与权限
- 照片读取：`PhotoKit (PHAsset)`
- 时间：`creationDate`
- 地点：`location`（`CLLocation`）
- 地名解析：`CLGeocoder.reverseGeocodeLocation`

权限建议：
1. 首次仅请求 `PHPhotoLibrary` 读取权限。
2. 进入“自动成册”功能时再解释用途（pre-permission 教学页）。
3. 对无 GPS 照片做“时间聚类兜底”，不要丢弃。

---

## 3) 时空聚类规则（Spatiotemporal Clustering）

> 目标：避免“按天硬切”，转为“旅程语义切分”。

### 3.1 预处理
1. 过滤视频/截图（可配置）。
2. 按 `creationDate` 升序。
3. 将照片映射为 `PhotoPoint`：
   - `assetId`
   - `timestamp`
   - `coordinate?`
   - `cityCandidate?`（后续填充）

### 3.2 Trip 触发条件（建议初始阈值）
定义 `currentCluster` 为当前旅程候选集合。

触发“新 Trip”条件（满足任一）：
1. **长时跳转**：相邻照片时间间隔 > `48h` 且空间距离 > `50km`。
2. **陌生城市停留**：进入新城市后连续素材覆盖时间 >= `2天`。
3. **跨国家/跨州（可选高优先级）**：逆地理编码结果国家（或州）变化，且新地点照片数 >= `N`。

结束 Trip 条件：
- 回到常驻城市（Home）并持续 >= `24h`。
- 或时间断层 > `72h` 且后续地点明显变化。

### 3.3 Home City 识别（提升准确率）
统计最近 90 天晚间（20:00–06:00）出现频次最高城市作为 `homeCity`。
- 用于避免把“日常通勤”误判为 Trip。

### 3.4 噪音处理
- 单张孤立点（仅 1–2 张，停留 < 3h）可并入前后簇。
- GPS 抖动用 1km 半径网格平滑。
- 无 GPS 照片：按拍摄时间插值归并到邻近 Trip。

---

## 4) 智能命名策略

命名模板优先级：
1. `[Year] [City] Trip`（如 `2020 Hawaii Trip`）
2. `[Year] [Region/Country] Trip`
3. `[Year] Spring Trip`（兜底）

细节策略：
- 若旅程覆盖多个城市：`2020 Japan (Tokyo + Kyoto) Trip`
- 若城市置信度不足，回退到国家级别。
- 支持本地化：中文用户可展示 `2020年 夏威夷之旅`，英文系统展示英文名。

---

## 5) 封面图自动选择（视觉预览）

每个 Trip 从候选集中打分，取 Top-1 作为封面：

`score = 0.35*清晰度 + 0.25*人脸质量 + 0.2*曝光/构图 + 0.1*时间代表性 + 0.1*地点代表性`

可用能力：
- `Vision`：人脸检测、主体区域质量。
- `CoreImage`：模糊度（Laplacian variance）、曝光估计。
- “代表性”可偏向旅程中位时间点与主地点。

---

## 6) iOS Liquid Glass 2030 风格（iPad）

### 信息架构
- 顶部：超大标题 `Trips` + 年份筛选胶囊。
- 主区：两列或三列自适应卡片网格（iPad 横屏三列）。
- 卡片：
  - 大图封面（圆角 24）
  - 玻璃拟态信息层（地点、日期范围、照片数）
  - 轻微视差与滚动动态模糊

### 交互
- 点按进入 Trip 时间线（按天折叠）。
- 长按卡片：重命名 / 合并 / 设为收藏。
- 顶部提供“重新智能整理”按钮（增量重算）。

### 动效建议
- 卡片进入：spring + fade。
- 筛选切换：cross dissolve。
- 封面刷新：shared element 过渡。

---

## 7) 推荐技术实现（SwiftUI + PhotoKit）

### 7.1 模块划分
- `PhotoIngestionService`：拉取资产与增量监听。
- `TripClusteringEngine`：时空聚类核心。
- `GeocodeService`：反向地理编码与缓存。
- `AlbumNamingService`：命名策略。
- `CoverSelectionService`：封面评分。
- `TripStore`：本地持久化（SQLite/CoreData/SwiftData）。

### 7.2 关键数据结构
```swift
struct PhotoPoint {
    let assetLocalIdentifier: String
    let date: Date
    let location: CLLocation?
}

struct Trip {
    let id: UUID
    var startDate: Date
    var endDate: Date
    var photoIds: [String]
    var centroid: CLLocation?
    var city: String?
    var country: String?
    var title: String
    var coverPhotoId: String?
}
```

### 7.3 聚类伪代码
```swift
func groupPhotosByTrip(_ assets: [PHAsset]) -> [Trip] {
    let points = assets
        .compactMap(mapToPhotoPoint)
        .sorted { $0.date < $1.date }

    var trips: [Trip] = []
    var current = TripBuilder()

    for p in points {
        if current.isEmpty {
            current.start(with: p)
            continue
        }

        let dt = p.date.timeIntervalSince(current.lastDate)
        let dist = distanceKm(p.location, current.lastLocation)

        if shouldStartNewTrip(dt: dt, distanceKm: dist, point: p, current: current) {
            trips.append(current.build())
            current = TripBuilder()
            current.start(with: p)
        } else {
            current.append(p)
        }
    }

    if !current.isEmpty { trips.append(current.build()) }
    return postProcess(trips)
}
```

---

## 8) 性能与工程化建议
- 首次全量计算 + 后续增量更新（通过 `PHPhotoLibraryChangeObserver`）。
- Geocoder 做 LRU 缓存（按网格中心点缓存）。
- 后台任务分片执行，避免主线程卡顿。
- 结果写入本地数据库，UI 层只读聚合模型。

---

## 9) MVP 上线路径（建议 3 个版本）

### V1（2-3 周）
- 基础时空聚类 + 自动命名 + 卡片列表。
- 用户可手动重命名。

### V2
- 封面智能评分。
- Trip 合并/拆分编辑器。
- Home City 自学习。

### V3
- 多设备同步（CloudKit）。
- 旅程故事页（地图轨迹 + 精选照片）。

---

## 10) 关键指标（衡量“智能感”）
- 自动成册命中率（用户无需修改的 Trip 占比）。
- 命名采纳率（用户未改名占比）。
- 首次渲染耗时、增量更新耗时。
- 用户进入 Trip 详情页点击率。


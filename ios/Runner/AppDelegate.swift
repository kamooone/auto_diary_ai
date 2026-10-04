import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 完全終了後にOSが位置情報イベントで再起動した場合も含め、記録を再開する
    LocationRecorder.shared.resumeIfEnabled()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    LocationRecorder.shared.registerChannel(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}

/// 位置情報をネイティブ側で記録する
///
/// 4つの仕組みを組み合わせる
/// - 通常の位置更新: アプリが動いている間(バックグラウンド含む)の細かい経路を記録する
/// - 重要な位置変更通知: 完全終了後、およそ500m以上の移動でOSがアプリを再起動する
/// - ジオフェンス: 現在地の周囲に円を置き、完全終了後にそこから出るとOSがアプリを再起動する
/// - 滞在検知(CLVisit): 滞在の到着・出発時刻を、終了中の分も含めて後から受け取る
///
/// OSによる再起動の時点ではFlutter(Dart)が動いているとは限らないため、
/// 取得した位置はいったんファイルに溜めておき、Dart側が取り出してIsarへ保存する。
final class LocationRecorder: NSObject, CLLocationManagerDelegate {
  static let shared = LocationRecorder()

  private static let channelName = "auto_diary_ai/location_recorder"
  private static let enabledKey = "location_recording_enabled"
  private static let lastVisitArrivalKey = "location_recording_last_visit_arrival"
  private static let distanceFilterMeters: CLLocationDistance = 10

  // 基地局ベースなどの粗い位置は経路を乱すため保存しない
  private static let maxAccuracyMeters: CLLocationAccuracy = 200

  // 現在地を追従するジオフェンス
  private static let regionIdentifier = "auto_diary_ai.current_area"
  private static let regionRadiusMeters: CLLocationDistance = 100
  private static let regionRecenterMeters: CLLocationDistance = 50

  private let manager = CLLocationManager()
  private var channel: FlutterMethodChannel?
  private var lastSavedLine: String?
  private var regionCenter: CLLocation?

  private lazy var directory: URL = {
    let base = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0]
    let directory = base.appendingPathComponent("location_recorder", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    return directory
  }()

  // まだDart側に渡していない位置情報
  private var pendingURL: URL { directory.appendingPathComponent("pending.csv") }

  // Dart側に渡したが、Isarへの保存完了がまだ通知されていない位置情報
  private var drainingURL: URL { directory.appendingPathComponent("draining.csv") }

  private var isEnabled: Bool {
    UserDefaults.standard.bool(forKey: LocationRecorder.enabledKey)
  }

  private var authorizationStatus: CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return manager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private override init() {
    super.init()
    manager.delegate = self
  }

  func registerChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: LocationRecorder.channelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "start":
        self.start()
        result(nil)
      case "drain":
        result(self.drain())
      case "confirmDrain":
        try? FileManager.default.removeItem(at: self.drainingURL)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    self.channel = channel
  }

  /// 記録を開始する(Dart側で位置情報が許可された後に呼ばれる)
  func start() {
    UserDefaults.standard.set(true, forKey: LocationRecorder.enabledKey)

    // 完全終了後の再起動には「常に許可」が必要なため、「使用中のみ」から切り替えを求める
    if authorizationStatus == .authorizedWhenInUse {
      manager.requestAlwaysAuthorization()
    }

    startServices()
  }

  func resumeIfEnabled() {
    if isEnabled {
      startServices()
    }
  }

  private func startServices() {
    let status = authorizationStatus
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      return
    }

    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = LocationRecorder.distanceFilterMeters
    manager.pausesLocationUpdatesAutomatically = false
    manager.allowsBackgroundLocationUpdates = true
    manager.showsBackgroundLocationIndicator = true

    // 完全終了後もOSがアプリを再起動して通知してくれる
    manager.startMonitoringSignificantLocationChanges()

    // 滞在の到着・出発を受け取る(完全終了後もOSがアプリを再起動して通知してくれる)
    manager.startMonitoringVisits()

    // アプリが動いている間(バックグラウンド含む)は通常の精度で記録する
    manager.startUpdatingLocation()
  }

  /// 現在地を中心にジオフェンスを置き直す
  /// 完全終了後にこの円から出ると、OSがアプリを再起動して記録を再開できる
  private func updateRegion(around location: CLLocation) {
    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
      return
    }

    // 中心からあまり動いていない間は登録し直さない
    if let center = currentRegionCenter(),
      location.distance(from: center) < LocationRecorder.regionRecenterMeters
    {
      return
    }

    let region = CLCircularRegion(
      center: location.coordinate,
      radius: min(LocationRecorder.regionRadiusMeters, manager.maximumRegionMonitoringDistance),
      identifier: LocationRecorder.regionIdentifier
    )
    region.notifyOnEntry = false
    region.notifyOnExit = true

    // 同じidentifierで登録すると前の円は置き換わるため、監視数は常に1つ
    manager.startMonitoring(for: region)
    regionCenter = location
  }

  private func currentRegionCenter() -> CLLocation? {
    if let regionCenter = regionCenter {
      return regionCenter
    }

    // 再起動直後は、前回登録した円がOS側に残っている
    for region in manager.monitoredRegions {
      if region.identifier == LocationRecorder.regionIdentifier,
        let circular = region as? CLCircularRegion
      {
        return CLLocation(
          latitude: circular.center.latitude,
          longitude: circular.center.longitude
        )
      }
    }

    return nil
  }

  private func line(for coordinate: CLLocationCoordinate2D, at date: Date) -> String {
    let milliseconds = Int64(date.timeIntervalSince1970 * 1000)
    return "\(coordinate.latitude),\(coordinate.longitude),\(milliseconds)"
  }

  private func isAccurate(_ accuracy: CLLocationAccuracy) -> Bool {
    return accuracy >= 0 && accuracy <= LocationRecorder.maxAccuracyMeters
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    var text = ""
    var latest: CLLocation?

    for location in locations where isAccurate(location.horizontalAccuracy) {
      let line = self.line(for: location.coordinate, at: location.timestamp)
      latest = location

      // 重要な位置変更通知と通常の位置更新で同じ位置が届いた場合は1件にする
      if line == lastSavedLine {
        continue
      }

      lastSavedLine = line
      text += line + "\n"
    }

    if !text.isEmpty {
      append(text, to: pendingURL)
    }

    if let latest = latest {
      updateRegion(around: latest)
    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    // 完全終了後にここへ来た場合、起動処理ですでに記録は再開している。
    // 次に届く位置で、ジオフェンスは新しい現在地へ置き直される
    resumeIfEnabled()
  }

  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    guard isAccurate(visit.horizontalAccuracy) else {
      return
    }

    var text = ""

    // 滞在は「到着時」と「出発時」の2回通知されるため、到着は1回だけ保存する
    if visit.arrivalDate != Date.distantPast {
      let arrival = visit.arrivalDate.timeIntervalSince1970
      let defaults = UserDefaults.standard

      if defaults.double(forKey: LocationRecorder.lastVisitArrivalKey) != arrival {
        defaults.set(arrival, forKey: LocationRecorder.lastVisitArrivalKey)
        text += line(for: visit.coordinate, at: visit.arrivalDate) + "\n"
      }
    }

    if visit.departureDate != Date.distantFuture {
      text += line(for: visit.coordinate, at: visit.departureDate) + "\n"
    }

    if !text.isEmpty {
      append(text, to: pendingURL)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  ) {
    NSLog("LocationRecorder: \(error.localizedDescription)")
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    resumeIfEnabled()
  }

  // iOS13以前
  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    resumeIfEnabled()
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    NSLog("LocationRecorder: \(error.localizedDescription)")
  }

  // MARK: - 保存

  private func append(_ text: String, to url: URL) {
    guard let data = text.data(using: .utf8) else {
      return
    }

    if let handle = try? FileHandle(forWritingTo: url) {
      if #available(iOS 13.4, *) {
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
      } else {
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
      }
    } else {
      try? data.write(to: url, options: .atomic)
    }
  }

  /// 溜まっている位置情報をDart側へ渡す
  /// Dart側の保存完了(confirmDrain)まではファイルを残し、途中で失敗しても失われないようにする
  private func drain() -> [[String: Any]] {
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: pendingURL.path) {
      if fileManager.fileExists(atPath: drainingURL.path) {
        if let text = try? String(contentsOf: pendingURL, encoding: .utf8) {
          append(text, to: drainingURL)
          try? fileManager.removeItem(at: pendingURL)
        }
      } else {
        try? fileManager.moveItem(at: pendingURL, to: drainingURL)
      }
    }

    guard let text = try? String(contentsOf: drainingURL, encoding: .utf8) else {
      return []
    }

    return text.split(separator: "\n").compactMap { line -> [String: Any]? in
      let parts = line.split(separator: ",")

      guard parts.count == 3,
        let latitude = Double(parts[0]),
        let longitude = Double(parts[1]),
        let milliseconds = Int64(parts[2])
      else {
        return nil
      }

      return [
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": milliseconds,
      ]
    }
  }
}

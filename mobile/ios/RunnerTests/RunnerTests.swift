import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testPrivateDirectoryAndLegacyMarkerAreExcludedFromBackup() throws {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("pluris-haven-backup-test-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let support = root.appendingPathComponent("Application Support", isDirectory: true)
    let documents = root.appendingPathComponent("Documents", isDirectory: true)
    try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    let legacyMarker = documents.appendingPathComponent(".pluris-haven-master-key-v1")
    try Data("provisioned".utf8).write(to: legacyMarker)

    try PrivateBackupExclusion.excludeDirectory(support)
    try PrivateBackupExclusion.excludeExistingFile(legacyMarker)

    XCTAssertEqual(
      try support.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup,
      true
    )
    XCTAssertEqual(
      try legacyMarker.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup,
      true
    )
  }

}

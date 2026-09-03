import AVFoundation
@preconcurrency import XCTest
@testable import Soundable

final class SoundableTests: XCTestCase {
    @MainActor
    func testInvalidSoundReportsWrongURL() {
        defer { resetSoundable() }
        let sound = Sound(fileName: "missing-sound.wav", bundle: .main)
        var receivedReason: SBError.PlayingFailureReason?

        sound.play { error in
            if case let SBError.playingFailed(reason)? = error {
                receivedReason = reason
            }
        }

        guard case .wrongUrl? = receivedReason else {
            return XCTFail("Expected wrongUrl, received \(String(describing: receivedReason))")
        }
    }

    @MainActor
    func testVolumeLoopsAndMuteRestore() throws {
        defer { resetSoundable() }
        let sound = Sound(url: try makeTemporaryWaveFile())

        sound.volume = 0.35
        sound.loopsCount = 2
        XCTAssertEqual(sound.volume, 0.35, accuracy: 0.001)
        XCTAssertEqual(sound.loopsCount, 2)

        sound.mute()
        XCTAssertTrue(sound.isMuted)
        sound.unmute()
        XCTAssertEqual(sound.volume, 0.35, accuracy: 0.001)
    }

    @MainActor
    func testDuplicateURLsHaveIndependentRegistryEntries() throws {
        defer { resetSoundable() }
        let url = try makeTemporaryWaveFile()
        let first = Sound(url: url)
        let second = Sound(url: url)

        XCTAssertNotEqual(first.identifier, second.identifier)
        Soundable.addPlayableItem(first)
        Soundable.addPlayableItem(second)
        XCTAssertEqual(Soundable.playingItemCount, 2)

        Soundable.removePlayableItem(first)
        XCTAssertEqual(Soundable.playingItemCount, 1)
    }

    @MainActor
    func testEmptyQueueReportsNoSounds() {
        defer { resetSoundable() }
        let queue = SoundsQueue(sounds: [])
        var receivedReason: SBError.PlayingFailureReason?

        queue.play { error in
            if case let SBError.playingFailed(reason)? = error {
                receivedReason = reason
            }
        }

        guard case .noSoundsToPlay? = receivedReason else {
            return XCTFail("Expected noSoundsToPlay, received \(String(describing: receivedReason))")
        }
    }

    @MainActor
    func testQueueIgnoresUnrelatedPlayerItemNotification() async throws {
        defer { resetSoundable() }
        let sound = Sound(url: try makeTemporaryWaveFile())
        let queue = SoundsQueue(sounds: [sound])
        let completion = expectation(description: "Queue must not complete")
        completion.isInverted = true

        queue.play { _ in completion.fulfill() }
        let unrelatedItem = AVPlayerItem(url: try makeTemporaryWaveFile())
        NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: unrelatedItem)

        await fulfillment(of: [completion], timeout: 0.1)
        queue.stop()
    }

    @MainActor
    func testQueueCompletesOnceAndCanReplay() async throws {
        defer { resetSoundable() }
        let sound = Sound(url: try makeTemporaryWaveFile())
        let queue = SoundsQueue(sounds: [sound])

        for attempt in 1...2 {
            let completion = expectation(description: "Completion \(attempt)")
            queue.play { error in
                XCTAssertNil(error)
                completion.fulfill()
            }

            let item = try XCTUnwrap(queue.queuePlayer?.items().first)
            NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            await fulfillment(of: [completion], timeout: 1)
            XCTAssertEqual(Soundable.playingItemCount, 0)
        }
    }

    @MainActor
    func testQueueFailureReturnsPlaybackFailure() async throws {
        defer { resetSoundable() }
        let sound = Sound(url: try makeTemporaryWaveFile())
        let queue = SoundsQueue(sounds: [sound])
        let completion = expectation(description: "Failure completion")

        queue.play { error in
            guard case let SBError.playingFailed(reason)? = error,
                  case .playbackFailed = reason else {
                return XCTFail("Expected playbackFailed, received \(String(describing: error))")
            }
            completion.fulfill()
        }

        let item = try XCTUnwrap(queue.queuePlayer?.items().first)
        NotificationCenter.default.post(name: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
        await fulfillment(of: [completion], timeout: 1)
    }

    @MainActor
    func testStoppingQueueSuppressesCompletion() throws {
        defer { resetSoundable() }
        let sound = Sound(url: try makeTemporaryWaveFile())
        let queue = SoundsQueue(sounds: [sound])
        var didComplete = false

        queue.play { _ in didComplete = true }
        queue.stop()

        XCTAssertFalse(didComplete)
        XCTAssertEqual(Soundable.playingItemCount, 0)
    }

    @MainActor
    func testArraySliceSequenceCanPlay() throws {
        defer { resetSoundable() }
        let sounds = [Sound(url: try makeTemporaryWaveFile())]
        sounds[...].play()
        XCTAssertEqual(Soundable.playingItemCount, 1)
    }

    @MainActor
    func testLegacySoundEnabledStringMigratesToBoolean() {
        defer { resetSoundable() }
        let defaults = UserDefaults.standard
        defaults.set("false", forKey: SoundableKey.SoundEnabled)

        Soundable.reloadSoundEnabledForTesting()

        XCTAssertFalse(Soundable.soundEnabled)
        XCTAssertEqual(defaults.object(forKey: SoundableKey.SoundEnabled) as? Bool, false)
    }

    @MainActor
    func testInterruptionObserverSurvivesMultipleNotifications() async {
        defer { resetSoundable() }
        let completion = expectation(description: "Both interruptions delivered")
        completion.expectedFulfillmentCount = 2

        Soundable.observeInterruptions { _, _ in completion.fulfill() }
        for rawValue in [
            AVAudioSession.InterruptionType.began.rawValue,
            AVAudioSession.InterruptionType.ended.rawValue
        ] {
            NotificationCenter.default.post(
                name: AVAudioSession.interruptionNotification,
                object: nil,
                userInfo: [AVAudioSessionInterruptionTypeKey: rawValue]
            )
        }

        await fulfillment(of: [completion], timeout: 1)
    }

    private func makeTemporaryWaveFile() throws -> URL {
        let bytes: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, 0x25, 0x00, 0x00, 0x00,
            0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
            0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
            0x40, 0x1F, 0x00, 0x00, 0x40, 0x1F, 0x00, 0x00,
            0x01, 0x00, 0x08, 0x00, 0x64, 0x61, 0x74, 0x61,
            0x01, 0x00, 0x00, 0x00, 0x80
        ]
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        try Data(bytes).write(to: url, options: .atomic)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    @MainActor
    private func resetSoundable() {
        Soundable.soundEnabled = true
        Soundable.stopAll()
    }
}

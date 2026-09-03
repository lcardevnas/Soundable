//
//  SoundsQueue.swift
//
//  Copyright © 2018 Luis Cardenas. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AVFoundation

/// An object that plays multiple sounds in sequence.
@MainActor
public final class SoundsQueue: Playable {
    /// The queue player that plays the queued sounds.
    var queuePlayer: AVQueuePlayer?

    public var groupKey: String = SoundableKey.DefaultGroupKey
    public var identifier = UUID().uuidString
    public var loopsCount = 0

    /// Retained for source compatibility with `Playable`. Queue playback uses
    /// the URLs of its component sounds.
    public var url: URL?

    private let sounds: [Sound]
    private var observedItems: [AVPlayerItem] = []
    private var pendingNumberOfSoundsToPlay = 0
    private var numberOfLoopsPlayed = 0
    private var completion: SoundCompletion?
    private var volumeBeforeMuting: Float = 1.0

    public var volume: Float {
        get { queuePlayer?.volume ?? 1.0 }
        set {
            queuePlayer?.volume = newValue
            if newValue > 0 {
                volumeBeforeMuting = newValue
            }
        }
    }

    public var isMuted: Bool {
        queuePlayer?.volume == 0.0
    }

    private init() {
        sounds = []
    }

    /// Creates a queue containing the valid sounds in `sounds`.
    public init(sounds: [Sound]) {
        self.sounds = sounds.filter { $0.player != nil }
        createPlayer()
    }

    public func play(
        groupKey: String? = nil,
        loopsCount: Int = 0,
        completion: SoundCompletion? = nil
    ) {
        guard Soundable.soundEnabled else {
            completion?(SBError.playingFailed(reason: .audioDisabled))
            return
        }

        guard !sounds.isEmpty else {
            completion?(SBError.playingFailed(reason: .noSoundsToPlay))
            return
        }

        self.groupKey = groupKey ?? SoundableKey.DefaultGroupKey
        self.loopsCount = loopsCount
        self.completion = completion
        numberOfLoopsPlayed = 0

        if pendingNumberOfSoundsToPlay == 0 || queuePlayer?.items().isEmpty != false {
            createPlayer()
        }

        Soundable.addPlayableItem(self)
        queuePlayer?.play()
    }

    public func pause() {
        queuePlayer?.pause()
    }

    public func stop() {
        completion = nil
        resetPlayer()
        unmute()
        Soundable.removePlayableItem(self)
    }

    public func mute() {
        if let currentVolume = queuePlayer?.volume, currentVolume > 0 {
            volumeBeforeMuting = currentVolume
        }
        queuePlayer?.volume = 0.0
    }

    public func unmute() {
        if queuePlayer?.volume == 0.0 {
            queuePlayer?.volume = volumeBeforeMuting
        }
    }

    @objc
    nonisolated private func playerItemDidReachEnd(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.handlePlayerItemDidReachEnd()
        }
    }

    @objc
    nonisolated private func playerItemFailedToReachEnd(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.finish(with: SBError.playingFailed(reason: .playbackFailed))
        }
    }

    private func handlePlayerItemDidReachEnd() {
        guard completion != nil || Soundable.containsPlayableItem(self) else { return }

        pendingNumberOfSoundsToPlay -= 1
        guard pendingNumberOfSoundsToPlay <= 0 else { return }

        if loopsCount == -1 || numberOfLoopsPlayed < loopsCount {
            numberOfLoopsPlayed += 1
            createPlayer()
            queuePlayer?.play()
        } else {
            finish(with: nil)
        }
    }

    private func createPlayer() {
        let wasMuted = isMuted
        removeItemObservers()

        let items = sounds.compactMap { sound in
            sound.url.map(AVPlayerItem.init(url:))
        }

        observedItems = items
        pendingNumberOfSoundsToPlay = items.count
        queuePlayer = AVQueuePlayer(items: items)
        queuePlayer?.volume = wasMuted ? 0.0 : volumeBeforeMuting

        for item in items {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidReachEnd),
                name: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemFailedToReachEnd),
                name: AVPlayerItem.failedToPlayToEndTimeNotification,
                object: item
            )
        }
    }

    private func removeItemObservers() {
        for item in observedItems {
            NotificationCenter.default.removeObserver(
                self,
                name: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )
            NotificationCenter.default.removeObserver(
                self,
                name: AVPlayerItem.failedToPlayToEndTimeNotification,
                object: item
            )
        }
        observedItems.removeAll()
    }

    private func resetPlayer() {
        removeItemObservers()
        queuePlayer?.removeAllItems()
        queuePlayer = nil
        pendingNumberOfSoundsToPlay = 0
        numberOfLoopsPlayed = 0
    }

    private func finish(with error: Error?) {
        let pendingCompletion = completion
        completion = nil
        resetPlayer()
        Soundable.removePlayableItem(self)
        unmute()
        pendingCompletion?(error)
    }
}

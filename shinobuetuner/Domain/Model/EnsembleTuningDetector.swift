//
//  EnsembleTuningDetector.swift
//  shinobuetuner
//
//  spectrumPublisher を受け取り、アンサンブルモニタリングの
//  チューニング判定結果を publish するクラス

import Combine
import Foundation

/// アンサンブルモニタリングのチューニング判定結果
struct EnsembleTuningState {
    /// 検出周波数 (Hz)
    let detectedFrequency: Float
    /// 基準音からのズレ (セント)
    let centsDeviation: Float
    /// スペクトル幅（ビン数）：小さいほど全員のピッチが揃っている
    let spectralWidth: Float
    /// チューニング成功フラグ（3条件の瞬時判定）
    let isInTune: Bool
    /// 安定性スコア（過去フレームのセント標準偏差）
    let stabilityScore: Float
}

/// アンサンブルモニタリングのチューニング判定を行うクラス
final class EnsembleTuningDetector {
    private let subject = PassthroughSubject<EnsembleTuningState, Never>()

    /// 外部公開用パブリッシャー（TunerViewModel が subscribe する）
    var publisher: AnyPublisher<EnsembleTuningState, Never> {
        subject.eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    /// セント偏差のリングバッファ（安定性スコア計算用）
    private var centsBuffer: [Float] = []

    /// アンサンブルモニタリングを開始する
    /// - Parameters:
    ///   - spectrumPublisher: MicrophoneDataSource → PitchRepository → MonitorPitchUseCase 経由のスペクトル情報
    ///   - settings: チューニング判定閾値（centThreshold / ensembleSpectralWidthThreshold / ensembleStabilityScoreThreshold）
    func start(
        spectrumPublisher: AnyPublisher<(pitch: Float, magnitudes: [Float], binWidth: Float), Never>,
        settings: TunerSettings
    ) {
        spectrumPublisher
            .sink { [weak self] data in
                guard let self else { return }
                let state = self.process(
                    pitch: data.pitch,
                    magnitudes: data.magnitudes,
                    binWidth: data.binWidth,
                    settings: settings
                )
                Task { @MainActor [weak self] in
                    self?.subject.send(state)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 内部処理

    private func process(
        pitch: Float,
        magnitudes: [Float],
        binWidth: Float,
        settings: TunerSettings
    ) -> EnsembleTuningState {
        // 無音・不正値はゼロ値を返す（binWidth=0 でのゼロ除算、pitch の NaN/Inf を防ぐ）
        guard pitch > 0, pitch.isFinite, binWidth > 0, !magnitudes.isEmpty else {
            centsBuffer.removeAll()
            return EnsembleTuningState(
                detectedFrequency: 0,
                centsDeviation: 0,
                spectralWidth: 0,
                isInTune: false,
                stabilityScore: 0
            )
        }

        // ① centsDeviation を計算
        let centsDeviation = NoteHelper.closestNote(for: pitch)?.cents ?? 0

        // リングバッファにセント値を追加（最大 ensembleBufferSize フレーム）
        centsBuffer.append(centsDeviation)
        if centsBuffer.count > AudioConstants.ensembleBufferSize {
            centsBuffer.removeFirst()
        }

        // ② stabilityScore（過去フレームのセント標準偏差）を計算
        let stabilityScore: Float
        if centsBuffer.count > 1 {
            let mean = centsBuffer.reduce(0, +) / Float(centsBuffer.count)
            let variance = centsBuffer.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(centsBuffer.count)
            stabilityScore = sqrt(variance)
        } else {
            stabilityScore = 0
        }

        // ③ spectralWidth（ピーク付近の -6dB 幅）を計算
        let peakBin = max(0, min(Int(pitch / binWidth), magnitudes.count - 1))
        let threshold = magnitudes[peakBin] * 0.5
        var left = peakBin
        var right = peakBin
        while left > 0 && magnitudes[left] > threshold { left -= 1 }
        while right < magnitudes.count - 1 && magnitudes[right] > threshold { right += 1 }
        let spectralWidth = Float(right - left)

        // 3条件の瞬時判定
        let isInTune =
            abs(centsDeviation) <= Float(settings.centThreshold) &&
            spectralWidth <= settings.ensembleSpectralWidthThreshold &&
            stabilityScore <= settings.ensembleStabilityScoreThreshold

        return EnsembleTuningState(
            detectedFrequency: pitch,
            centsDeviation: centsDeviation,
            spectralWidth: spectralWidth,
            isInTune: isInTune,
            stabilityScore: stabilityScore
        )
    }
}

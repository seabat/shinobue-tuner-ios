//
//  TunerSettingsRepositoryImpl.swift
//  shinobuetuner
//
//  TunerSettingsRepository の UserDefaults 実装

import Foundation

/// TunerSettingsRepository の UserDefaults を使った具体実装
final class TunerSettingsRepositoryImpl: TunerSettingsRepository {
    private enum Keys {
        static let centThreshold   = "tuningCentThreshold"
        static let durationSeconds = "tuningDurationSeconds"
        static let tuning          = "selectedTuning"
        static let showPitchGraph  = "showPitchGraph"
        static let ensembleSpectralWidthThreshold  = "ensembleSpectralWidthThreshold"
        static let ensembleStabilityScoreThreshold = "ensembleStabilityScoreThreshold"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() -> TunerSettings {
        let savedCent           = defaults.double(forKey: Keys.centThreshold)
        let savedDuration       = defaults.double(forKey: Keys.durationSeconds)
        let savedTuning         = defaults.integer(forKey: Keys.tuning)
        // showPitchGraph は未保存時に object が nil → デフォルト true
        let savedGraph          = defaults.object(forKey: Keys.showPitchGraph) as? Bool ?? true
        let savedSpectralWidth  = defaults.double(forKey: Keys.ensembleSpectralWidthThreshold)
        let savedStabilityScore = defaults.double(forKey: Keys.ensembleStabilityScoreThreshold)

        return TunerSettings(
            centThreshold:                    savedCent           > 0 ? savedCent           : 10.0,
            durationSeconds:                  savedDuration       > 0 ? savedDuration       : 1.0,
            tuning:                           ShinobueTuning(rawValue: savedTuning) ?? .rokuHon,
            showPitchGraph:                   savedGraph,
            ensembleSpectralWidthThreshold:   savedSpectralWidth  > 0 ? Float(savedSpectralWidth)  : 5.0,
            ensembleStabilityScoreThreshold:  savedStabilityScore > 0 ? Float(savedStabilityScore) : 10.0
        )
    }

    func save(_ settings: TunerSettings) {
        defaults.set(settings.centThreshold,                    forKey: Keys.centThreshold)
        defaults.set(settings.durationSeconds,                  forKey: Keys.durationSeconds)
        defaults.set(settings.tuning.rawValue,                  forKey: Keys.tuning)
        defaults.set(settings.showPitchGraph,                   forKey: Keys.showPitchGraph)
        defaults.set(settings.ensembleSpectralWidthThreshold,   forKey: Keys.ensembleSpectralWidthThreshold)
        defaults.set(settings.ensembleStabilityScoreThreshold,  forKey: Keys.ensembleStabilityScoreThreshold)
    }
}

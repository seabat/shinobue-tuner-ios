## アーキテクチャ

**MVVM + Clean Architecture**（Presentation / Domain / Data の3層構成）

```
Presentation ──依存──▶ Domain ◀──依存── Data
```

```
shinobuetuner/
├── Domain/        # Model / Repository Protocol / UseCase
├── Data/          # DataSource（AVAudioEngine, FFT） / Repository 実装
└── Presentation/  # ViewModel / View
    └── View/
        ├── Turner/         # チューナー画面
        ├── Playback/       # 録音一覧・再生
        └── FrequencyTable/ # 音階周波数表
```



## 作業ルール

- **実装・修正の前に必ずプランを提示し、ユーザーの承認を得てから着手する**
- 調査・ファイル読み取りのみの操作はプランなしで進めてよい

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



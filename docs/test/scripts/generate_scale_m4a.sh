#!/bin/zsh
#
# generate_scale_m4a.sh
#
# 篠笛の音階（移動ドの ド レ ミ ファ ソ ラ シ ド）を1音1秒ずつ鳴らすテスト用 .m4a を ffmpeg で生成する
# TunerMainScreen の結合テスト（Maestro）とピッチ検出の単体テストで使う
#
# 使い方: docs/test/scripts/generate_scale_m4a.sh <6|8> [出力先]
#   6 = 六本調子（B♭5 C6 D6 E♭6 F6 G6 A6 B♭6）
#   8 = 八本調子（C6 D6 E6 F6 G6 A6 B6 C7）
#   出力先の省略時は shinobuetunerTests/Resources/{rokuhon,hachihon}_scale.m4a

set -euo pipefail

TUNING="${1:-}"
case "$TUNING" in
  6) NAME="rokuhon" ;;
  8) NAME="hachihon" ;;
  *) echo "使い方: $0 <6|8> [出力先]" >&2; exit 1 ;;
esac

SCRIPT_DIR="${0:A:h}"
OUTPUT="${2:-$SCRIPT_DIR/../../../shinobuetunerTests/Resources/${NAME}_scale.m4a}"
mkdir -p "${OUTPUT:h}"

# 六本調子の ド〜ド の MIDI 番号（B♭5=82 から長音階）。八本調子は +2 半音ずらす（運指は調子によらず共通）
OFFSET=$(( TUNING - 6 ))
MIDI_NOTES=(82 84 86 87 89 91 93 94)

# A4 = 442 Hz の12平均律で各音の周波数を求める
FREQS=()
for midi in "${MIDI_NOTES[@]}"; do
  FREQS+=("$(awk -v m=$(( midi + OFFSET )) 'BEGIN { printf "%.3f", 442 * 2 ^ ((m - 69) / 12) }')")
done

# 時刻 t に応じて周波数を切り替える式: if(lt(t,1),f0,if(lt(t,2),f1,...f7))
FREQ_EXPR="${FREQS[8]}"
for i in {7..1}; do
  FREQ_EXPR="if(lt(t,$i),${FREQS[$i]},$FREQ_EXPR)"
done

# 1音ごとに先頭・末尾 20ms のフェードをかけ、切り替わり時のクリックノイズを防ぐ
ENV="min(1,min(mod(t,1)/0.02,(1-mod(t,1))/0.02))"
# HPS（倍音積スペクトル法）で基音を検出できるよう、第2・第3倍音を含めた篠笛風の音にする
TONE="0.5*sin(2*PI*F*t)+0.25*sin(4*PI*F*t)+0.15*sin(6*PI*F*t)"
EXPR="${ENV}*(${TONE//F/($FREQ_EXPR)})"

ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "aevalsrc=exprs='${EXPR}':s=48000:d=8" \
  -ac 1 -c:a aac -b:a 128k "$OUTPUT"

echo "生成しました: $OUTPUT"
echo "周波数(Hz): ${FREQS[*]}"

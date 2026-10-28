"""App Store「ヘッダと検索結果」用の画像を生成する。

- ヘッダ: 3840 x 1646 (21:9)
- 検索結果: 3840 x 2560 (3:2)
いずれも透過なし PNG。2倍の解像度で描画して縮小し、アンチエイリアスをかける。

使い方（Pillow が必要。フォントは macOS 標準のヒラギノ角ゴシック・SF を使う）:
    python3 docs/appstore/make_store_assets.py docs/appstore
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 2  # スーパーサンプリング倍率
OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)

# アイコンから採取した配色
NAVY = (20, 22, 35)
NAVY_LIGHT = (34, 38, 60)
GOLD = (228, 198, 110)
GOLD_LIGHT = (243, 226, 170)
GOLD_DARK = (176, 142, 62)
HOLE = (90, 5, 26)
WHITE = (245, 245, 250)
GRAY = (150, 155, 175)
GREEN = (52, 199, 89)

HIRA_W6 = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
HIRA_W3 = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"
SFNS = "/System/Library/Fonts/SFNS.ttf"


def font(path, size, variation=None):
    f = ImageFont.truetype(path, size * SS)
    if variation:
        try:
            f.set_variation_by_name(variation)
        except Exception:
            pass
    return f


def background(w, h, cy_ratio=0.45):
    """中央がわずかに明るい濃紺の背景"""
    img = Image.new("RGB", (w, h), NAVY)
    glow = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(glow)
    rw, rh = w * 0.42, h * 0.55
    cx, cy = w / 2, h * cy_ratio
    d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(min(w, h) * 0.18))
    img.paste(Image.new("RGB", (w, h), NAVY_LIGHT), mask=glow)
    return img


def draw_flute(length, thickness):
    """横向きの篠笛（アイコンのデザインに合わせた金色の竹と赤い指孔）"""
    pad = thickness
    layer = Image.new("RGBA", (int(length + pad * 2), int(thickness + pad * 2)), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0 = pad, pad
    x1, y1 = pad + length, pad + thickness
    r = thickness * 0.18
    # 本体
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=GOLD)
    # 上側のハイライト・下側の陰
    d.rounded_rectangle([x0 + r, y0 + thickness * 0.10, x1 - r, y0 + thickness * 0.30], radius=thickness * 0.1, fill=GOLD_LIGHT)
    d.rectangle([x0 + r, y1 - thickness * 0.16, x1 - r, y1 - thickness * 0.04], fill=(208, 176, 92))
    # 両端の巻き（濃い金）
    cap = thickness * 0.38
    d.rounded_rectangle([x0, y0, x0 + cap, y1], radius=r, fill=GOLD_DARK)
    d.rounded_rectangle([x1 - cap, y0, x1, y1], radius=r, fill=GOLD_DARK)
    d.rectangle([x0 + cap * 0.45, y0, x0 + cap * 0.6, y1], fill=GOLD)
    d.rectangle([x1 - cap * 0.6, y0, x1 - cap * 0.45, y1], fill=GOLD)
    # 節
    jx = x0 + length * 0.30
    lw = max(2, int(thickness * 0.06))
    d.line([jx, y0, jx, y1], fill=GOLD_DARK, width=lw)
    d.line([jx + thickness * 0.14, y0, jx + thickness * 0.14, y1], fill=GOLD_DARK, width=lw)
    # 歌口（楕円・縁取りあり）
    bx = x0 + length * 0.12
    bw, bh = thickness * 0.62, thickness * 0.46
    d.ellipse([bx - bw / 2 - thickness * 0.07, (y0 + y1) / 2 - bh / 2 - thickness * 0.07,
               bx + bw / 2 + thickness * 0.07, (y0 + y1) / 2 + bh / 2 + thickness * 0.07], fill=(200, 160, 90))
    d.ellipse([bx - bw / 2, (y0 + y1) / 2 - bh / 2, bx + bw / 2, (y0 + y1) / 2 + bh / 2], fill=HOLE)
    # 指孔 7つ
    hr = thickness * 0.2
    start, step = x0 + length * 0.47, length * 0.068
    for i in range(7):
        hx = start + step * i
        d.ellipse([hx - hr, (y0 + y1) / 2 - hr, hx + hr, (y0 + y1) / 2 + hr], fill=HOLE)
    return layer


def paste_with_shadow(img, layer, cx, cy, angle=0):
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    shadow.putalpha(layer.getchannel("A").point(lambda a: int(a * 0.55)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(layer.size[1] * 0.06 if not angle else 30 * SS))
    ox, oy = int(cx - layer.size[0] / 2), int(cy - layer.size[1] / 2)
    img.paste(shadow, (ox + 10 * SS, oy + 24 * SS), shadow)
    img.paste(layer, (ox, oy), layer)


def meter_color(t):
    """セントメーターのグラデーション（t: 0〜1、中央 0.5 が緑）"""
    stops = [(0.0, (255, 69, 58)), (0.25, (255, 204, 0)), (0.5, GREEN), (0.75, (255, 204, 0)), (1.0, (255, 69, 58))]
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t <= t1:
            k = (t - t0) / (t1 - t0)
            return tuple(int(c0[i] + (c1[i] - c0[i]) * k) for i in range(3))
    return stops[-1][1]


def _needle_segment(cx, cy, ux, uy, r0, r1, width):
    """ピボットからの距離 r0〜r1 を幅 width の帯として結ぶ四角形の頂点を返す"""
    px, py = -uy, ux  # 進行方向に垂直な単位ベクトル
    hw = width / 2
    return [
        (cx + ux * r0 + px * hw, cy + uy * r0 + py * hw),
        (cx + ux * r1 + px * hw, cy + uy * r1 + py * hw),
        (cx + ux * r1 - px * hw, cy + uy * r1 - py * hw),
        (cx + ux * r0 - px * hw, cy + uy * r0 - py * hw),
    ]


def draw_gauge(img, cx, cy, radius, stroke, cents, label_font, main_height):
    """アプリのチューナーゲージ（半円タコメーター）を描く。

    cx, cy はピボット（針の回転中心）。cents は針が指すセント値（-50〜+50）。
    main_height は中央に置く階名の行高さで、針を細くする区間の算出に使う。
    """
    d = ImageDraw.Draw(img)
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]

    # アーク: 180°(9時) 〜 360°(3時) を細かく分割して角度グラデーションにする
    steps = 540
    for i in range(steps):
        a0 = 180 + 180 * i / steps
        a1 = 180 + 180 * (i + 1) / steps + 0.4  # わずかに重ねて継ぎ目を消す
        d.arc(bbox, a0, a1, fill=meter_color(i / (steps - 1)), width=int(stroke))

    # 目盛り線とラベル
    label_r = radius + stroke / 2 + 80 * SS
    for cent, label in [(-50, "-50"), (-25, "-25"), (0, "0"), (25, "+25"), (50, "+50")]:
        ang = math.radians(cent / 50 * 90)
        ux, uy = math.sin(ang), -math.cos(ang)
        d.polygon(_needle_segment(cx, cy, ux, uy, radius - 22 * SS, radius + 22 * SS, 12 * SS),
                  fill=(255, 255, 255, 180))
        d.text((cx + label_r * ux, cy + label_r * uy), label, font=label_font, fill=GRAY, anchor="mm")

    # 針: 先端(太) → 階名に重なる区間(細) → ハブ側(太)
    ang = math.radians(cents / 50 * 90)
    ux, uy = math.sin(ang), -math.cos(ang)
    length = radius + stroke / 2 - 20 * SS
    center_off = radius * 0.44           # 中央テキストの位置（アプリと同じ比率）
    thin_lo = center_off - main_height / 2
    thin_hi = center_off + main_height / 2
    thick_w, thin_w = radius * 0.040, radius * 0.016
    d.polygon(_needle_segment(cx, cy, ux, uy, thin_hi, length, thick_w), fill=WHITE)
    d.polygon(_needle_segment(cx, cy, ux, uy, thin_lo, thin_hi, thin_w), fill=(255, 255, 255, 115))
    d.polygon(_needle_segment(cx, cy, ux, uy, 0, thin_lo, thick_w), fill=WHITE)
    hub = radius * 0.056
    d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub], fill=WHITE)


def text(d, xy, s, f, fill):
    d.text(xy, s, font=f, fill=fill, anchor="mm")


def make_header(lang):
    w, h = 3840 * SS, 1646 * SS
    img = background(w, h, cy_ratio=0.42).convert("RGBA")
    d = ImageDraw.Draw(img)
    if lang == "ja":
        text(d, (w / 2, 330 * SS), "篠笛専用チューナー", font(HIRA_W6, 180), WHITE)
        text(d, (w / 2, 520 * SS), "六本調子・八本調子に対応　A4 = 442 Hz", font(HIRA_W3, 84), GOLD)
    else:
        text(d, (w / 2, 330 * SS), "The Tuner Made for Shinobue", font(SFNS, 150, "Bold"), WHITE)
        text(d, (w / 2, 520 * SS), "Supports No. 6 & No. 8 keys  ·  A4 = 442 Hz", font(SFNS, 84, "Regular"), GOLD)
    flute = draw_flute(2700 * SS, 150 * SS)
    paste_with_shadow(img, flute, w / 2, 860 * SS)
    out = img.convert("RGB").resize((3840, 1646), Image.LANCZOS)
    out.save(OUT / f"header_{lang}.png")


def make_search(lang):
    w, h = 3840 * SS, 2560 * SS
    img = background(w, h, cy_ratio=0.5).convert("RGBA")
    d = ImageDraw.Draw(img)
    if lang == "ja":
        text(d, (w / 2, 290 * SS), "篠笛専用チューナー", font(HIRA_W6, 210), WHITE)
        text(d, (w / 2, 500 * SS), "六本調子・八本調子に対応　A4 = 442 Hz", font(HIRA_W3, 96), GOLD)
        solfege = "ド"
        chips = ["音階名・運指名を選択", "セントメーター", "ピッチグラフ", "録音・再生"]
        chip_font = font(HIRA_W6, 84)
    else:
        text(d, (w / 2, 290 * SS), "The Tuner Made for Shinobue", font(SFNS, 190, "Bold"), WHITE)
        text(d, (w / 2, 500 * SS), "Supports No. 6 & No. 8 keys  ·  A4 = 442 Hz", font(SFNS, 96, "Regular"), GOLD)
        solfege = "Do"
        chips = ["Note or fingering", "Cent meter", "Pitch graph", "Record & play"]
        chip_font = font(SFNS, 84, "Semibold")

    # 周波数（アプリではゲージの上に出る）
    text(d, (w / 2, 700 * SS), "468.3 Hz", font(SFNS, 120, "Regular"), GRAY)

    # チューナーゲージ。中央に階名＋音名（六本調子の運指「一」= B♭4）
    gauge_cy, radius, stroke = 1950 * SS, 920 * SS, 155 * SS
    solfege_size = 440
    main_h = solfege_size * SS * 1.2
    draw_gauge(img, w / 2, gauge_cy, radius, stroke, 0, font(SFNS, 92, "Regular"), main_h)

    big = font(HIRA_W6, solfege_size)
    note_font = font(SFNS, int(solfege_size * 0.4), "Semibold")
    center_y = gauge_cy - radius * 0.44
    gap = solfege_size * 0.13 * SS
    sw = d.textlength(solfege, font=big)
    nw = d.textlength("B♭4", font=note_font)
    left = w / 2 - (sw + gap + nw) / 2
    text(d, (left + sw / 2, center_y), solfege, big, GREEN)
    text(d, (left + sw + gap + nw / 2, center_y + solfege_size * 0.22 * SS), "B♭4", note_font, WHITE)

    # 機能のチップ
    pad_x, chip_h, gap = 80 * SS, 170 * SS, 60 * SS
    widths = [d.textlength(c, font=chip_font) + pad_x * 2 for c in chips]
    x = w / 2 - (sum(widths) + gap * (len(chips) - 1)) / 2
    cy = 2320 * SS
    for c, cw in zip(chips, widths):
        d.rounded_rectangle([x, cy - chip_h / 2, x + cw, cy + chip_h / 2], radius=chip_h / 2,
                            fill=(38, 42, 64), outline=GOLD_DARK, width=4 * SS)
        text(d, (x + cw / 2, cy), c, chip_font, GOLD_LIGHT)
        x += cw + gap

    out = img.convert("RGB").resize((3840, 2560), Image.LANCZOS)
    out.save(OUT / f"search_{lang}.png")


for lang in ["ja", "en"]:
    make_header(lang)
    make_search(lang)
print("done")

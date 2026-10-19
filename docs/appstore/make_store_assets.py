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


def draw_meter(img, cx, top, width, height, label_font):
    d = ImageDraw.Draw(img)
    x0 = int(cx - width / 2)
    bar = Image.new("RGB", (int(width), int(height)))
    bd = ImageDraw.Draw(bar)
    for x in range(int(width)):
        bd.line([x, 0, x, height], fill=meter_color(x / (width - 1)))
    mask = Image.new("L", bar.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, width - 1, height - 1], radius=height / 2, fill=255)
    img.paste(bar, (x0, int(top)), mask)
    # 中央線と針（三角）
    d.line([cx, top, cx, top + height], fill=WHITE, width=int(6 * SS))
    tri_h = height * 0.95
    d.polygon([(cx, top + height * 0.15), (cx - tri_h * 0.62, top + height * 0.15 + tri_h), (cx + tri_h * 0.62, top + height * 0.15 + tri_h)],
              fill=WHITE, outline=(60, 60, 70))
    for i, label in enumerate(["-50", "-25", "0", "+25", "+50"]):
        lx = x0 + width * (0.02 + 0.24 * i)
        d.text((lx, top + height + 40 * SS), label, font=label_font, fill=GRAY, anchor="mt")


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
        fingering, solfege = "一", "ド"
        captions = ["運指", "階名", "音名"]
        cap_font = font(HIRA_W3, 70)
        chips = ["運指・階名・音名", "セントメーター", "ピッチグラフ", "録音・再生"]
        chip_font = font(HIRA_W6, 84)
    else:
        text(d, (w / 2, 290 * SS), "The Tuner Made for Shinobue", font(SFNS, 190, "Bold"), WHITE)
        text(d, (w / 2, 500 * SS), "Supports No. 6 & No. 8 keys  ·  A4 = 442 Hz", font(SFNS, 96, "Regular"), GOLD)
        fingering, solfege = "1", "Do"
        captions = ["Fingering", "Solfège", "Note"]
        cap_font = font(SFNS, 70, "Regular")
        chips = ["Fingering & notes", "Cent meter", "Pitch graph", "Record & play"]
        chip_font = font(SFNS, 84, "Semibold")

    # 音の表示（チューナー画面の上部と同じ並び：運指・階名・音名）。六本調子の一 = B♭4
    big = font(HIRA_W6, 400)
    mid = font(HIRA_W6, 250)
    row_y = 960 * SS
    text(d, (w / 2 - 860 * SS, row_y), fingering, mid, WHITE)
    text(d, (w / 2, row_y), solfege, big, GREEN)
    text(d, (w / 2 + 860 * SS, row_y), "B♭4", font(SFNS, 250, "Semibold"), WHITE)
    for dx, c in zip([-860, 0, 860], captions):
        text(d, (w / 2 + dx * SS, 1250 * SS), c, cap_font, GRAY)
    text(d, (w / 2, 1370 * SS), "468.3 Hz", font(SFNS, 100, "Regular"), GRAY)

    draw_meter(img, w / 2, 1530 * SS, 2700 * SS, 120 * SS, font(SFNS, 70, "Regular"))

    # 機能のチップ
    pad_x, chip_h, gap = 80 * SS, 170 * SS, 60 * SS
    widths = [d.textlength(c, font=chip_font) + pad_x * 2 for c in chips]
    x = w / 2 - (sum(widths) + gap * (len(chips) - 1)) / 2
    cy = 2130 * SS
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

"""Fantasy Arena — ассет-пак в едином стиле (пиксель-арт, сетка 16x16, тёмная обводка).

Каждый спрайт задан сеткой символов; символ -> цвет из общей палитры PALETTE.
Запуск: python3 build_pack.py  -> папка fantasy_arena_pack/ рядом со скриптом.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent  # корень пака

# ---------------------------------------------------------------------------
# Общая палитра (одна на весь пак)
# ---------------------------------------------------------------------------
PALETTE = {
    "K": "#241a2c",  # обводка
    "F": "#2d2238",  # заливка интерфейса
    "1": "#f4f4f4",  # белый блик
    "L": "#c2c3c7", "M": "#8b8f99", "D": "#4f5160",          # металл
    "B": "#e8e0c8", "b": "#b8ab8c",                          # кость
    "T": "#d29a5a", "W": "#b8763a", "w": "#6e4322", "n": "#4a2c18",  # дерево, кожа
    "Y": "#ffe66d", "G": "#f1c453", "g": "#c99a2e", "o": "#8a6b2a",  # золото
    "r": "#ff6b5b", "R": "#e23d28", "x": "#9b1f2a",          # красный
    "O": "#ff9a3c",                                          # оранжевый
    "e": "#a6f07a", "E": "#5fcd4a", "v": "#2f8a3a", "N": "#7dff7a",  # зелёный
    "c": "#d6eef8", "C": "#8ec5df", "s": "#79b8e8", "S": "#3a6ea5", "z": "#233f73",  # синий
    "i": "#9ff3ff", "I": "#4fc3e0",                          # лёд
    "p": "#c49be8", "P": "#8f5ec8", "q": "#5b3a8a", "Q": "#3a2350",  # фиолетовый
    "m": "#ff4fd8",                                          # проклятое свечение
    "h": "#8f7ea0", "j": "#6b5a7a", "J": "#463a52",          # проклятый камень
}
RGB = {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in PALETTE.items()}


def sprite(rows: list[str], remap: dict[str, str] | None = None) -> Image.Image:
    """Сетка символов -> RGBA. remap переводит символы исходной сетки в символы палитры."""
    remap = remap or {}
    w, h = len(rows[0]), len(rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        if len(row) != w:
            raise ValueError(f"строка {y} длиной {len(row)} вместо {w}: {row!r}")
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            ch = remap.get(ch, ch)
            img.putpixel((x, y), RGB[ch] + (255,))
    return img


def grid(w: int, h: int) -> list[list[str]]:
    return [["."] * w for _ in range(h)]


def to_rows(g: list[list[str]]) -> list[str]:
    return ["".join(r) for r in g]


def outline(g: list[list[str]]) -> list[list[str]]:
    """Обводит непрозрачные пиксели символом K (по 4 соседям)."""
    h, w = len(g), len(g[0])
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and g[ny][nx] not in (".", "K"):
                    out[y][x] = "K"
                    break
    return out


def noise(x: int, y: int, seed: int) -> int:
    return (x * 73856093 ^ y * 19349663 ^ seed * 83492791) & 0xFFFF


# ---------------------------------------------------------------------------
# Предметы (15)
# ---------------------------------------------------------------------------
BOOT = [
    "................",
    "................",
    ".....KKKKK......",
    ".....KTTWK......",
    ".....KTTWK......",
    ".....KTTWK......",
    ".....KGGgK......",
    ".....KTTWK......",
    ".....KTTWKK.....",
    ".....KTTTWWK....",
    "....KTTTTTTWK...",
    "....KTTTTTTTWK..",
    "....KwwwwwwwwK..",
    "....KKKKKKKKKK..",
    "................",
    "................",
]

ITEMS = {
    "boots": sprite(BOOT),
    "storm_boots": sprite([
        "................",
        "............KK..",
        ".....KKKKK.KYK..",
        ".....KssSKKYK...",
        ".....KssSKKYYYK.",
        ".....KssSK..KYK.",
        ".....KYYGK.KK...",
        ".....KssSK......",
        ".....KssSKK.....",
        ".....KsssSSK....",
        "....KssssssSK...",
        "....KsssssssSK..",
        "....KzzzzzzzzK..",
        "....KKKKKKKKKK..",
        "................",
        "................",
    ]),
    "heart": sprite([
        "................",
        "................",
        "...KKK....KKK...",
        "..KrrRK..KrRRK..",
        ".K1rRRRKKRRRRxK.",
        ".KrRRRRRRRRRRxK.",
        ".KRRRRRRRRRRRxK.",
        "..KRRRRRRRRRxK..",
        "...KRRRRRRRxK...",
        "....KRRRRRxK....",
        ".....KRRRxK.....",
        "......KRxK......",
        ".......KK.......",
        "................",
        "................",
        "................",
    ]),
    "magnet": sprite([
        "................",
        "..KKKK....KKKK..",
        "..K11K....K11K..",
        "..KLLK....KLMK..",
        "..KKKK....KKKK..",
        "..KrRK....KRxK..",
        "..KRRK....KRxK..",
        "..KRRK....KRxK..",
        "..KRRRK..KRRxK..",
        "..KRRRRKKRRRxK..",
        "...KRRRRRRRxK...",
        "....KxxxxxxK....",
        ".....KKKKKK.....",
        "................",
        "................",
        "................",
    ]),
    "power": sprite(remap={"L": "G", "1": "Y", "M": "g", "G": "R", "g": "x", "D": "o"}, rows=[
        "................",
        "................",
        "................",
        "....KKKKKKK.....",
        "...KLLMLLMLK....",
        "...KL1MLLMLKK...",
        "...KLLMLLMLKLK..",
        "...KMMMMMMMKLK..",
        "...KLLLLLLLLMK..",
        "...KLLLLLLLMK...",
        "....KMMMMMMK....",
        "....KGGGGGgK....",
        "....KDDDDDDK....",
        "....KKKKKKKK....",
        "................",
        "................",
    ]),
    "ring_of_life": sprite([
        "................",
        "................",
        "......KKKK......",
        ".....KeEEvK.....",
        ".....KEEvvK.....",
        "....KKGKKGKK....",
        "...KGGKKKKGgK...",
        "..KGK......KgK..",
        "..KGK......KgK..",
        "..KGK......KgK..",
        "...KGK....KgK...",
        "....KGGGGggK....",
        ".....KKKKKK.....",
        "................",
        "................",
        "................",
    ]),
    "hourglass": sprite([
        "................",
        "..KKKKKKKKKKKK..",
        "..KWWWWWWWWWwK..",
        "..KKKKKKKKKKKK..",
        "..wKcccccccCKw..",
        "..w.KGGGGGCK.w..",
        "..w..KGGGgK..w..",
        "..w...KGgK...w..",
        "..w..KcGccK..w..",
        "..w.KccGcccK.w..",
        "..wKcgGGGgcCKw..",
        "..wKGGGGGGGgKw..",
        "..KKKKKKKKKKKK..",
        "..KWWWWWWWWWwK..",
        "..KKKKKKKKKKKK..",
        "................",
    ]),
    "lens": sprite([
        "................",
        "....KKKKK.......",
        "...KGGGGGK......",
        "..KGsssssGK.....",
        ".KGs11ssssGK....",
        ".KGs1sssssGK....",
        ".KGsssssssGK....",
        ".KGsssssssGK....",
        ".KGssssssSGK....",
        "..KGssssSGK.....",
        "...KGGGGGKK.....",
        "....KKKKKWWK....",
        "..........KWWK..",
        "...........KWWK.",
        "............KwK.",
        ".............K..",
    ]),
    "plate_armor": sprite([
        "................",
        "................",
        "...KKK....KKK...",
        "..KLLMKKKKMLLK..",
        "..KL1LLLLLLLMK..",
        "..KLLLLMMLLLMK..",
        "...KLLLMMLLLK...",
        "...KLLLMMLLMK...",
        "...KLLLMMLLMK...",
        "...KGGGGGGGgK...",
        "...KLLLMMLLMK...",
        "....KLLMMLMK....",
        ".....KKKKKK.....",
        "................",
        "................",
        "................",
    ]),
    "quiver": sprite([
        "...K...K...K....",
        "..KRK.K1K.KRK...",
        "..KRK.K1K.KRK...",
        "..KxK.KLK.KxK...",
        "...M...M...M....",
        "..KKKKKKKKKKK...",
        "..KTTTTTTTTWK...",
        "..KTTTTTTTTWK...",
        "..KGGGGGGGGgK...",
        "..KTTTTTTTTWK...",
        "..KTTTTTTTTWK...",
        "..KTTTTTTTTWK...",
        "..KTTTTTTTTWK...",
        "...KwwwwwwwK....",
        "....KKKKKKK.....",
        "................",
    ]),
    "storm_anchor_placeholder": None,  # заполняется ниже (якорь)
    "blood_crystal": sprite([
        "................",
        ".......KK.......",
        "......KrRK......",
        ".....KrrRxK.....",
        "....KrrRRRxK....",
        "...Kr1RRRRxxK...",
        "...KrrRRRRxxK...",
        "...KrRRRRRxxK...",
        "....KRRRRxxK....",
        ".....KRRxxK.....",
        "......KRxK......",
        ".......KK.......",
        "........K.......",
        ".......KRK......",
        ".......KxK......",
        "........K.......",
    ]),
    "glass_cannon": sprite([
        "................",
        "................",
        "................",
        "................",
        ".....KKKKKKKKKK.",
        "...KKc1cccccccCK",
        "..KCcccKcccccCzK",
        "..KCccccKccCCCzK",
        "...KKCCCCCCCCCK.",
        "....KKKKKKKKKK..",
        ".....KKKKK......",
        "....KWWwWWK.....",
        "....KWwnwWK.....",
        "....KWWwWWK.....",
        ".....KKKKK......",
        "................",
    ]),
    "phoenix_feather": sprite([
        "................",
        "...........KKK..",
        "..........KYOBK.",
        "........KYYOBRRK",
        ".......KYYOBRRK.",
        "......KYYOBRRK..",
        ".....KYYOBRKRK..",
        "....KYOOBRRK....",
        "...KYOOBRKRK....",
        "...KOOBRRK......",
        "..KKOBRK........",
        "..KTKKK.........",
        ".KTK............",
        "KTK.............",
        "TK..............",
        "................",
    ]),
    "cursed_idol": sprite([
        "..K..........K..",
        ".KhK........KJK.",
        ".KhjK.KKKK.KjJK.",
        "..KhjKhjjJKjJK..",
        "...KhjjjjjjJK...",
        "...KjNNjjNNJK...",
        "...KjNNjjNNJK...",
        "...KjjjjjjjJK...",
        "...KjKjKKjKJK...",
        "....KjjjjjJK....",
        "...KKKjjjjKKK...",
        "..KhjKjjjJKjJK..",
        "..KjJKjjjJKJJK..",
        "..KKKKKKKKKKKK..",
        "..KGGGGGGGGGgK..",
        "..KKKKKKKKKKKK..",
    ]),
}
ITEMS.pop("storm_anchor_placeholder")
ITEMS["anchor"] = sprite([
    "................",
    "......KKKK......",
    ".....K1LLDK.....",
    ".....KL..DK.....",
    "......KLDK......",
    "....KKKLDKKK....",
    "....K1LLLLDK....",
    "....KKKLDKKK....",
    "......KLDK......",
    "......KLDK......",
    ".KK...KLDK...KK.",
    "K1LK..KLDK..KLDK",
    ".KLDK.KLDK.KLDK.",
    "..KLDKKLDKKLDK..",
    "...KKLLLLLDDK...",
    "....KKKKKKKK....",
])
# Порядок как в ТЗ
ITEM_ORDER = ["boots", "heart", "magnet", "power", "ring_of_life", "hourglass", "lens",
              "plate_armor", "quiver", "storm_boots", "anchor", "blood_crystal",
              "glass_cannon", "phoenix_feather", "cursed_idol"]

# ---------------------------------------------------------------------------
# Навыки мага (3)
# ---------------------------------------------------------------------------
SKILLS = {
    "resonance": sprite([
        "................",
        ".....KKKKKK.....",
        "...KKppppppKK...",
        "..KpK......KpK..",
        ".KpK..KKKK..KpK.",
        ".Kp..KPPPqK..pK.",
        "Kp..KP1PPPqK..pK",
        "Kp..K1PPPPqK..pK",
        "Kp..KPPPPqqK..pK",
        "Kp..KqPPqqqK..pK",
        ".Kp..KqqqqK..pK.",
        ".KpK..KKKK..KpK.",
        "..KpK......KpK..",
        "...KKppppppKK...",
        ".....KKKKKK.....",
        "................",
    ]),
    "mana_shield": sprite([
        "................",
        "...KKKKKKKKKK...",
        "..KcssssssSSzK..",
        "..KcsssiisSSzK..",
        "..KcssiiiiSSzK..",
        "..KcsssiisSSzK..",
        "..KcssssssSSzK..",
        "...KcsssssSzK...",
        "...KcsssssSzK...",
        "....KcsssSzK....",
        ".....KcsSzK.....",
        "......KczK......",
        ".......KK.......",
        "................",
        "................",
        "................",
    ]),
    "flow": sprite([
        "................",
        "................",
        "................",
        "................",
        ".KK...KK...KK...",
        ".KYK..KOK..KRK..",
        "..KYK..KOK..KRK.",
        "...KYK..KOK..KRK",
        "...KYK..KOK..KRK",
        "..KYK..KOK..KRK.",
        ".KYK..KOK..KRK..",
        ".KK...KK...KK...",
        "................",
        "................",
        "................",
        "................",
    ]),
}

# ---------------------------------------------------------------------------
# Черепа (основа для оружия «Проклятый череп»)
# ---------------------------------------------------------------------------
SKULL_CLOSED = [
    "................",
    "................",
    "................",
    ".....KKKKKK.....",
    "....KBBBBBbK....",
    "...KBBBBBBBbK...",
    "...KBBBBBBBbK...",
    "...KBNNBBNNbK...",
    "...KBNNBBNNbK...",
    "...KBBBKKBBbK...",
    "....KBBBBBbK....",
    "....KBKBKBKK....",
    ".....KKKKKK.....",
    "................",
    "................",
    "................",
]
SKULL_OPEN = [
    "................",
    "................",
    ".....KKKKKK.....",
    "....KBBBBBbK....",
    "...KBBBBBBBbK...",
    "...KBBBBBBBbK...",
    "...KBNNBBNNbK...",
    "...KBNNBBNNbK...",
    "...KBBBKKBBbK...",
    "....KBKBKBKK....",
    "....KKKKKKKK....",
    "....KBKBKBKK....",
    ".....KBBBbK.....",
    "......KKKK......",
    "................",
    "................",
]
SKULL_CURSED = [
    "................",
    "KK............KK",
    "KBK..........KBK",
    "KBBK.KKKKKK.KBBK",
    ".KBBKhhhhhJKBBK.",
    "..KKhhhhhhhJKK..",
    "...KhhhhhhhJK...",
    "...KhmmhhmmJK...",
    "...KhmmhhmmJK...",
    "...KhhhKKhhJK...",
    "....KhhhhhJK....",
    "....KhKhKhKK....",
    ".....KKKKKK.....",
    "................",
    "................",
    "................",
]
SMALL_SKULL = [
    "..KKKK..",
    ".KBBBbK.",
    "KBBBBBbK",
    "KNNBNNbK",
    "KNNBNNbK",
    "KBBKBBbK",
    ".KBBBbK.",
    ".KBKBKK.",
    "..KKKK..",
]
FLAME_TRAIL = [
    [".......", "...R..R", ".RROORO", "ROOYOOY", "OYYYYYY", "ROOYOOY", ".RROORO", "...R..R", "......."],
    [".......", "..R...R", "R.ROROO", "ROYYOOY", "OYYOYYY", "ROYYOOY", "R.ROROO", "..R...R", "......."],
]


def flaming_skull(frame: int, cursed_fire: bool = False) -> Image.Image:
    rows = ["." * 16] * 4
    rows += [f + s + "." for f, s in zip(FLAME_TRAIL[frame], SMALL_SKULL)]
    rows += ["." * 16] * 3
    remap = {"R": "q", "O": "P", "Y": "p"} if cursed_fire else None
    # remap не должен трогать сам череп: в нём нет R/O/Y, так что безопасно
    return sprite(rows, remap)


# ---------------------------------------------------------------------------
# Иконки оружия (9)
# ---------------------------------------------------------------------------
def aura_icon() -> Image.Image:
    g = grid(16, 16)
    cx = cy = 7.5
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - cx, y - cy)
            if 3.9 <= d < 4.7:
                g[y][x] = "Y"
            elif 4.7 <= d < 5.6:
                g[y][x] = "O"
            elif 5.6 <= d < 6.3:
                g[y][x] = "R"
    # языки пламени наружу
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        for r, ch in ((6.6, "O"), (7.3, "Y")):
            x, y = round(cx + r * math.cos(a)), round(cy + r * math.sin(a))
            if 0 <= x < 16 and 0 <= y < 16:
                g[y][x] = ch
    g[7][7] = g[8][8] = "Y"
    g[7][8] = g[8][7] = "O"
    return sprite(to_rows(outline(g)))


def orbs_icon() -> Image.Image:
    g = grid(16, 16)
    cx, cy, r = 7.5, 8.0, 5.6
    for k in range(36):
        a = k * math.tau / 36
        x, y = round(cx + r * math.cos(a)), round(cy + r * math.sin(a))
        if k % 3 == 0 and 0 <= x < 16 and 0 <= y < 16:
            g[y][x] = "M"
    ball = [".KKK.", "K1pPK", "KpPqK", "KPqqK", ".KKK."]
    for deg in (-90, 30, 150):
        a = math.radians(deg)
        ox, oy = round(cx + r * math.cos(a)) - 2, round(cy + r * math.sin(a)) - 2
        for dy, row in enumerate(ball):
            for dx, ch in enumerate(row):
                x, y = ox + dx, oy + dy
                if ch != "." and 0 <= x < 16 and 0 <= y < 16:
                    g[y][x] = ch
    return sprite(to_rows(g))


WEAPONS = {
    "magic_bolt": sprite([
        "................",
        "................",
        "..........KKKK..",
        ".........KppPqK.",
        "........Kp11PPqK",
        "........KpPPPPqK",
        "........KPPPPqqK",
        ".........KPqqqK.",
        ".......p..KKKK..",
        "......pP........",
        ".....pP...p.....",
        "....pP..........",
        "...p..p.........",
        "..p.............",
        "................",
        "................",
    ]),
    "fire_rain": sprite([
        "................",
        ".............YK.",
        "...........YOO..",
        "..........YOOR..",
        ".........YOORR..",
        "........YOORR...",
        ".....KKKOORR....",
        "....KxRROOR.....",
        "...KxRRRRO......",
        "...KxRDRRRK.....",
        "...KxxRRDRK.....",
        "....KxxRRK......",
        ".....KKKK.......",
        "................",
        "................",
        "................",
    ]),
    "chain_lightning": sprite([
        "................",
        ".........KKKK...",
        "........KY1YK...",
        ".......KY1YK....",
        "......KY1YK.....",
        ".....KY1YKKKK...",
        "....KYYYYYYYK...",
        "...KKKKY1YYK....",
        "......KY1YK.....",
        ".....KY1YK......",
        "....KY1YK.......",
        "...KYYK.........",
        "...KYK..........",
        "...KK...........",
        "................",
        "................",
    ]),
    "orbs": orbs_icon(),
    "aura": aura_icon(),
    "frost_bell": sprite([
        "................",
        "..1....KK....1..",
        "......KiIK......",
        ".....KKKKKK.....",
        "....KiiIIISK....",
        "....KiIIIISK....",
        "...KiiIIIISSK...",
        "...KiIIIIISSK...",
        "...KiIIIIISSK...",
        "..KiiIIIIISSzK..",
        "..KKKKKKKKKKKK..",
        "......KMMK......",
        ".1.....KK.....1.",
        "................",
        "................",
        "................",
    ]),
    "cursed_skull": flaming_skull(0, cursed_fire=True),
    "throwing_axe": sprite([
        "................",
        "................",
        "...KKKK.........",
        "..K1LLLK........",
        ".K1LLLLMK.......",
        ".KLLLLLMMK......",
        ".KLLLLMMKWK.....",
        "..KLLMMKWWK.....",
        "...KMMKWWK......",
        "....KKWWK.......",
        ".......KWWK.....",
        "........KWWK....",
        ".........KWWK...",
        "..........KwwK..",
        "...........KK...",
        "................",
    ]),
    "holy_water": sprite([
        "................",
        "......KKKK......",
        "......KTWK......",
        "......KKKK......",
        "......KccK......",
        "......KccK......",
        ".....KcssSK.....",
        "....KcsssSSK....",
        "...Kcss1ssSzK...",
        "...Kcs111sSzK...",
        "...Kcss1sSSzK...",
        "...KcsssSSSzK...",
        "....KSSSSzzK....",
        ".....KKKKKK.....",
        "................",
        "................",
    ]),
}
WEAPON_ORDER = ["magic_bolt", "fire_rain", "chain_lightning", "orbs", "aura",
                "frost_bell", "cursed_skull", "throwing_axe", "holy_water"]

# ---------------------------------------------------------------------------
# Снаряды и объекты на арене
# ---------------------------------------------------------------------------
BOLT_F0 = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "......KKKK......",
    ".....Kp1PqK.....",
    ".....K1PPqK.....",
    ".....KPPPqK.....",
    ".....KqPqqK.....",
    "......KKKK......",
    "................",
    "................",
    "................",
    "................",
    "................",
]
BOLT_F1 = [row[:] for row in BOLT_F0]
for (bx, by) in ((3, 6), (12, 9), (4, 11), (11, 4)):
    BOLT_F1[by] = BOLT_F1[by][:bx] + "p" + BOLT_F1[by][bx + 1:]

ORB = [
    "................",
    "................",
    "................",
    "................",
    "......KKKK......",
    ".....K1ppPK.....",
    "....K1pPPPqK....",
    "....KpPPPPqK....",
    "....KpPPPqqK....",
    "....KPPPqqqK....",
    ".....KPqqqK.....",
    "......KKKK......",
    "................",
    "................",
    "................",
    "................",
]


def puddle(frame: int) -> Image.Image:
    w, h = 24, 12
    g = grid(w, h)
    for y in range(h):
        for x in range(w):
            dx, dy = (x - 11.5) / 10.5, (y - 5.5) / 4.6
            d = dx * dx + dy * dy
            if d < 1.0:
                g[y][x] = "S" if d > 0.55 else "s"
    for (px, py) in ([(6, 4), (14, 6), (17, 4)] if frame == 0 else [(8, 6), (12, 4), (16, 7)]):
        g[py][px] = "1"
        g[py][px + 1] = "c"
    return sprite(to_rows(outline(g)))


PROJECTILES = {
    "magic_bolt_f0": sprite(BOLT_F0),
    "magic_bolt_f1": sprite(BOLT_F1),
    "orb": sprite(ORB),
    "meteor": WEAPONS["fire_rain"],
    "throwing_axe": WEAPONS["throwing_axe"],
    "holy_flask": WEAPONS["holy_water"],
    "holy_puddle_f0": puddle(0),
    "holy_puddle_f1": puddle(1),
    "skull_chomp_f0": sprite(SKULL_CLOSED),
    "skull_chomp_f1": sprite(SKULL_OPEN),
    "skull_flaming_f0": flaming_skull(0),
    "skull_flaming_f1": flaming_skull(1),
    "skull_cursed": sprite(SKULL_CURSED),
    "skull_cursed_flaming_f0": flaming_skull(0, cursed_fire=True),
    "skull_cursed_flaming_f1": flaming_skull(1, cursed_fire=True),
}

# ---------------------------------------------------------------------------
# Подбираемое
# ---------------------------------------------------------------------------
GEM = [
    "...KK...",
    "..K1uK..",
    ".KauuyK.",
    "KauuuuyK",
    "KuuuuyyK",
    ".KuuyyK.",
    "..KyyK..",
    "...KK...",
]
GEM_TIERS = {
    "xp_gem_1_blue": {"a": "c", "u": "s", "y": "S"},
    "xp_gem_2_green": {"a": "e", "u": "E", "y": "v"},
    "xp_gem_3_gold": {"a": "Y", "u": "G", "y": "g"},
    "xp_gem_4_red": {"a": "r", "u": "R", "y": "x"},
}
PICKUPS = {name: sprite(GEM, remap) for name, remap in GEM_TIERS.items()}
PICKUPS["anvil"] = sprite([
    "................",
    "................",
    "................",
    "................",
    "...KKKKKKKKKKKK.",
    ".KKL1LLLLLLLLMK.",
    "KMMLLLLLLLLLMMK.",
    ".KKKKLLLLLMKKK..",
    ".....KLLLMK.....",
    ".....KLLLMK.....",
    "....KLLLLLMK....",
    "...KMMMMMMMMK...",
    "...KDDDDDDDDK...",
    "...KKKKKKKKKK...",
    "................",
    "................",
])
PICKUPS["heal_plus"] = sprite([
    "..KKKK..",
    "..KeEK..",
    "KKKeEKKK",
    "KeeeEEvK",
    "KEEEEvvK",
    "KKKEvKKK",
    "..KEvK..",
    "..KKKK..",
])

# ---------------------------------------------------------------------------
# Эффекты
# ---------------------------------------------------------------------------
def explosion(frame: int) -> Image.Image:
    g = grid(16, 16)
    radius = [2.6, 4.6, 6.2, 7.0, 7.4][frame]
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if d >= radius:
                continue
            t = d / radius
            n = noise(x, y, frame) % 100
            if frame == 0:
                ch = "1" if t < 0.6 else "Y"
            elif frame == 1:
                ch = "1" if t < 0.35 else ("Y" if t < 0.7 else "O")
            elif frame == 2:
                ch = "Y" if t < 0.35 else ("O" if t < 0.7 else "R")
            elif frame == 3:
                if n < 30:
                    continue
                ch = "O" if t < 0.4 else ("R" if t < 0.75 else "D")
            else:
                if n < 55 or t < 0.45:
                    continue
                ch = "M" if n % 2 else "D"
            g[y][x] = ch
    if frame <= 3:
        g = outline(g)
    return sprite(to_rows(g))


def hit_spark(frame: int) -> Image.Image:
    shapes = [
        ["........", "........", "...1....", "..1Y1...", "...1....", "........", "........", "........"],
        ["...1....", "...Y....", "...Y....", "1YY1YY1.", "...Y....", "...Y....", "...1....", "........"],
        ["1.....1.", ".Y...Y..", "........", "...Y....", "........", ".Y...Y..", "1.....1.", "........"],
    ]
    return sprite(shapes[frame])


def frost_ring(frame: int) -> Image.Image:
    size = 32
    g = grid(size, size)
    r = [6.0, 10.0, 14.0][frame]
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - 15.5, y - 15.5)
            if r - 0.5 <= d < r + 0.5:
                g[y][x] = "I"
            elif r - 1.1 <= d < r - 0.5:
                # тонкий внутренний блик — пунктиром, чтобы кольцо осталось лёгким
                ang = math.atan2(y - 15.5, x - 15.5)
                if int((ang + math.pi) / (math.pi / 8)) % 2 == 0:
                    g[y][x] = "i"
    for k in range(6):
        a = k * math.pi / 3 + frame * 0.4
        x, y = round(15.5 + (r + 1.6) * math.cos(a)), round(15.5 + (r + 1.6) * math.sin(a))
        if 0 <= x < size and 0 <= y < size:
            g[y][x] = "1"
    return sprite(to_rows(g))


EFFECTS = {f"explosion_f{i}": explosion(i) for i in range(5)}
EFFECTS.update({f"hit_spark_f{i}": hit_spark(i) for i in range(3)})
EFFECTS.update({f"frost_ring_f{i}": frost_ring(i) for i in range(3)})

# ---------------------------------------------------------------------------
# Интерфейс
# ---------------------------------------------------------------------------
def slot(border: str, light: str) -> Image.Image:
    s = 20
    g = grid(s, s)
    for y in range(s):
        for x in range(s):
            edge = min(x, y, s - 1 - x, s - 1 - y)
            g[y][x] = "K" if edge == 0 else (border if edge == 1 else "F")
    for (x, y) in ((1, 1), (s - 2, 1), (1, s - 2), (s - 2, s - 2)):
        g[y][x] = light
    return sprite(to_rows(g))


def panel(border: str, light: str) -> Image.Image:
    s = 24
    g = grid(s, s)
    for y in range(s):
        for x in range(s):
            edge = min(x, y, s - 1 - x, s - 1 - y)
            g[y][x] = "K" if edge == 0 else (border if edge in (1, 2) else ("K" if edge == 3 else "F"))
    for (x, y) in ((2, 2), (s - 3, 2), (2, s - 3), (s - 3, s - 3)):
        g[y][x] = light
    return sprite(to_rows(g))


def warning_circle(frame: int) -> Image.Image:
    g = grid(16, 16)
    for y in range(16):
        for x in range(16):
            d = math.hypot(x - 7.5, y - 7.5)
            if 5.6 <= d < 7.0:
                ang = math.atan2(y - 7.5, x - 7.5)
                dashed = int((ang + math.pi) / (math.pi / 6)) % 2 == 0
                if frame == 1 or dashed:
                    g[y][x] = "r" if frame == 1 else "R"
            elif d < 2.0 and frame == 1:
                g[y][x] = "R"
    return sprite(to_rows(g))


UI = {
    "slot_weapon_class": slot("P", "p"),
    "slot_weapon_common": slot("M", "L"),
    "slot_item": slot("W", "T"),
    "slot_skill": slot("G", "Y"),
    "panel_9slice": panel("j", "h"),
    "panel_9slice_gold": panel("g", "Y"),
    "star": sprite([
        "...KK...",
        "..KYGK..",
        "KKKYGKKK",
        "KYYYGGgK",
        ".KYGGgK.",
        ".KYGKgK.",
        "KYGK.KgK",
        "KKK...KK",
    ]),
    "warning_circle_f0": warning_circle(0),
    "warning_circle_f1": warning_circle(1),
    "edge_arrow": sprite([
        "KK......",
        "KrKK....",
        "KRrrKK..",
        "KRRRrrK.",
        "KRRRxxK.",
        "KRxxKK..",
        "KxKK....",
        "KK......",
    ]),
}

# ---------------------------------------------------------------------------
# Сохранение и превью
# ---------------------------------------------------------------------------
SECTIONS = [
    ("items", "Предметы", {k: ITEMS[k] for k in ITEM_ORDER}, True),
    ("skills", "Навыки мага", SKILLS, True),
    ("weapons", "Иконки оружия", {k: WEAPONS[k] for k in WEAPON_ORDER}, True),
    ("projectiles", "Снаряды и объекты", PROJECTILES, False),
    ("pickups", "Подбираемое", PICKUPS, False),
    ("effects", "Эффекты", EFFECTS, False),
    ("ui", "Интерфейс", UI, False),
]


def save_all() -> None:
    for folder, _title, sprites, with_32 in SECTIONS:
        base = ROOT / folder
        (base / "16" if with_32 else base).mkdir(parents=True, exist_ok=True)
        for name, img in sprites.items():
            if with_32:
                img.save(base / "16" / f"{name}.png")
                (base / "32").mkdir(exist_ok=True)
                img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(base / "32" / f"{name}.png")
            else:
                img.save(base / f"{name}.png")


def contact_sheet(path: Path) -> None:
    cell_w, cell_h, per_row, pad = 104, 96, 8, 12
    rows_total = sum(math.ceil(len(s) / per_row) for _, _, s, _ in SECTIONS)
    height = pad + rows_total * cell_h + len(SECTIONS) * 22 + pad
    width = pad * 2 + per_row * cell_w
    sheet = Image.new("RGBA", (width, height), RGB["F"] + (255,))
    draw = ImageDraw.Draw(sheet)
    y = pad
    for folder, _title, sprites, _ in SECTIONS:
        draw.text((pad, y + 4), folder.upper(), fill=RGB["Y"] + (255,))
        y += 22
        for i, (name, img) in enumerate(sprites.items()):
            col, row = i % per_row, i // per_row
            x0, y0 = pad + col * cell_w, y + row * cell_h
            scale = max(1, min(4, 64 // max(img.width, img.height)))
            big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
            bx = x0 + (cell_w - big.width) // 2
            by = y0 + (72 - big.height) // 2
            # клетчатая подложка под спрайтом
            for cy in range(0, big.height, scale * 2):
                for cx in range(0, big.width, scale * 2):
                    draw.rectangle([bx + cx, by + cy, bx + cx + scale - 1, by + cy + scale - 1], fill=(52, 44, 60, 255))
            sheet.alpha_composite(big, (bx, by))
            label = name if len(name) <= 17 else name[:16] + "~"
            draw.text((x0 + 4, y0 + 76), label, fill=RGB["L"] + (255,))
        y += math.ceil(len(sprites) / per_row) * cell_h
    sheet.save(path)


def palette_sheet(path: Path) -> None:
    keys = list(PALETTE)
    img = Image.new("RGBA", (len(keys) * 12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, k in enumerate(keys):
        d.rectangle([i * 12, 0, i * 12 + 11, 11], fill=RGB[k] + (255,))
    img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(path)


if __name__ == "__main__":
    save_all()
    contact_sheet(ROOT / "preview.png")
    palette_sheet(ROOT / "palette.png")
    total = sum(len(s) for _, _, s, _ in SECTIONS)
    print(f"готово: {total} спрайтов -> {ROOT}")

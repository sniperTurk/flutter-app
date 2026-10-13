"""Cross-validated test of G1 BC estimators for projectiles without a published BC.

Research only (docs/research/tahmini_bc_hata.md). Nothing here is used by the
app. Data: the manufacturer-published G1 BCs already in the repository
(`lib/data/bullet_library.dart`; `lib/data/factory_ammo_library.dart` as an
external check). Target: G1 BC. Every estimator predicts the G1 form factor
i = SD / BC (McCoy, Modern Exterior Ballistics, 1999, ch. 1/4: BC = SD / i,
SD = m / d²), so BC_est = SD / i_est and the error is |BC_est/BC_pub − 1|.

Validation
- "kfold": 10-fold, repeated 5× with different shuffles. Folds are grouped by
  (brand, diameter, weight) so twist/diameter variants of one bullet never sit
  on both sides of a split (they would leak).
- "lobo": leave-one-brand-out: the whole brand is unseen, as for a new maker.
Run: python3 -I tools/research/bc_estimator_cv.py [--json out.json]
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bc_data  # noqa: E402

# ------------------------------------------------------------------ families
# Firearm bullet families from words in the maker's product name. First match
# wins. Groups follow the shape classes McCoy (1999, ch. 4) uses for drag:
# long secant/tangent-ogive boat-tails (low drag), tipped boat-tails, plain
# boat-tails, flat-base spitzers, and blunt round/flat-nose bullets.
FIREARM_FAMILIES: list[tuple[str, str]] = [
    # long-range solids and tipped HPs whose names also carry "solid"/"hollow point"
    ("vld_match", r"\b(elr|bore rider|lazer|lzr)\b"),
    ("blunt", r"\b(rn|round ?nose|fn|flat ?nose|fp|ftx|revolver|subsonic|sub-x|lever|wadcutter|"
              r"semi-spitzer|dgs|solid|bushmaster|hornet|grizzly|tmj)\b|\bfmj\b(?!\s*-?bt)"),
    ("vld_match", r"\b(vld|hybrid|eld match|eld-vt|a-tip|scenar|scenar-l|elite hunter|eol|glider|vlr\d?|"
                  r"tmk|smk|mkx|matchking|aeromatch|juggernaut|palma|fullbore|otm|hpbt|bthp|"
                  r"match|target|competition|elr|long range|mth|mtac|lrx|classic hunter|"
                  r"berger|ascent|hammer)\b"),
    ("tipped_bt", r"\b(eld-x|accubond|ballistic tip|sst|tipped|tip|ttsx|v-max|varmageddon|"
                  r"scirocco|gmx|cx|ecx|ntx|bonded tip|expansion tip|plainsmaster|varminator|"
                  r"tac-tx|e-tip|silvertip)\b"),
    ("bt", r"\b(bt|boat-tail|boat tail|sbt|btsp|gameking|sgk|tgk|fmjbt|pbta|pbtt|gb|grand slam|"
           r"interbond|tsx bt|tbbc)\b"),
    ("fb_spitzer", r".*"),
]
FIREARM_FLAGS: dict[str, str] = {
    "match": r"\b(match|target|competition|smk|tmk|matchking|scenar|otm|palma|fullbore|mtac|aeromatch)\b",
    "vld": r"\b(vld|hybrid|elr|long range|eol|elite hunter|glider|vlr\d?|a-tip|eld match|eld-x|lrx|"
           r"classic hunter|ascent|mth)\b",
    "tip": r"\b(tip|tipped|ballistic tip|accubond|sst|eld-x|eld-vt|eld match|a-tip|ttsx|v-max|"
           r"varmageddon|ntx|scirocco|gmx|cx|ecx|ascent|bonded tip)\b",
    "bt": r"\b(bt|boat-tail|boat tail|hpbt|bthp|sbt|btsp|fmjbt|gameking|sgk|tgk|vld|hybrid|eld|"
          r"eld-x|a-tip|accubond|ballistic tip|sst|lrx|scenar|otm|smk|tmk|matchking|elite hunter|"
          r"classic hunter|scirocco|gb)\b",
    "fb": r"\b(fb|flat ?base|flat-base)\b",
    "rn": r"\b(rn|round ?nose|semi-spitzer|revolver|lever)\b",
    "fn": r"\b(fn|flat ?nose|fp|ftx|wadcutter)\b",
    "sp": r"\b(sp|soft ?point|interlock|hot-cor|pp|psp|spt|pro-hunter|weldcore|partition|"
          r"a-frame|grand slam|core-lokt)\b",
    "hp": r"\b(hp|hollow ?point|hpbt|bthp|otm|tnt|varmint)\b",
    "fmj": r"\b(fmj|fmjbt|tmj|solid|dgs)\b",
    "mono": r"\b(tsx|ttsx|lrx|cx|ecx|tac-tx|gmx|mono|solid copper|plainsmaster|bushmaster|"
            r"varminator|vlr\d?|glider|mth|mtac|raptor|lazer|lzr|hammer|tipped|naturalis|"
            r"expansion tip|e-tip)\b",
    "subsonic": r"\b(subsonic|sub-x)\b",
}
MONO_BRANDS = {"Peregrine", "Cutting Edge Bullets", "Hammer Bullets"}

SLUG_FAMILIES = [
    ("elr", r"\belr\b"),
    ("heavy", r"\b(heavy slug|precision slug|grizzly)\b"),
    ("hp_db", r"\bdb\b"),
    ("hp_fb", r"\bfb\b"),
    ("plain", r".*"),
]
PELLET_FAMILIES = [
    ("pointed", r"\b(silver point|spitzkugel|hornet|pointed|spitz)\b"),
    ("wide_hp", r"\b(crow magnum|terminator|hunter extreme|hollow|hp|wadcutter)\b"),
    ("lead_free", r"\b(green|lead free)\b"),
    ("dome", r".*"),
]


def family(row: dict, table) -> str:
    text = f"{row['name']} {row.get('item', '')}".lower()
    for fam, rx in table:
        if re.search(rx, text):
            return fam
    return table[-1][0]


def flags(row: dict) -> dict[str, int]:
    text = f"{row['name']} {row.get('item', '')}".lower()
    f = {k: int(bool(re.search(rx, text))) for k, rx in FIREARM_FLAGS.items()}
    if row["brand"] in MONO_BRANDS:
        f["mono"] = 1
    return f


def sd_lb_in2(grain: float, d_mm: float) -> float:
    return grain / (7000.0 * (d_mm / 25.4) ** 2)


# ---------------------------------------------------------------- datasets
def dataset(category: str) -> list[dict]:
    rows = []
    for r in bc_data.load_bullets():
        if not r["g1"] or not r["grain"] or not r["diameter_mm"]:
            continue
        cat = "firearm" if r["platform"] == "firearm" else r["type"]
        if cat != category:
            continue
        r = dict(r)
        r["cat"] = cat
        r["sd"] = sd_lb_in2(r["grain"], r["diameter_mm"])
        r["i"] = r["sd"] / r["g1"]
        r["ld"] = r["length_mm"] / r["diameter_mm"] if r["length_mm"] else None
        table = {"firearm": FIREARM_FAMILIES, "slug": SLUG_FAMILIES, "pellet": PELLET_FAMILIES}[cat]
        r["fam"] = family(r, table)
        r["flags"] = flags(r) if cat == "firearm" else {}
        r["group"] = f"{r['brand']}|{round(r['diameter_mm'], 2)}|{r['grain']}"
        rows.append(r)
    return rows


def factory_external(lib_rows: list[dict]) -> list[dict]:
    """Factory G1 rows whose bullet is not already in the bullet library."""
    seen = {(r["brand"].lower(), round(r["diameter_mm"], 1), r["grain"], r["g1"]) for r in lib_rows}
    seen_bg = {(round(r["diameter_mm"], 1), r["grain"], r["g1"]) for r in lib_rows}
    out = []
    for r in bc_data.load_factory():
        if r["model"] != "g1" or not r["bc"] or r["bc_from_bullet"] or r["bc_source"]:
            continue
        if not r["grain"] or not r["diameter_mm"] or r["diameter_mm"] < 4:
            continue
        key = (round(r["diameter_mm"], 1), r["grain"], r["bc"])
        if key in seen_bg or (r["brand"].lower(),) + key in seen:
            continue
        r = dict(r, item="", g1=r["bc"], length_mm=None, cat="firearm")
        r["sd"] = sd_lb_in2(r["grain"], r["diameter_mm"])
        r["i"] = r["sd"] / r["g1"]
        r["ld"] = None
        r["fam"] = family(r, FIREARM_FAMILIES)
        r["flags"] = flags(r)
        r["group"] = f"{r['brand']}|{round(r['diameter_mm'], 2)}|{r['grain']}"
        out.append(r)
    # one row per distinct (brand, diameter, weight, BC): factory lines repeat
    uniq = {}
    for r in out:
        uniq.setdefault((r["brand"], round(r["diameter_mm"], 2), r["grain"], r["g1"]), r)
    return list(uniq.values())


# --------------------------------------------------------------- estimators
def _median_i(train):
    return float(np.median([r["i"] for r in train]))


class GlobalMedian:
    name = "M0 global median i (current app)"

    def fit(self, train):
        self.i = _median_i(train)
        return self

    def predict(self, r):
        return self.i


class GroupMedian:
    """Median i of a key; falls back to coarser keys, then the global median."""

    def __init__(self, name, *keyfns, min_n=3):
        self.name, self.keyfns, self.min_n = name, keyfns, min_n

    def fit(self, train):
        self.glob = _median_i(train)
        self.tables = []
        for kf in self.keyfns:
            d = defaultdict(list)
            for r in train:
                d[kf(r)].append(r["i"])
            self.tables.append({k: float(np.median(v)) for k, v in d.items() if len(v) >= self.min_n})
        return self

    def predict(self, r):
        for kf, t in zip(self.keyfns, self.tables):
            k = kf(r)
            if k in t:
                return t[k]
        return self.glob


def cal_band(r):
    d = r["diameter_mm"]
    for lim, name in ((5.0, "<5"), (6.0, "5-6"), (7.0, "6-7"), (7.5, "7-7.5"), (8.0, "7.5-8"),
                      (9.0, "8-9"), (10.5, "9-10.5")):
        if d < lim:
            return name
    return ">10.5"


def sd_band(r):
    sd = r["sd"]
    if r["cat"] == "firearm":
        edges = (0.18, 0.22, 0.26, 0.30, 0.34)
    elif r["cat"] == "slug":
        edges = (0.07, 0.085, 0.10, 0.13)
    else:
        edges = (0.04, 0.05, 0.06)
    return sum(sd >= e for e in edges)


class Ridge:
    """Ridge regression of log i on features (closed form, standardised)."""

    def __init__(self, name, featfn, lam=1.0):
        self.name, self.featfn, self.lam = name, featfn, lam

    def fit(self, train):
        self.cols = sorted({k for r in train for k in self.featfn(r)})
        X = np.array([[self.featfn(r).get(c, 0.0) for c in self.cols] for r in train])
        y = np.log([r["i"] for r in train])
        self.mu, self.sig = X.mean(0), X.std(0)
        self.sig[self.sig == 0] = 1
        Z = (X - self.mu) / self.sig
        self.y0 = y.mean()
        A = Z.T @ Z + self.lam * np.eye(Z.shape[1])
        self.w = np.linalg.solve(A, Z.T @ (y - self.y0))
        return self

    def predict(self, r):
        f = self.featfn(r)
        x = (np.array([f.get(c, 0.0) for c in self.cols]) - self.mu) / self.sig
        return float(math.exp(self.y0 + x @ self.w))


class KNN:
    """Median i of the k nearest training rows in a standardised feature space."""

    def __init__(self, name, featfn, k=7):
        self.name, self.featfn, self.k = name, featfn, k

    def fit(self, train):
        self.cols = sorted({c for r in train for c in self.featfn(r)})
        self.X = np.array([[self.featfn(r).get(c, 0.0) for c in self.cols] for r in train])
        self.mu, self.sig = self.X.mean(0), self.X.std(0)
        self.sig[self.sig == 0] = 1
        self.Z = (self.X - self.mu) / self.sig
        self.i = np.array([r["i"] for r in train])
        return self

    def predict(self, r):
        f = self.featfn(r)
        z = (np.array([f.get(c, 0.0) for c in self.cols]) - self.mu) / self.sig
        dist = ((self.Z - z) ** 2).sum(1)
        idx = np.argsort(dist)[: self.k]
        return float(np.median(self.i[idx]))


class GBM:
    """Gradient-boosted trees on log i (scikit-learn), for comparison."""

    def __init__(self, name, featfn):
        self.name, self.featfn = name, featfn

    def fit(self, train):
        from sklearn.ensemble import HistGradientBoostingRegressor
        self.cols = sorted({c for r in train for c in self.featfn(r)})
        X = np.array([[self.featfn(r).get(c, np.nan) for c in self.cols] for r in train])
        # drop columns with fewer than two distinct known values (binning fails)
        keep = [j for j in range(X.shape[1]) if len(np.unique(X[~np.isnan(X[:, j]), j])) >= 2]
        self.cols = [self.cols[j] for j in keep]
        X = X[:, keep]
        y = np.log([r["i"] for r in train])
        self.m = HistGradientBoostingRegressor(max_iter=200, learning_rate=0.05, max_leaf_nodes=15,
                                               min_samples_leaf=10, l2_regularization=1.0,
                                               random_state=0).fit(X, y)
        return self

    def predict(self, r):
        f = self.featfn(r)
        x = np.array([[f.get(c, np.nan) for c in self.cols]])
        return float(math.exp(self.m.predict(x)[0]))


# feature functions -----------------------------------------------------
def f_basic(r):
    return {"logd": math.log(r["diameter_mm"]), "logsd": math.log(r["sd"])}


def f_family(r):
    f = f_basic(r)
    f["fam=" + r["fam"]] = 1.0
    for k, v in r["flags"].items():
        f["flag=" + k] = float(v)
    return f


def f_family_ld(r):
    f = f_family(r)
    if r["ld"]:
        f["ld"] = r["ld"]
        f["has_ld"] = 1.0
    return f


def f_family_brand(r):
    f = f_family_ld(r)
    f["brand=" + r["brand"]] = 1.0
    return f


def f_gbm(r):
    f = f_basic(r)
    f["fam_code"] = float([x for x, _ in FIREARM_FAMILIES + SLUG_FAMILIES + PELLET_FAMILIES].index(r["fam"]))
    for k, v in r["flags"].items():
        f["flag=" + k] = float(v)
    f["ld"] = r["ld"] if r["ld"] else np.nan
    return f


class LdOnly:
    """log i = a + b·log(L/d) where length is known; global median otherwise."""
    name = "M3 length/diameter regression (L known only)"

    def fit(self, train):
        tl = [r for r in train if r["ld"]]
        self.glob = _median_i(train)
        if len(tl) < 5:
            self.ab = None
            return self
        x = np.log([r["ld"] for r in tl])
        y = np.log([r["i"] for r in tl])
        self.ab = np.polyfit(x, y, 1)
        return self

    def predict(self, r):
        if not r["ld"] or self.ab is None:
            return self.glob
        return float(math.exp(np.polyval(self.ab, math.log(r["ld"]))))


class LdFam:
    """Special families (e.g. ELR boat-tail slugs) by their own median; others by
    the L/d regression when length is known, else the median of non-special rows."""

    def __init__(self, name, special):
        self.name, self.special = name, set(special)

    def fit(self, train):
        sp = defaultdict(list)
        for r in train:
            if r["fam"] in self.special:
                sp[r["fam"]].append(r["i"])
        self.sp = {k: float(np.median(v)) for k, v in sp.items() if len(v) >= 3}
        rest = [r for r in train if r["fam"] not in self.sp]
        self.ld = LdOnly().fit(rest)
        return self

    def predict(self, r):
        if r["fam"] in self.sp:
            return self.sp[r["fam"]]
        return self.ld.predict(r)


def estimators(cat):
    fam = lambda r: r["fam"]  # noqa: E731
    ests = [
        GlobalMedian(),
        GroupMedian("M1 family median i", fam),
        GroupMedian("M2 calibre x SD band median i", lambda r: (cal_band(r), sd_band(r)), cal_band),
        GroupMedian("M1+2 family x SD band median i", lambda r: (r["fam"], sd_band(r)), fam),
        LdOnly(),
        GroupMedian("M4 brand median i (k-fold only)", lambda r: r["brand"]),
        GroupMedian("M4b brand x family median i (k-fold only)", lambda r: (r["brand"], r["fam"]),
                    lambda r: r["brand"], fam),
        KNN("M5 nearest neighbours (d, SD, family[, L/d])", f_family_ld, k=7),
        Ridge("M6 ridge log-i regression (d, SD, family, flags, L/d)", f_family_ld, lam=3.0),
        Ridge("M6b ridge + brand (k-fold only)", f_family_brand, lam=3.0),
        GBM("M7 boosted trees (d, SD, family, flags, L/d)", f_gbm),
    ]
    if cat == "slug":
        ests += [
            GroupMedian("S1 ELR keyword vs rest median i", lambda r: r["fam"] == "elr"),
            LdFam("S2 ELR keyword, else L/d regression", ["elr"]),
        ]
    return ests


# ------------------------------------------------------------- validation
def folds_kfold(rows, k=10, seed=0):
    groups = sorted({r["group"] for r in rows})
    rng = np.random.default_rng(seed)
    rng.shuffle(groups)
    gfold = {g: n % k for n, g in enumerate(groups)}
    return [[j for j, r in enumerate(rows) if gfold[r["group"]] == f] for f in range(k)]


def folds_lobo(rows):
    brands = sorted({r["brand"] for r in rows})
    return [[j for j, r in enumerate(rows) if r["brand"] == b] for b in brands]


def evaluate(rows, est, scheme, repeats=5):
    errs, signed = [], []
    runs = [folds_kfold(rows, seed=s) for s in range(repeats)] if scheme == "kfold" else [folds_lobo(rows)]
    for folds in runs:
        e_run = np.full(len(rows), np.nan)
        s_run = np.full(len(rows), np.nan)
        for test in folds:
            if not test:
                continue
            ts = set(test)
            train = [r for j, r in enumerate(rows) if j not in ts]
            if len(train) < 10:
                continue
            est.fit(train)
            for j in test:
                r = rows[j]
                bc = r["sd"] / est.predict(r)
                e_run[j] = abs(bc / r["g1"] - 1)
                s_run[j] = bc / r["g1"] - 1
        errs.append(e_run)
        signed.append(s_run)
    e = np.nanmean(np.array(errs), 0)  # per-row mean over repeats
    s = np.nanmean(np.array(signed), 0)
    e, s = e[~np.isnan(e)], s[~np.isnan(s)]
    return dict(n=int(len(e)), median=float(np.median(e)), p75=float(np.percentile(e, 75)),
                p90=float(np.percentile(e, 90)), bias=float(np.median(s)),
                within10=float(np.mean(e <= 0.10)), within20=float(np.mean(e <= 0.20)))


def insample(rows):
    i = _median_i(rows)
    e = np.array([abs(r["sd"] / i / r["g1"] - 1) for r in rows])
    return dict(n=len(rows), i=i, median=float(np.median(e)), p75=float(np.percentile(e, 75)),
                p90=float(np.percentile(e, 90)))


def final_tables() -> dict:
    """The recommended estimators fitted on ALL rows (what an app table would hold)."""
    res = {}
    fa = dataset("firearm")
    tab = defaultdict(list)
    for r in fa:
        tab[(r["fam"], sd_band(r))].append(r["i"])
    fam = defaultdict(list)
    for r in fa:
        fam[r["fam"]].append(r["i"])
    res["firearm_family_sd"] = {f"{k[0]}|sd_band{k[1]}": dict(n=len(v), i=round(float(np.median(v)), 3))
                                for k, v in sorted(tab.items())}
    res["firearm_family"] = {k: dict(n=len(v), i=round(float(np.median(v)), 3)) for k, v in sorted(fam.items())}
    sl = dataset("slug")
    elr = [r["i"] for r in sl if r["fam"] == "elr"]
    rest = [r for r in sl if r["fam"] != "elr"]
    withl = [r for r in rest if r["ld"]]
    a, b = np.polyfit(np.log([r["ld"] for r in withl]), np.log([r["i"] for r in withl]), 1)
    res["slug"] = dict(elr_i=round(float(np.median(elr)), 3), elr_n=len(elr),
                       rest_i=round(float(np.median([r["i"] for r in rest])), 3), rest_n=len(rest),
                       ld_fit=f"ln i = {b:.3f} + {a:.3f}·ln(L/d)  (n={len(withl)}, "
                              f"L/d {min(r['ld'] for r in withl):.2f}–{max(r['ld'] for r in withl):.2f})")
    pe = dataset("pellet")
    pf = defaultdict(list)
    for r in pe:
        pf[r["fam"]].append(r["i"])
    res["pellet_family"] = {k: dict(n=len(v), i=round(float(np.median(v)), 3)) for k, v in sorted(pf.items())}
    by_brand = defaultdict(list)
    for r in sl:
        by_brand[r["brand"]].append(r["i"])
    res["slug_brand_median_i"] = {k: dict(n=len(v), i=round(float(np.median(v)), 3)) for k, v in by_brand.items()}
    for k, v in res.items():
        print("\n", k, json.dumps(v, ensure_ascii=False))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", type=Path)
    args = ap.parse_args()
    out = {}
    for cat in ("firearm", "slug", "pellet"):
        rows = dataset(cat)
        out[cat] = {"insample_global_median": insample(rows), "families": {}, "methods": {}}
        fams = defaultdict(list)
        for r in rows:
            fams[r["fam"]].append(r["i"])
        out[cat]["families"] = {k: dict(n=len(v), median_i=float(np.median(v)),
                                        q25=float(np.percentile(v, 25)), q75=float(np.percentile(v, 75)))
                                for k, v in sorted(fams.items())}
        out[cat]["n_with_length"] = sum(1 for r in rows if r["ld"])
        print(f"\n=== {cat}: n={len(rows)}  brands={len({r['brand'] for r in rows})}  "
              f"with length={out[cat]['n_with_length']}")
        print("in-sample global median:", {k: round(v, 3) for k, v in out[cat]['insample_global_median'].items()})
        for k, v in out[cat]["families"].items():
            print(f"  family {k:12s} n={v['n']:4d} median i={v['median_i']:.3f} IQR {v['q25']:.3f}-{v['q75']:.3f}")
        schemes = ["kfold"] + (["lobo"] if len({r["brand"] for r in rows}) >= 3 else [])
        for est in estimators(cat):
            res = {}
            for sc in schemes:
                if sc == "lobo" and ("k-fold only" in est.name):
                    continue
                res[sc] = evaluate(rows, est, sc)
            out[cat]["methods"][est.name] = res
            line = "  ".join(f"{sc}: med {v['median']*100:5.1f}% p75 {v['p75']*100:5.1f}% "
                             f"p90 {v['p90']*100:5.1f}% bias {v['bias']*100:+5.1f}%"
                             for sc, v in res.items())
            print(f"  {est.name:58s} {line}")
        # length-known subset: does L/d help where it is known?
        sub = [r for r in rows if r["ld"]]
        if len(sub) >= 30:
            out[cat]["length_subset"] = {}
            for est in [GlobalMedian(), GroupMedian("M1 family median i", lambda r: r["fam"]), LdOnly(),
                        Ridge("M6 ridge (no L/d)", f_family, lam=3.0),
                        Ridge("M6 ridge + L/d", f_family_ld, lam=3.0)]:
                res = {sc: evaluate(sub, est, sc) for sc in schemes}
                out[cat]["length_subset"][est.name] = res
                line = "  ".join(f"{sc}: med {v['median']*100:5.1f}% p75 {v['p75']*100:5.1f}% p90 {v['p90']*100:5.1f}%"
                                 for sc, v in res.items())
                print(f"  [L known, n={len(sub)}] {est.name:40s} {line}")
        if cat == "firearm":
            ext = factory_external(rows)
            out[cat]["external_factory"] = {}
            print(f"  external factory-ammo check (trained on bullet library): n={len(ext)}")
            for est in [GlobalMedian(), GroupMedian("M1 family median i", lambda r: r["fam"]),
                        GroupMedian("M1+2 family x SD band median i", lambda r: (r["fam"], sd_band(r)),
                                    lambda r: r["fam"]),
                        Ridge("M6 ridge log-i regression", f_family_ld, lam=3.0),
                        KNN("M5 kNN", f_family_ld, k=7)]:
                est.fit(rows)
                e = np.array([abs(r["sd"] / est.predict(r) / r["g1"] - 1) for r in ext])
                res = dict(n=len(e), median=float(np.median(e)), p75=float(np.percentile(e, 75)),
                           p90=float(np.percentile(e, 90)))
                out[cat]["external_factory"][est.name] = res
                print(f"    {est.name:40s} med {res['median']*100:5.1f}% p75 {res['p75']*100:5.1f}% p90 {res['p90']*100:5.1f}%")
    out["final_tables"] = final_tables()
    if args.json:
        args.json.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()

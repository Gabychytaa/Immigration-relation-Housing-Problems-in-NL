import os, csv, io, re, pandas as pd
from typing import Dict, Optional, List, Tuple
from pathlib import Path
import unicodedata
import re
from functools import lru_cache

try:
    import cbsodata
except ImportError as e:
    raise ImportError(
        "cbsodata is not installed. In a notebook run: %pip install -U cbsodata"
    ) from e

def _norm(s: str) -> str:
    s = str(s).replace("\u00a0"," ")
    return s.strip().strip('"').strip("'").lower()

def _norm(s: str) -> str:
    s = str(s).replace("\u00a0"," ")
    return s.strip().strip('"').strip("'").lower()

def extract_statline_maps(meta_path: str) -> Dict[str, Dict[str, str]]:
    """
    Parse a CBS metadata file that is CSV-within-CSV:
      - Outer CSV delimiter is comma, real content lives in the first column as a quoted string.
      - Inside that string, section headers/rows are semicolon-separated.
      - We find any header line containing 'Key' and 'Title' (semicolon CSV),
        grab the nearest non-empty line above as the section title,
        and read rows until a blank or the next header.
    Returns: { <section title>: {Key -> Title}, ... }
    """
    if not os.path.exists(meta_path):
        print(f"[meta] File not found: {meta_path}")
        return {}

    # 1) Read outer CSV (comma). Keep the first cell of each row as our logical "line".
    with open(meta_path, "r", encoding="utf-8") as f:
        outer = list(csv.reader(f, delimiter=","))

    lines = []
    for row in outer:
        # Some rows might be empty; keep empty string for alignment
        first = row[0] if row else ""
        # Normalize BOM on the first cell if present
        if first.startswith("\ufeff"):
            first = first.lstrip("\ufeff")
        lines.append(first)

    def is_header(s: str) -> bool:
        # header is a semicolon CSV line that contains Key and Title
        return ("Key" in s and "Title" in s and ";" in s)

    # 2) Find all header indices
    header_idxs = [i for i, ln in enumerate(lines) if is_header(ln)]
    if not header_idxs:
        print("[meta] No header lines found (no 'Key;Title' headers).")
        return {}

    # 3) Pair each header with a title (nearest non-empty line above)
    blocks = []  # (title, header_idx, start_row_idx, end_row_idx_exclusive)
    for hidx in header_idxs:
        # find title line above
        title = None
        j = hidx - 1
        while j >= 0:
            s = lines[j].strip()
            if s != "":
                title = s.strip().strip('"').strip("'")
                break
            j -= 1
        if title is None:
            title = f"Section_{hidx}"

        # data rows start after header
        start = hidx + 1

        # stop at blank line or next header
        k = start
        while k < len(lines):
            s = lines[k].strip()
            if s == "" or is_header(s):
                break
            k += 1
        end = k
        blocks.append((title, hidx, start, end))

    # 4) Build maps by parsing the semicolon-CSV lines in each block
    maps: Dict[str, Dict[str, str]] = {}
    for title, hidx, start, end in blocks:
        header = next(csv.reader([lines[hidx].strip()], delimiter=";"))
        rows = []
        for r in range(start, end):
            row = next(csv.reader([lines[r].strip()], delimiter=";"))
            if len(row) < len(header):
                row += [""] * (len(header) - len(row))
            rows.append(row)
        if not rows:
            continue

        sec = pd.DataFrame(rows, columns=header)
        # clean string cells
        for c in sec.columns:
            if sec[c].dtype == object:
                sec[c] = sec[c].str.replace("\u00a0"," ", regex=False).str.strip('"').str.strip()

        if "Key" in sec.columns and "Title" in sec.columns and len(sec):
            maps[title] = dict(zip(sec["Key"], sec["Title"]))

    if not maps:
        print("[meta] Parsed 0 sections with Key/Title.")
    else:
        print(f"[meta] Parsed {len(maps)} sections.")
        # Uncomment to see a quick summary:
        # print(", ".join(f"{t}({len(m)})" for t,m in list(maps.items())[:12]))

    return maps

def decode_statline_local(data_path: str, meta_path: str) -> pd.DataFrame:
    """
    Decode a CBS StatLine CSV using its metadata maps.
    Maps codes -> labels for Geslacht / Leeftijd / Nationaliteit / Perioden when available.
    """
    df = pd.read_csv(data_path, sep=";")

    # normalize headers
    df.columns = (
        df.columns.astype(str)
          .str.replace("\u00a0"," ", regex=False)
          .str.replace(r'^[#\s]+','', regex=True)
          .str.strip().str.strip('"').str.strip("'")
    )

    maps_all = extract_statline_maps(meta_path)

    # fuzzy finder: pick the section whose title contains our keyword
    def find_map(keyword: str) -> Optional[Dict[str, str]]:
        kw = _norm(keyword)
        for t, m in maps_all.items():
            if kw in _norm(t):
                return m
        return None

    map_geslacht = find_map("Geslacht")
    map_leeftijd = find_map("Leeftijd")
    map_nat      = find_map("Nationaliteit")
    map_perioden = find_map("Perioden")

    def apply_map(col_name: str, mapping: Optional[Dict[str,str]], label: str):
        if col_name in df.columns:
            if mapping:
                df[col_name] = (
                    df[col_name].astype(str)
                      .str.replace("\u00a0"," ", regex=False)
                      .str.strip()
                      .map(mapping)
                      .fillna(df[col_name])
                )
            else:
                print(f"[decode] No mapping found for {label}.")
        # silently skip if column absent

    apply_map("Geslacht",      map_geslacht, "Geslacht")
    apply_map("Leeftijd",      map_leeftijd, "Leeftijd")
    apply_map("Nationaliteit", map_nat,      "Nationaliteit")
    apply_map("Perioden",      map_perioden, "Perioden")

    return df

def load_cbs_dataset(basepath: str, table_id: str):
    data_path = f"{basepath}/{table_id}_UntypedDataSet.csv"
    meta_path = f"{basepath}/{table_id}_metadata.csv"
    return decode_statline_local(data_path, meta_path)

def decode_nationaliteit(df: pd.DataFrame, meta_path: str,
                         col: str = "Nationaliteit") -> pd.DataFrame:
    """
    Decode 'Nationaliteit' codes (e.g. NAT9487) in a CBS dataset using its metadata file.
    Keeps original value if no mapping is found.
    """
    # read full metadata file
    text = Path(meta_path).read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()

    # find the "Nationaliteit" section
    try:
        start = next(i for i, l in enumerate(lines) if l.strip('"') == "Nationaliteit")
    except StopIteration:
        raise ValueError("Section 'Nationaliteit' not found in metadata")

    # detect where the section ends (usually at "Perioden")
    try:
        end = next(i for i, l in enumerate(lines[start+1:], start+1)
                   if l.strip('"') in ["Geslacht","Leeftijd","Perioden","DataProperties","TableInfos"])
    except StopIteration:
        end = len(lines)

    # parse the block using csv.reader (handles quoted fields with semicolons inside)
    block = "\n".join(lines[start+1:end])
    rows = list(csv.reader(io.StringIO(block), delimiter=";", quotechar='"'))

    # build DataFrame for the mapping
    meta_nat = pd.DataFrame(rows[1:], columns=rows[0])  # skip header row
    meta_nat = meta_nat.rename(columns=lambda c: c.strip())
    for c in meta_nat.columns:
        meta_nat[c] = meta_nat[c].astype(str).str.strip()

    # build dictionary Key → Title
    nat_map = dict(zip(meta_nat["Key"].str.upper().str.strip(),
                       meta_nat["Title"].str.strip()))

    # apply mapping to dataframe
    if col in df.columns:
        df = df.copy()
        df[col] = (
            df[col].astype(str).str.strip().str.upper()
            .map(nat_map)
            .fillna(df[col])
        )
    return df

import csv, pandas as pd, numpy as np
from pathlib import Path

def _read_meta_sections(meta_path):
    # Read entire metadata honoring quoted newlines
    with open(meta_path, encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f, delimiter=";"))
    # clean cells
    rows = [[(c or "").strip().strip('"').strip("'") for c in r] for r in rows]

    # detect ANY section title row: first cell non-empty, all other cells empty
    titles = []
    for i, r in enumerate(rows):
        if not r: 
            continue
        if r[0] and all(c == "" for c in r[1:]):
            titles.append((r[0], i))

    # build blocks
    blocks = []
    for k, (title, i) in enumerate(titles):
        h = i + 1        # header
        s = i + 2        # start
        e = titles[k+1][1] if k+1 < len(titles) else len(rows)
        blocks.append((title, h, s, e))

    # build maps for every block that has Key + a title-like column
    all_maps = {}
    for title, h, s, e in blocks:
        header = rows[h] if h < len(rows) else []
        body = rows[s:e]
        if not header or not body or "Key" not in header:
            continue

        # choose a label column
        label_candidates = ["Title","Titel","Omschrijving","Description","Name","Naam","ShortTitle","Shorttitle"]
        label_col = next((c for c in label_candidates if c in header), None)
        if label_col is None:
            continue

        L = len(header)
        fixed = [(r[:L] + [""] * max(0, L - len(r))) for r in body]
        sec = pd.DataFrame(fixed, columns=header)

        for c in sec.columns:
            if sec[c].dtype == object:
                sec[c] = (sec[c].astype(str)
                          .str.replace("\u00a0"," ", regex=False)
                          .str.strip())

        m = dict(zip(sec["Key"].str.upper().str.strip(), sec[label_col].str.strip()))
        all_maps[title] = m

    return all_maps

def _norm(s):
    return str(s).lower().replace("-", " ").replace("_", " ").strip()

def decode_using_meta_any(df, meta_path):
    maps = _read_meta_sections(meta_path)
    if not maps:
        print("[decode] No sections parsed from metadata.")
        return df

    # try to match each df column either by section title similarity OR by key pattern
    out = df.copy()
    for col in df.columns:
        # skip numeric columns
        if not pd.api.types.is_object_dtype(df[col]):
            continue
        sample = out[col].dropna().astype(str)
        if sample.empty:
            continue

        # guess by code pattern in the data
        # e.g., NAT\d+, \d{4}(JJ|KW|MM)\d{2}, A0\d+, etc.
        keys_upper = sample.head(50).str.upper().str.strip()

        # find a map that contains many of these keys
        best_title, best_hits = None, 0
        for title, mp in maps.items():
            hit = keys_upper.isin(mp.keys()).sum()
            if hit > best_hits:
                best_title, best_hits = title, hit

        if best_hits >= 5:  # heuristic: enough keys matched
            out[col] = out[col].astype(str).str.upper().str.strip().map(maps[best_title]).fillna(out[col])
            # print(f"[decode] applied {best_title} to column {col}")
            continue

        # fallback: title~column name similarity (for textual columns like Geslacht/Leeftijd)
        coln = _norm(col)
        best_title2 = None
        for title in maps.keys():
            tn = _norm(title)
            if coln in tn or tn in coln:
                best_title2 = title
                break
        if best_title2:
            out[col] = out[col].astype(str).str.upper().str.strip().map(maps[best_title2]).fillna(out[col])
            # print(f"[decode] applied {best_title2} to column {col}")

    return out

# --- NEW: robust metadata reader (does NOT replace your existing one) ---
import csv
import pandas as pd
from typing import Dict, List, Tuple, Optional

def read_statline_maps_robust(meta_path: str) -> Dict[str, Dict[str, str]]:
    """
    Read a CBS *_metadata.csv into {section_title -> {Key -> Label}}.
    Robust to quoted newlines and minor formatting quirks.
    """
    with open(meta_path, encoding="utf-8", newline="") as f:
        all_rows = list(csv.reader(f, delimiter=";"))

    # clean cells
    all_rows = [[(c or "").strip().strip('"').strip("'") for c in r] for r in all_rows]

    # detect section title rows: first cell non-empty, the rest empty
    title_positions: List[Tuple[str, int]] = []
    for i, r in enumerate(all_rows):
        if r and r[0] and all(c == "" for c in r[1:]):
            title_positions.append((r[0], i))
    if not title_positions:
        return {}

    # build blocks: title row -> header row -> data rows until next title
    blocks: List[Tuple[str, int, int, int]] = []
    title_positions.sort(key=lambda x: x[1])
    for k, (title, trow) in enumerate(title_positions):
        hidx = trow + 1
        start = trow + 2
        end = title_positions[k+1][1] if k+1 < len(title_positions) else len(all_rows)
        blocks.append((title, hidx, start, end))

    maps: Dict[str, Dict[str, str]] = {}
    label_candidates = ["Title","Titel","Omschrijving","Description","Name","Naam","ShortTitle","Shorttitle"]

    for title, hidx, start, end in blocks:
        header = all_rows[hidx] if hidx < len(all_rows) else []
        body = all_rows[start:end]
        if not header or not body or "Key" not in header:
            continue

        # align ragged rows
        L = len(header)
        fixed = [(r[:L] + [""] * max(0, L - len(r))) for r in body]
        sec = pd.DataFrame(fixed, columns=header)

        # clean strings
        for c in sec.columns:
            if sec[c].dtype == object:
                sec[c] = (sec[c].astype(str)
                          .str.replace("\u00a0"," ", regex=False)
                          .str.strip())

        # pick a label column
        lab = next((c for c in label_candidates if c in sec.columns), None)
        if not lab:
            continue

        keys = sec["Key"].astype(str).str.upper().str.strip()
        vals = sec[lab].astype(str).str.strip()
        maps[title] = dict(zip(keys, vals))

    return maps


def decode_columns_with_maps(df: pd.DataFrame,
                             meta_path: str,
                             columns: Optional[List[str]] = None) -> pd.DataFrame:
    """
    Apply robust metadata maps to selected columns (object dtype).
    Does NOT modify the original df.
    """
    maps = read_statline_maps_robust(meta_path)
    if not maps:
        print("[decode+] No sections parsed from metadata.")
        return df

    out = df.copy()
    cols = columns or [c for c in out.columns if out[c].dtype == "object"]

    # helper: pick best map by # of keys matched in the column
    def best_map_for(series: pd.Series) -> Optional[Dict[str,str]]:
        sample = series.dropna().astype(str).str.upper().str.strip()
        if sample.empty:
            return None
        best_title, best_hits = None, 0
        for title, mp in maps.items():
            hits = sample.isin(mp.keys()).sum()
            if hits > best_hits:
                best_title, best_hits = title, hits
        return maps.get(best_title) if best_hits >= 3 else None  # threshold

    for col in cols:
        mp = best_map_for(out[col])
        if mp:
            out[col] = out[col].astype(str).str.upper().str.strip().map(mp).fillna(out[col])

    return out

def norm_text(s):
    return (s.astype("string")
             .str.replace("\u00A0"," ", regex=False)  # NBSP → space
             .str.strip()
             .str.lower()
             .str.normalize("NFKC"))

def norm_key(x: str) -> str:
    x = str(x).replace("\u00A0"," ").strip().lower()
    return unicodedata.normalize("NFKC", x)

def extract_block(text, dim_name):
    # look for the line with the dim name in quotes on its own line (CBS style)
    # then collect lines until next empty line or next quoted section title
    pat = re.compile(rf'^\s*"{re.escape(dim_name)}"\s*$', re.MULTILINE)
    m = pat.search(text)
    if not m:
        return None
    start = m.end()
    # skip potential blank line
    rest = text[start:].lstrip("\n")
    lines = []
    for line in rest.split("\n"):
        if not line.strip():           # blank line => end
            break
        if re.match(r'^\s*"[A-Za-z].*"\s*$', line) and ";" not in line:
            # looks like the next section title
            break
        lines.append(line)
    if not lines:
        return None
    # the block uses ; as delimiter and double quotes for quotes; also doubles quotes inside ("")
    block = "\n".join(l.replace('""','"').strip('"') for l in lines)
    try:
        df = pd.read_csv(io.StringIO(block), sep=";", engine="python", dtype=str)
    except Exception:
        df = None
    return df

@lru_cache(maxsize=None)
def cbs_code_map(dataset: str, dimension: str) -> dict:
    """
    Fetch the official code→label map for one dimension of a CBS dataset.
    Cached so repeated calls are instant.
    """
    meta = pd.DataFrame(get_meta(dataset, dimension))
    # pick sensible columns (CBS uses these names)
    key_col = next((c for c in ["Key", "ID", "Identifier"] if c in meta.columns), None)
    lbl_col = next((c for c in ["Title", "TitleShort", "Omschrijving", "ShortTitle", "Description"] if c in meta.columns), None)
    if key_col is None or lbl_col is None:
        # last-resort fallback
        key_col = meta.columns[0]
        lbl_col = meta.columns[1]
    return dict(zip(meta[key_col].astype(str), meta[lbl_col].astype(str)))

def cbs_decode_columns(df: pd.DataFrame, dataset: str, dims: list[str]) -> pd.DataFrame:
    """
    Map code columns to human labels in-place (no merges).
    Unknown codes are left as-is.
    """
    out = df.copy()
    for dim in dims:
        if dim in out.columns:
            m = cbs_code_map(dataset, dim)
            out[dim] = out[dim].astype(str).map(m).fillna(out[dim])
    return out

def add_period_parts(df: pd.DataFrame, period_col: str = "Perioden") -> pd.DataFrame:
    """
    Parse CBS Period codes into Int64 year/month/quarter columns.
    Supports YYYY, YYYYMMnn, YYYYKWnn, YYYYJJnn.
    """
    if period_col not in df.columns:
        return df
    def _parse(s: str):
        s = str(s)
        y = m = q = None
        m1 = re.match(r"^(\d{4})MM(\d{2})$", s, flags=re.I)
        q1 = re.match(r"^(\d{4})KW(\d{2})$", s, flags=re.I)
        y1 = re.match(r"^(\d{4})JJ\d{2}$", s, flags=re.I)
        y0 = re.match(r"^(\d{4})$", s)
        if m1: y, m = int(m1.group(1)), int(m1.group(2))
        elif q1: y, q = int(q1.group(1)), int(q1.group(2))
        elif y1: y = int(y1.group(1))
        elif y0: y = int(y0.group(1))
        return y, m, q
    parsed = df[period_col].apply(_parse)
    out = df.copy()
    out["year"]    = pd.array([t[0] for t in parsed], dtype="Int64")
    out["month"]   = pd.array([t[1] for t in parsed], dtype="Int64")
    out["quarter"] = pd.array([t[2] for t in parsed], dtype="Int64")
    return out

def get_meta(dataset: str, dimension: str):
    """Return CBS StatLine metadata for a given dataset+dimension."""
    return cbsodata.get_meta(dataset, dimension)
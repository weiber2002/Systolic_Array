#!/usr/bin/env python3
# ==============================================================
#  data_generate.py – Fixed-Point Matrix Generator
#    • matrixA  固定 16×4 = 64 words
#    • matrixB  固定  4×16 = 64 words
#    • matrixO  固定 16×16 = 256 words（若 n < 16，其他元素補 0）
# ==============================================================
from pathlib import Path
from typing   import List, Optional
import numpy as np, random, time

# ---------- 參數 ----------
DATA_WIDTH = 16
Q          = 15
SAT_MIN    = -(1 << (DATA_WIDTH - 1))
SAT_MAX    =  (1 << (DATA_WIDTH - 1)) - 1

OUT_DIR = Path(__file__).resolve().parent / "../python/data"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ---------- 工具 ----------
def float_to_fixed(x: np.ndarray, q: int = Q) -> np.ndarray:
    return (x * (1 << q)).astype(np.int16)

def matmul_fixed(a: np.ndarray, b: np.ndarray, q: int = Q) -> np.ndarray:
    acc = a.astype(np.int64) @ b.astype(np.int64)
    acc >>= q
    acc = np.clip(acc, SAT_MIN, SAT_MAX)
    return acc.astype(np.int16)

def emit_hex_and_float(arr: np.ndarray, stem: Path, q: int = Q) -> None:
    """Row-major，每行一 word；同步輸出 float 方便人工檢查。"""
    hex_p   = stem.with_suffix(".hex")
    float_p = stem.with_name(stem.name + "_float.txt")
    scale   = 1 << q
    with open(hex_p, "w") as fh, open(float_p, "w") as ft:
        for x in arr.flatten(order="C"):
            hexstr = f"{x & 0xFFFF:04x}"
            fh.write(hexstr + "\n")
            ft.write(f"{x / scale:+.7f}\t{hexstr}\n")
# ---------- 主流程 ----------
def main(seed: Optional[int] = None) -> None:
    # 1. 隨機種子
    np.random.seed(int(time.time()) if seed is None else seed)
    random.seed(np.random.randint(0, 2**32 - 1))

    # 2. 隨機指令序列（允許重覆）
    instr_candidates = [4, 8, 16]
    L = random.randint(1, 3)              # 指令長度 1~3
    INSTR: List[int] = [random.choice(instr_candidates) for _ in range(L)]
    # 例如可能得到 [4, 4, 4] 或 [16, 4, 8] 等
    print(f"[Info] 隨機指令序列：{INSTR}")

    # 3. 寫 inst.hex（結尾補 0）
    with open(OUT_DIR / "inst.hex", "w") as f:
        for ins in INSTR:
            f.write(f"{ins:X}\n")
        f.write("0\n")

    # 4. 產生最大 n 所需隨機矩陣
    n_max, K_FIXED = max(INSTR), 4
    A_full = float_to_fixed(np.random.uniform(-1.0, 1.0, (n_max, K_FIXED)))
    B_full = float_to_fixed(np.random.uniform(-1.0, 1.0, (K_FIXED, n_max)))

    # 5. 輸出各子矩陣
    for idx, n in enumerate(INSTR, start=1):
        prefix = f"matrix{idx}"

        # --- matrixA：16×4 ---
        A_pad = np.zeros((16, K_FIXED), dtype=np.int16)
        A_pad[:n, :] = A_full[:n, :]
        emit_hex_and_float(A_pad, OUT_DIR / f"{prefix}_A")

        # --- matrixB：4×16 ---
        B_pad = np.zeros((K_FIXED, 16), dtype=np.int16)
        B_pad[:, :n] = B_full[:, :n]
        emit_hex_and_float(B_pad, OUT_DIR / f"{prefix}_B")

        # --- matrixO：16×16 ---
        O_sub = matmul_fixed(A_full[:n, :], B_full[:, :n])
        O_pad = np.zeros((16, 16), dtype=np.int16)
        O_pad[:n, :n] = O_sub
        emit_hex_and_float(O_pad, OUT_DIR / f"{prefix}_O")

    print("[Done] 檔案輸出至", OUT_DIR)


if __name__ == "__main__":
    main()

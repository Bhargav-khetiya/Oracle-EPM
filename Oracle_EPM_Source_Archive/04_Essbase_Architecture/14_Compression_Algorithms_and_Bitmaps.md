# 14 — Essbase Compression Algorithms & Bitmap Internals

---

## 14.1 Why Essbase Compresses Blocks

In an Essbase BSO database, a data block represents all intersections of the **Dense** dimensions for one specific combination of Sparse members:
$$\text{Block Size (Uncompressed)} = (\text{Dense}_1 \times \text{Dense}_2 \times \dots \times \text{Dense}_N) \times 8\text{ bytes}$$

If a block contains 2,000 dense cells, its uncompressed memory size is $2,000 \times 8 = 16,000\text{ bytes (16 KB)}$.
However, within that block, many cells may be `#MISSING` (empty). Storing empty 8-byte floats on disk would waste gigabytes of disk space and saturate storage I/O bandwidth.

Essbase provides **4 distinct compression algorithms** to compress blocks when writing them from RAM (Data Cache) into physical disk storage (`.PAG` files).

---

## 14.2 The 4 Compression Types

```
┌────────────────────────────────────────────────────────────────────────┐
│                        COMPRESSION TYPES IN ESSBASE                    │
├─────────────┬──────────────────────────────────────────────────────────┤
│ 1. NONE     │ Stores raw uncompressed 8-byte IEEE floats on disk       │
├─────────────┼──────────────────────────────────────────────────────────┤
│ 2. RLE      │ Run-Length Encoding: Compresses sequential #MISSING cells│
├─────────────┼──────────────────────────────────────────────────────────┤
│ 3. BITMAP   │ Bitmask array marking cell presence (Default & Standard) │
├─────────────┼──────────────────────────────────────────────────────────┤
│ 4. ZLIB     │ Lempel-Ziv dictionary compression (Deflate algorithm)    │
└─────────────┴──────────────────────────────────────────────────────────┘
```

---

## 14.3 Deep Dive: The Bitmap Compression Mechanics (Byte-by-Byte)

**Bitmap Compression** is the signature engineering breakthrough of the Essbase BSO storage engine.

### The Algorithm:
1. Essbase creates a **Bitmask Header** where **1 bit corresponds to 1 dense cell**.
   * Bit = `1`: Cell contains a valid numeric value.
   * Bit = `0`: Cell is `#MISSING`.
2. Following the bitmask header, Essbase writes **only the cells with Bit = 1**.
3. All `#MISSING` cells are completely omitted from disk!

### Concrete Byte-by-Byte Mathematical Example:
Assume a dense block of **16 cells**:

```
Cell Index:  00  01  02  03  04  05  06  07  08  09  10  11  12  13  14  15
Cell Value:  100  #M  #M  250  #M  #M  #M  #M  #M  #M  500  #M  #M  #M  #M  #M
```

#### Uncompressed Size:
$$16 \text{ cells} \times 8 \text{ bytes} = \mathbf{128 \text{ bytes}}$$

#### Bitmap Compressed Size:
1. **Bitmask Header**:
   * 16 cells require 16 bits = **2 bytes**.
   * Binary mask: `1 0 0 1 0 0 0 0  0 0 1 0 0 0 0 0` (Hex: `0x90 0x20`).
2. **Payload (Stored Non-Missing Cells)**:
   * Cell 00: `100.0` (8 bytes)
   * Cell 03: `250.0` (8 bytes)
   * Cell 10: `500.0` (8 bytes)
   * Total payload = $3 \times 8 = \mathbf{24 \text{ bytes}}$.
3. **Total Disk Footprint**:
   $$\text{Total Size} = 2 \text{ bytes (header)} + 24 \text{ bytes (data)} = \mathbf{26 \text{ bytes}}$$
   $$\text{Compression Ratio} = \frac{26}{128} = \mathbf{79.7\% \text{ reduction in disk space!}}$$

When Essbase reads the block from `.PAG` back into the Data Cache:
* It reads the 26 bytes from disk.
* Allocates 128 bytes in RAM.
* Reads the bitmask: whenever a bit is `0`, it writes `#MISSING`; whenever a bit is `1`, it pulls the next 8-byte float from the payload.
* The block is expanded in RAM in microseconds.

---

## 14.4 ZLIB Compression: When and Why to Use It

While Bitmap compression eliminates `#MISSING` cells, it stores non-missing cells as full 8-byte binary floats.
* **ZLIB (Lempel-Ziv / Deflate)**: Applies dictionary-based pattern compression across the entire block, compressing repeating numeric patterns, zeros, and similar floating-point byte sequences.

### When ZLIB Outperforms Bitmap:
1. **High Data Density (> 40% - 50%)**: If a block is densely populated, Bitmap saves very little space because almost all bits are `1`. ZLIB can compress dense numbers by a further 30% to 60%.
2. **Large Block Sizes (> 100 KB - 500 KB)**: ZLIB dictionary algorithms achieve higher compression ratios on large byte buffers.
3. *Trade-off*: ZLIB requires slightly more CPU cycles to decompress than Bitmap.

---

## 14.5 Compression Decision Matrix

| Cube Characteristic | Recommended Compression | Rationale |
| :--- | :---: | :--- |
| **Typical Planning Cube** (Block Density 1% – 20%, Block Size 10 KB – 80 KB) | **`BITMAP`** *(Default)* | Maximum decompression speed with low CPU overhead; perfectly eliminates sparse cell waste. |
| **Dense Financial Cube** (Block Density > 35%, Block Size > 100 KB) | **`ZLIB`** | Achieves maximum disk space reduction when blocks have few `#MISSING` cells. |
| **Heavy Sequential Missing Data** (Many empty consecutive months) | **`RLE`** | Extremely fast compression of long repeating sequences. |
| **Micro-Cubes / In-Memory RAM Disks** | **`NONE`** | Zero CPU overhead for decompression; best when disk I/O is not a bottleneck. |

---

## 14.6 Changing Compression Type via MaxL

```sql
/* Check current compression setting */
display database 'FinPlan'.'FinPlan' all;

/* Alter database compression to ZLIB */
alter database 'FinPlan'.'FinPlan' set compression zlib;

/* Alter database compression to BITMAP */
alter database 'FinPlan'.'FinPlan' set compression bitmap;

/* Force restructuring to rewrite .PAG files with new compression */
alter database 'FinPlan'.'FinPlan' force restructuring;
```

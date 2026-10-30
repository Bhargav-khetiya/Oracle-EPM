# ⚡ Dimension Properties — Member Formula Compilation & Execution Internals

> **Purpose**: This technical manual details the internal C++ compilation of Essbase member formulas into Abstract Syntax Trees (ASTs) and bytecode, the execution differences between dense and sparse formulas, memory footprints, and cross-cube data streaming via `@XREF` and `@XWRITE`.

---

## 1. Member Formula Compilation: Source Text to Bytecode

When an administrator saves or refreshes an outline in Oracle EPM Cloud or Essbase, the outline compiler evaluates every member formula through a 4-phase compilation pipeline:

```
[Member Formula String: "Margin %" = "Gross Margin" / "Revenue" * 100;]
                                  │
                                  ▼
                [Phase 1: Lexical Analysis & Tokenizer]
                ├── Tokens: [MEMBER, "Margin %"], [ASSIGN], 
                │           [MEMBER, "Gross Margin"], [DIV], 
                │           [MEMBER, "Revenue"], [MUL], [LITERAL, 100]
                                  │
                                  ▼
                [Phase 2: Abstract Syntax Tree (AST) Generation]
                │                       *
                │                     /   \
                │                    /     100
                │                   /
                │                  /
                │            "Gross Margin"  "Revenue"
                                  │
                                  ▼
                [Phase 3: Semantic Analysis & Type Verification]
                ├── Verifies member existence in outline
                ├── Validates dimensionality: Dense vs Sparse
                └── Assigns Solve Order and Two-Pass tags
                                  │
                                  ▼
                [Phase 4: Bytecode Compilation & Memory Packing]
                └── Serializes AST into Essbase bytecode vector stored in .OTL
```

---

## 2. Dense Formulas vs. Sparse Formulas: Execution Engine Differences

Where a member formula resides in the dimensional hierarchy (Dense vs. Sparse) fundamentally alters the runtime behavior and memory mechanics of the Essbase kernel:

```
┌───────────────────────────────────────────────┬───────────────────────────────────────────────┐
│             DENSE MEMBER FORMULA              │             SPARSE MEMBER FORMULA             │
├───────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ Example: Formula on Account or Period         │ Example: Formula on Entity or Product         │
│ Evaluated **in-place** inside a single block  │ Evaluates **across multiple physical blocks** │
│ Fast: No block header locking or index lookups│ Slow: May force loading / creating new blocks │
│ Calculated whenever the block is loaded in RAM│ Triggers Top-Down calculation if unguarded    │
│ Zero I/O overhead                             │ High I/O overhead & risk of block thrashing   │
└───────────────────────────────────────────────┴───────────────────────────────────────────────┘
```

### The Physics of Dense Formula Execution
When an Account formula runs (e.g., `"Operating Income" = "Gross Profit" - "Operating Expense";`):
1. The sparse block (e.g., `Entity_A -> FY24 -> Working`) is already loaded in RAM.
2. The formula calculates the value directly at the dense cell offset:

$$\text{Memory Address} = \text{Block Base Address} + (\text{Dense Offset} \times 8 \text{ bytes})$$

3. No index search or disk fetch is required. It computes at CPU register speeds.

### The Physics of Sparse Formula Execution
When an Entity formula runs (e.g., `"Entity_A" = "Entity_B" * 0.5;`):
1. The kernel cannot simply calculate a cell in the current block.
2. It must query the `.IND` B-Tree to find the physical block pointer for `Entity_B`.
3. It loads the `Entity_B` block from `.PAG` into the data cache.
4. It reads the dense array, multiplies by $0.5$, and copies the result into the `Entity_A` block.
5. If `Entity_A` did not previously exist, the engine must perform a **dynamic block creation**, updating the sparse index tree and acquiring index latches.

---

## 3. Cross-Cube Data Streaming: `@XREF` and `@XWRITE`

When formulas transfer data across separate Essbase databases or EPM Cloud cubes, the kernel uses specialized remote procedure calls:

```
┌─────────────────────────┐                            ┌─────────────────────────┐
│     SOURCE DATABASE     │                            │     TARGET DATABASE     │
│       (e.g. Oep_FS)     │                            │      (e.g. Oep_WFP)     │
│                         │   TCP Socket Buffer (RAM)  │                         │
│   [Essbase Data Block]  │ ─────────────────────────► │   [Essbase Data Block]  │
│   Cell: "Salary" = 5000 │        Port 1423 / TLS     │   Cell: "Emp_Exp" = 5000│
└─────────────────────────┘                            └─────────────────────────┘
```

### 1. `@XREF` (Pull Mechanism)
- **Syntax**: `@XREF(RemoteLocationName, [Member_List])`
- **Execution Flow**:
  - The target cube initiates a query to the remote source cube.
  - The source cube compiles an internal retrieval query, fetches the block, extracts the cell, and transmits the 8-byte floating point number back across the internal TCP socket.
- **Architectural Bottleneck**: Executing `@XREF` inside a dense calculation loop causes millions of individual network handshakes, crippling performance. Always wrap `@XREF` inside a tight `FIX` scope.

### 2. `@XWRITE` (Push Mechanism)
- **Syntax**: `@XWRITE(SourceMember, RemoteLocationName, [TargetMemberList])`
- **Execution Flow**:
  - The source cube opens a direct write stream into the target cube's memory buffer.
  - If target blocks do not exist, `@XWRITE` will trigger target block creation.

---

## 4. Circular Reference Detection & Recursion Traversal

Essbase uses a Directed Acyclic Graph (DAG) validator during outline compilation. If a circular calculation dependency is introduced:

```
[Account A] = [Account B] * 1.10;
[Account B] = [Account C] + 500;
[Account C] = [Account A] * 0.90;  <── Circular Reference!
```

### Compiler Response:
1. The compiler tracks each traversed member node in a recursion bitmask stack.
2. Upon revisiting an active node, the compiler halts with error:
   ```
   Error: 1200497 Member formula for Account [Account A] contains a circular reference to [Account C].
   ```
3. In dynamic calculations, circular dependencies that bypass static validation (e.g., through dynamic runtime cross-dimensional lookups) trigger an **execution abort** after a maximum stack depth threshold (default: 256 calls), returning `#ERROR` to prevent a stack overflow crash.

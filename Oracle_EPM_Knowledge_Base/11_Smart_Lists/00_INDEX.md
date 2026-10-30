# Smart Lists

> Smart Lists provide text dropdown selections within Essbase cells — transforming numeric IDs into human-readable options like "Full-Time", "Active", or "Approved".

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Smart Lists Complete Guide](01_Smart_Lists_Complete_Guide.md) | Architecture, storage physics, entries, evaluation order, Calc Manager integration |

---

## How Smart Lists Work

```
User selects "Full-Time" in form → Planning converts to ID 1
Essbase stores 1.00000000 (8-byte double) in .PAG block
On retrieval: Planning reads 1.0 → renders "Full-Time" in dropdown
```

Smart Lists are a **Planning layer feature** — Essbase only stores numbers.

---

**Provenance:** Merged from ChatGPT `Smart_Lists/`, Claude Smart List content, Gemini equivalents.

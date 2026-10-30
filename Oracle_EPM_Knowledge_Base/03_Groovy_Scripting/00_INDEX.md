# Groovy Scripting for EPM

> Groovy business rules extend Calc Manager beyond traditional calc scripts — enabling REST API calls, conditional logic, data grid manipulation, and integration with external systems.

---

## Reading Order

| # | File | What You'll Learn |
|---|------|-------------------|
| 1 | [Groovy Overview](01_Groovy_Overview.md) | Groovy vs calc scripts, key APIs (DataGridBuilder, throwVetoException, micro-FIX), execution context |

---

## Why Groovy?

| Feature | Calc Scripts | Groovy Rules |
|:---|:---:|:---:|
| Basic calculations | ✅ | ✅ |
| Conditional logic | Limited (IF/ENDIF) | Full programming (if/else, loops, try/catch) |
| REST API calls | ❌ | ✅ |
| Data grid manipulation | ❌ | ✅ (DataGridBuilder) |
| Email notifications | ❌ | ✅ |
| Cross-cube data movement | @XREF/@XWRITE (slow) | executeDataMap (fast) |
| Error handling | Limited | Full try/catch/finally |

---

**Provenance:** Merged from ChatGPT `Calc Manager/06_Groovy_Business_Rules/`, Claude `09_Groovy/`, Gemini equivalents.

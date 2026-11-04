# @SIBLINGS

## Overview

`@SIBLINGS` is a **member relationship function** in Oracle EPM Cloud (PBCS/EPBCS) Calc Manager that returns all **sibling members** — members that share the same parent — of a specified member. The returned set excludes the specified member itself.

### Why Does This Function Exist—

Sibling-level calculations are common in financial planning:
- Calculating a department's share of the total across peer departments
- Comparing an entity's performance to its peer group
- Building allocation bases across all members at the same level
- Finding peer averages for benchmarking

### When to Use It

- In allocation formulas as the denominator base (sum of all siblings)
- For peer comparison and benchmarking calculations
- When building competitive analysis within a hierarchy level
- To calculate a member's rank or percentile among peers
- When distributing amounts across peer members

---

## Category

**Member / Relationship / Navigation**

---

## Syntax

```essbase
@SIBLINGS(mbrName)
```

### Formal Syntax

```
@SIBLINGS(memberNameOrFunction)
```

Where:
- `memberNameOrFunction` — The member whose siblings to return. The member itself is NOT included in the result.

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mbrName` | Member name or function | ✅ Yes | The member whose siblings to find. Can be a literal name, `@CURRMBR`, or another member function. Returns all members with the same parent, excluding the specified member. If the member has no siblings (only child), returns an empty set. |

---

## Return Value

**Return Type**: Member set (all siblings excluding the specified member)

---

## How It Works (Behind the Scenes)

1. **Parent Lookup**: @SIBLINGS first finds the parent of the specified member, then returns all of that parent's children EXCEPT the specified member.

2. **Exclusion**: The specified member is always excluded. If you need all children including the current member, use `@CHILDREN(@PARENT(mbrName))`.

3. **Order**: Siblings are returned in outline order (the order they appear in the dimension hierarchy).

4. **Only Children**: If a member is an only child (no siblings), @SIBLINGS returns an empty set.

5. **Root Member**: If called on the root member, behavior depends on whether the root has siblings in a multi-root dimension structure.

---

## Syntax Variants & Scenarios

### Variant 1: Named Member

```essbase
@SIBLINGS("Entity_NA")
```
Returns all siblings of Entity_NA (e.g., Entity_EU, Entity_APAC).

### Variant 2: Dynamic Current Member

```essbase
@SIBLINGS(@CURRMBR("Entity"))
```
Returns siblings of the current entity in the calculation loop.

### Variant 3: In @SUM for Allocation

```essbase
@SUM(Revenue, @SIBLINGS(@CURRMBR("Entity")))
```
Total revenue across all sibling entities (excluding current).

### Variant 4: Combined with @CURRMBR for Total

```essbase
Revenue / @SUM(Revenue, @SIBLINGS(@CURRMBR("Entity")), @CURRMBR("Entity"))
```
Current entity's revenue as a share of all peers (including self).

---

## Practical Examples

### Example 1: Revenue Share Among Peers

**Scenario**: Calculate each entity's revenue share among its peer group.

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vTotalPeers = @SUM(Revenue, @SIBLINGS(@CURRMBR("Entity"))) + Revenue;
    
    IF(vTotalPeers > 0)
        "Peer_Share" = Revenue / vTotalPeers * 100;
    ELSE
        "Peer_Share" = #MISSING;
    ENDIF
ENDFIX
```

---

### Example 2: Cost Allocation Across Peers

```essbase
FIX("FY25", "Working", @CHILDREN("Americas"))
    VAR vPeerBase = @SUM("Headcount", @SIBLINGS(@CURRMBR("Entity"))) + "Headcount";
    
    IF(vPeerBase > 0)
        "Shared_Cost" = "Regional_Overhead" -> @PARENT(@CURRMBR("Entity")) *
            ("Headcount" / vPeerBase);
    ENDIF
ENDFIX
```

---

### Example 3: Peer Average Comparison

```essbase
FIX("FY25", "Working", @DESCENDANTS("Total Entity"))
    VAR vSibCount = @NUMSIBLINGS(@CURRMBR("Entity"));
    VAR vSibTotal = @SUM(Revenue, @SIBLINGS(@CURRMBR("Entity")));
    
    IF(vSibCount > 0)
        "Peer_Average" = vSibTotal / vSibCount;
        "Vs_Peer_Avg" = Revenue - "Peer_Average";
    ENDIF
ENDFIX
```

---

## Common Mistakes & Gotchas

| Mistake | Explanation | Fix |
|---------|-------------|-----|
| Forgetting self is excluded | @SIBLINGS excludes the member itself | For full peer group: add `@CURRMBR` to the sum |
| Empty set for only child | If a member has no siblings, @SUM returns #MISSING | Check sibling count first |
| @SIBLINGS vs. @CHILDREN confusion | @SIBLINGS = same level peers; @CHILDREN = one level down | Use @SIBLINGS for peer analysis; @CHILDREN for hierarchy |

---

## Related Functions

| Function | Relationship |
|----------|-------------|
| [`@RSIBLINGS`](./@RSIBLINGS.md) | Right (following) siblings only |
| [`@LSIBLINGS`](./@LSIBLINGS.md) | Left (preceding) siblings only |
| [`@PREVSIBLING`](./@PREVSIBLING.md) | Previous sibling |
| [`@NEXTSIBLING`](./@NEXTSIBLING.md) | Next sibling |
| [`@PARENT`](./@PARENT.md) | Parent of the member |
| [`@CHILDREN`](./@CHILDREN.md) | Children — opposite direction |

---

## Official Oracle Reference

- [Oracle EPM Cloud Calculation Functions — @SIBLINGS](https://docs.oracle.com/en/cloud/saas/planning-budgeting-cloud/pfusc/siblings.html)

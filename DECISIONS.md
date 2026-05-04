# DECISIONS.md

## 5. How did you structure the class internally — one big method, strategy pattern, or something else? Why?

I structured the class as a small rule-engine style class.

The public method `CALCULATE_GAPS` controls the workflow, while each rule is implemented in its own private method:

- `EVALUATE_DEACTIVATED`
- `EVALUATE_EXTRA_CUSTOM`
- `EVALUATE_CUSTOM_CODE_RISK`

I avoided one large method because the rule logic would become harder to test and extend. I did not fully implement a separate strategy class for each rule because the current scope is small and the task requires a compact pure ABAP implementation.

This structure keeps the engine simple but still separates each rule clearly.

## 6. What happens when two rules produce the same score for different scope items? How does your ordering behave? Is it stable?

The output is sorted by severity first, then score descending.

If two gaps have the same severity and same score, the implementation sorts by `scope_item` ascending and then by `gap_type` ascending.

That makes the output deterministic. The same input always produces the same output order.

## 7. How would you extend this to handle a new rule, e.g. DEPRECATED_SCOPE_ITEM, without modifying existing methods? Show the extension point.

The current extension point is the rule evaluation section inside `CALCULATE_GAPS`.

Today it calls:

```abap
evaluate_deactivated( ... ).
evaluate_extra_custom( ... ).
evaluate_custom_code_risk( ... ).
```

## 8. If the actual input had 500,000 rows, where's the bottleneck and how would you fix it — still in pure ABAP, no DB?

The main bottleneck would be memory usage and repeated table processing.

If the engine loops over 500,000 actual rows and repeatedly searches the baseline table using a standard table, performance can degrade quickly because each lookup may become a linear search. Another bottleneck is the final sorting of all generated gaps, especially if each actual row can create multiple gaps.

To fix this while staying pure ABAP and not using the database, I would:

1. Convert the baseline input into a hashed table keyed by `scope_item`, so each lookup is close to O(1) instead of repeatedly scanning the baseline table.

2. Keep the actual input as a streaming/chunked input if possible. For example, process 10,000 or 50,000 rows at a time instead of holding unnecessary intermediate tables.

3. Avoid creating long reason strings during the main evaluation loop. I would store a compact reason code and only expand it into a full message when the output is displayed or exported.

4. Minimize sorting work. Since output ordering is by severity and score, I would either sort only the final gap list once, or collect gaps into separate severity buckets first, then sort each bucket by score.

5. Avoid nested loops between actual and baseline data. The design should be one pass over actual rows, with hashed lookups against baseline.

So the biggest technical bottleneck is not the rule calculation itself; it is table lookup, memory growth, and final sorting of a potentially very large gap result set.
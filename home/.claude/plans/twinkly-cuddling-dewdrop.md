# Multiselect Status Filter with Ghost Ancestor Rendering

## Summary

Replace the single-select `lightning-combobox` status filter with a multiselect checkbox dropdown. Default-selected statuses come from the `Workflow__c` JSON (new `visibleByDefault` field). Parents whose status is filtered out but who have visible descendants are shown grayed out ("ghost ancestors").

## Files to Modify

| File | Change |
|------|--------|
| `StatusWrapper.cls` | Add `visibleByDefault` boolean property |
| `PicklistOption.cls` | Add `visibleByDefault` boolean + 3-param constructor |
| `ProjectDataWrapper.cls` | Rewrite `collectStatusOptions` to pass `visibleByDefault` per status; remove "All Statuses" entry |
| `baseComponent.js` | Add `visibleByDefault` to `defaultWorkflow`; remove "All Statuses" from `defaultStatusOptions` |
| `workItemCardContainer.js` | Replace single `statusFilter` with `selectedStatuses` array; new `annotateAndFilter` tree algorithm |
| `workItemCardContainer.html` | Replace `lightning-combobox` with new `c-status-filter-multiselect` |
| `workItemCardContainer.css` | Widen filter area |
| `workItemCard.js` | Add `@api isDimmed` property; include in `cardContainerClass` |
| `workItemCard.html` | Pass `is-dimmed={child.isDimmed}` in recursive children |
| `workItemCard.css` | Add `.work-item-dimmed` styles (opacity + subtle hatching overlay) |
| `workItemCardContainer.test.js` | Update test that checks for `lightning-combobox` → `c-status-filter-multiselect` |

## Files to Create

| File | Purpose |
|------|---------|
| `statusFilterMultiselect/statusFilterMultiselect.js` | Checkbox dropdown component (follows `workItemStatusDropdown` pattern) |
| `statusFilterMultiselect/statusFilterMultiselect.html` | Trigger button + positioned dropdown with checkboxes |
| `statusFilterMultiselect/statusFilterMultiselect.css` | Dropdown positioning, checkbox styling |
| `statusFilterMultiselect/statusFilterMultiselect.js-meta.xml` | LWC metadata |
| `statusFilterMultiselect/__tests__/statusFilterMultiselect.test.js` | Unit tests for the new component |

## Implementation Steps

### 1. Apex: Extend StatusWrapper + PicklistOption

**StatusWrapper.cls** — Add optional `visibleByDefault` field:
```apex
@AuraEnabled
public Boolean visibleByDefault { get; set; }
```
`JSON.deserializeStrict` leaves it `null` for old workflow JSON → client treats null as `true`.

**PicklistOption.cls** — Add `visibleByDefault` field + 3-param constructor:
```apex
@AuraEnabled
public Boolean visibleByDefault { get; set; }

public PicklistOption(String value, String label, Boolean visibleByDefault) {
    this.value = value;
    this.label = label;
    this.visibleByDefault = visibleByDefault;
}
```

### 2. Apex: Rewrite ProjectDataWrapper status collection

Replace `collectStatusOptions` returning `Set<String>` with `collectStatusOptionsWithDefaults` returning `Map<String, Boolean>`. Union strategy: if ANY template marks a status as visible (or omits the field), it's visible by default.

Remove the hard-coded `new PicklistOption('All Statuses', '')` entry — the multiselect handles "all/none" via UI buttons.

### 3. JS: Update baseComponent defaults

Add `visibleByDefault` to each entry in `defaultWorkflow`. Set `false` for Complete and Cancelled. Remove the `{ label: 'All Statuses', value: '' }` entry from `defaultStatusOptions`.

### 4. LWC: Create statusFilterMultiselect component

**API:**
- `@api options` — `[{ label, value, visibleByDefault }]`
- `@api disabled`
- Fires `change` event with `{ selectedValues: string[] }`

**Behavior:**
- On init: pre-select options where `visibleByDefault !== false`
- Trigger button shows summary text: "All Statuses" / "3 of 5 statuses" / "None"
- Dropdown has "All | None" quick-toggle links + checkboxes
- Click-outside closes dropdown (same pattern as `workItemStatusDropdown`)

### 5. JS: Rewrite workItemCardContainer filter logic

Replace `statusFilter = ''` with `@track selectedStatuses = []`.

**On data load** (`handleWorkItemsChange`): initialize `selectedStatuses` from options where `visibleByDefault !== false`, unless localStorage has a saved selection for this project.

**New `applyFilter`:** If all selected → pass through unchanged. If none → empty list. Otherwise → call `annotateAndFilter`.

**New `annotateAndFilter(items, selectedSet)`:** Depth-first recursive tree walk:
- If item status ∈ selectedSet → `directMatch` (isDimmed=false), include with filtered children
- Else if any descendant is visible → `ghostAncestor` (isDimmed=true), include with filtered children
- Else → hidden, exclude entirely

**Persist** `selectedStatuses` to localStorage (same pattern as viewMode).

### 6. LWC: Pass isDimmed through workItemCard

**workItemCard.js:** Add `@api isDimmed = false`. Append `work-item-dimmed` class to `cardContainerClass` when true.

**workItemCard.html:** In recursive children template, pass `is-dimmed={child.isDimmed}`.

### 7. CSS: Dimmed styling

```css
.work-item-dimmed {
    opacity: 0.45;
}
.work-item-dimmed:hover {
    opacity: 0.7;
}
```
Dimmed items remain fully interactive (clickable, expandable, editable).

### 8. Tests

- Update `workItemCardContainer.test.js`: change `lightning-combobox` assertions to `c-status-filter-multiselect`
- Create `statusFilterMultiselect.test.js`: initialization, default selection from `visibleByDefault`, checkbox toggling, All/None buttons, trigger label text, click-outside close

## Key Design Decisions

1. **No Apex changes to dataManager.js** — it already passes `statusOptions` through as-is; the enriched objects flow automatically.
2. **Ghost ancestors remain interactive** — filtering is a visibility concern, not an access control. Users may need to click through a ghost parent to reach its visible children.
3. **Union strategy for multi-template projects** — If Template A says `Complete.visibleByDefault=false` and Template B says `Complete.visibleByDefault=true`, the status is visible by default.
4. **localStorage persistence** — User's custom filter selection persists per-project, matching the existing viewMode persistence pattern.

## Verification

1. `npm test` — All existing + new tests pass
2. `npm run lint` — No lint errors
3. Manual: Deploy to scratch org, open project page → verify multiselect shows with correct defaults from workflow
4. Manual: Filter out a status → verify parent chain shows dimmed when children remain visible
5. Manual: Filter out a status → verify items with ALL descendants in that status are fully hidden
6. Manual: Refresh page → verify localStorage restores filter selection

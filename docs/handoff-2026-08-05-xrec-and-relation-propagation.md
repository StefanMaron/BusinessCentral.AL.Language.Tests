# Handoff — `xRec` in table triggers, and rename propagation through `TableRelation`

**Date:** 2026-08-05
**Status:** not started — design settled, nothing written yet
**Run this from a session rooted at THIS repo.** It was scoped out of a Gardens America session
whose AL gate hooks block every `.al` write machine-wide, including in unrelated repos.

## Why this exists

An AL review rule was drafted in another project asserting that a table's `OnRename` trigger can use
`xRec` to recover the **old** primary key, and fix up "soft" references that carry no
`TableRelation`. Stefan challenged it from experience: `xRec` is reliable when the change is driven
by a **user through a page**, and unreliable when driven by **code**.

If he is right, the drafted rule is not merely imprecise — it is actively harmful. A fix-up loop
keyed on `xRec` under a code-driven rename would compute the *new* key, match zero rows, update
nothing, and report success. A correct-looking no-op.

**That rule is held uncommitted pending the result of this work.** The point of these tests is to
settle the contract with evidence rather than memory.

## What this repo already says

`tests/al-language/record/TestXRecContracts.al` states the contract in its header comment:

> - In OnModify: Rec = new values, xRec = the record BEFORE the modification
> - BUT: this only works correctly from PAGE triggers, NOT from code!
> - When Rec.Modify() is called from CODE, xRec has the SAME values as Rec (new values)
> - Since xRec cannot be accessed from procedural code, we test the OBSERVABLE consequences

So the claim is **written down but never executed**. Every test in that codeunit asserts on `Rec`
(`OnRename_Rec_HasNewKey`, `Rec_AfterRename_PositionedAtNewKey`,
`Rec_AfterRename_OldKeyNotAccessible`) or on observable persistence. **No test reads `xRec`.**

The `ALT Trigger Log` fixture already has an `OldValue` field (table 60003, field 4) that is
**currently written by nothing and read by no test** — verified. It is the natural place to capture
`xRec` without disturbing anything.

## The two questions

### Q1 — Does `xRec` hold the previous record inside a table trigger, and does the answer depend on what drove the write?

Specifically for `OnRename` (the case the rule depends on) and `OnModify` (where the repo's stated
contract lives), under both a **code-driven** write (`Rec.Rename()` / `Rec.Modify()`) and a
**page-driven** write (via `TestPage`).

### Q2 — Does `ValidateTableRelation = false` suppress automatic rename propagation?

Zero coverage in this repo today (`grep -rl ValidateTableRelation tests/` → nothing). It matters
because Microsoft documents that renaming a record updates it "in all other locations" via
`TableRelation`, and the open question is whether disabling *input validation* on a field also
disables *rename propagation* for it. Nobody should assert either way until it is tested.

## Test design — three outcomes, not two

This is the part that must not be lost. A naive assertion ("is `xRec` the old key?") collapses two
distinct failures into one bucket. There are **three** possible states:

| If `xRec` is… | Logged `OldValue` |
|---|---|
| the previous record | the old value |
| a mirror of `Rec` | the new value |
| never populated / meaningless | the **type default** (`0` for Integer, `''` for Text) |

**Therefore choose values so that old, new, and type-default are pairwise distinct:**

- Rename: `7 → 99`. Never use `0` as either key, or "not populated" is indistinguishable from "old".
- Modify: `'OLD' → 'NEW'`. Never use `''`.

Assert the logged value against all three named outcomes so the result identifies *which* happened.
"`xRec` was ignored altogether" must be a reportable result, not a silent failure.

## Work items

### 1. Fixture — capture `xRec` in `ALT Triggered` (table 60002)

`tests/al-language/_fixtures/tables/ALTTriggered.al`. Non-breaking: no existing test reads
`OldValue`, and the two `OnModify` tests in `TestXRecContracts.al` use `ALT Universal`, not this
table.

```al
trigger OnModify()
begin
    TrigLog."TriggerName" := 'OnModify';
    TrigLog."SourceEntryNo" := Rec."Entry No.";
    TrigLog."OldValue" := xRec."Watched Field";     // <- new
    TrigLog."NewValue" := Rec."Watched Field";      // <- new
    TrigLog."LoggedAt" := CurrentDateTime();
    TrigLog.Insert();
end;

trigger OnRename()
begin
    TrigLog."TriggerName" := 'OnRename';
    TrigLog."SourceEntryNo" := Rec."Entry No.";
    TrigLog."OldValue" := Format(xRec."Entry No.");  // <- new, the load-bearing one
    TrigLog."NewValue" := Format(Rec."Entry No.");   // <- new
    TrigLog."LoggedAt" := CurrentDateTime();
    TrigLog.Insert();
end;
```

### 2. Fixture — card page on `ALT Triggered`, for the page-driven half

There is no page fixture over `ALT Triggered` today; `ALT Card Page` (60017) is over `ALT Universal`.
A new card page is required to drive `OnModify` (and ideally `OnRename`, by editing the primary key
field) through the UI path via `TestPage`.

`TestPage` is already used in this repo — see `tests/al-language/handlers/TestPageAdvanced.al` and
`TestPageExtended.al` for the established pattern.

### 3. Fixture — parent/child tables for Q2

Three fields on the child, so one rename answers all three cases at once:

```al
table 60027 "ALT Relation Child"
{
    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; "Validated Ref"; Code[20])       // normal relation — expect propagation
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Relation Parent"."Code";
        }
        field(3; "Unvalidated Ref"; Code[20])     // THE OPEN QUESTION
        {
            DataClassification = SystemMetadata;
            TableRelation = "ALT Relation Parent"."Code";
            ValidateTableRelation = false;
        }
        field(4; "Soft Ref"; Code[20]) { DataClassification = SystemMetadata; }  // no relation — expect NO propagation
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
```

Field 4 is the control: it proves the test can detect a *non*-propagating field, so a "propagated"
result on field 3 is meaningful rather than an artifact.

### 4. Object IDs — verified free as of 2026-08-05

| Object | ID |
|---|---|
| `ALT Relation Parent` (table) | **60026** |
| `ALT Relation Child` (table) | **60027** |
| Card page over `ALT Triggered` | **60028** |
| Test codeunit — xRec driver contracts | **60205** |
| Test codeunit — rename propagation | **60206** |

`60018` is **taken** (do not reuse — it was the obvious next page ID). Highest existing codeunit is
`61004`; the `60183–60204` block is contiguous test codeunits.

### 5. Register the new tables

Both new tables must be added to:

- `tests/al-language/_fixtures/ALTFixtureCleanup.al` (codeunit 60019) — `DeleteAll(false)` per table,
  since `Initialize()` must clear every table the codeunit touches.
- `tests/al-language/_fixtures/ALTPermissionSet.permissionset.al` (60022) — `tabledata … = RIMD`.

## Repo conventions to follow

From `CONTRIBUTING.md` — these are enforced by review, and one of them bites here:

- **`Initialize()` first** in every `[Test]`, and it must clear every table used.
- **No per-test fixture definitions.** All schema objects go in `_fixtures/`. This is why items 1–3
  are fixture changes rather than inline declarations.
- **One claim per codeunit**; file named `Test<Type><Aspect>.al` in the matching area folder
  (`tests/al-language/record/`).
- **Procedure naming:** `<Type>_<Method>_<Scenario>_<Outcome>` — the full claim readable from the
  name alone. E.g. `Record_Rename_FromCode_xRecHoldsNewKey`.
- **Doc-link comment** at the top of the file, linking the relevant BC docs page.
- **The two-rule contract:** the test must fail if the behavior is broken, and must assert a specific
  non-default value. The three-outcome design above exists to satisfy exactly this.
- No BC-version guard needed unless something is 28-only.

## Then

Open a PR. CI (`.github/workflows/ci.yml`) runs on `pull_request` to `main`, across the BC version
matrix. Check the run roughly ten minutes later.

**Report back:** for each of `OnRename` / `OnModify`, under each of code-driven / page-driven, which
of the three outcomes occurred — and for Q2, whether `Unvalidated Ref` followed the parent rename
while `Soft Ref` did not.

Those results decide the wording of the external review rule that is currently held uncommitted, and
they should also correct or confirm the header comment in `TestXRecContracts.al`, which today asserts
the page-vs-code distinction without ever having proven it.

## Results (2026-08-05, PR #17)

| Trigger | Driver | Outcome |
|---|---|---|
| `OnModify` | code (`Rec.Modify()`) | xRec MIRRORS Rec (new values) — no before-image |
| `OnModify` | page (`TestPage`) | xRec correctly holds the PREVIOUS value |
| `OnRename` | code (`Rec.Rename()`) | xRec correctly holds the PREVIOUS key |
| `OnRename` | page | xRec correctly holds the PREVIOUS key — confirmed directly against real Microsoft SaaS BC (not just the local/CI bc-linux environment), both for a code-driven and a real interactive Web Client edit-and-tab-out. **`TestPage` itself cannot be used to write an automated regression test for this**: `TestPage."<pk field>".SetValue()`/`.Value:=` silently no-ops on a primary-key-bound field on both bc-linux and stock Microsoft SaaS BC — a gap in the `TestPage` object, not in BC's actual Rename behavior. See `StefanMaron/MsDyn365Bc.On.Linux#17` (closed as "works as intended on Microsoft's platform, not a bc-linux bug").

**Q2 — `ValidateTableRelation = false`**: confirmed it suppresses rename PROPAGATION, not just input validation. `Validated Ref` follows a parent rename; `Unvalidated Ref` does not; `Soft Ref` (the no-`TableRelation` control) does not either, proving the test can detect non-propagation.

**Bottom line for the external review rule**: the rule's underlying premise does NOT hold in general —
`OnModify` demonstrably differs between code-driven and page-driven writes, so "xRec is unreliable
under code" is a real phenomenon for `Modify`. But it does **not** apply to `OnRename` specifically:
`xRec` is reliable for Rename regardless of what drove the write. A fix-up loop keyed on `xRec` inside
`OnRename` is safe under both code-driven and page-driven renames. The rule, if scoped specifically to
`OnRename` (not `OnModify` or triggers in general), can be committed as correct.

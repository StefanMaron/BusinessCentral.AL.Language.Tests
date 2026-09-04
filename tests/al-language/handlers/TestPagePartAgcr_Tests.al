// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-onaftergetcurrrecord-trigger
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Test Page Part Agcr Row (60812), Test Page Part Agcr Part (60813),
//                Test Page Part Agcr Host (60814), Test Page Part Agcr Trace (60811),
//                Assert (60021)
//
// A subpage PART bound via SubPageLink to the host's current row -- the FactBox/summary
// shape -- gets its own row and fires OnOpenPage/OnAfterGetRecord/OnAfterGetCurrRecord the
// same way a top-level page does. What is NOT obvious, and what this file measures rather
// than assumes, is WHEN: whether a TestPage-driven host fires the part's triggers eagerly as
// part of opening (the part is declared in the layout; nothing in the host's own AL ever
// references CurrPage.AgcrPart), or only once something -- the host's own AL, or the test's
// own TestPage-side access -- actually touches the part. OBSERVATION probes first
// (Error('OBS order=%1', ...) dumping the accumulated trace), converted to real assertions
// once the corpus CI's real-BC answer is in.

codeunit 60815 "Test Page Part Agcr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Part Agcr Row";
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Row.DeleteAll();
        Trace.Reset();
    end;

    local procedure SeedRow(No: Code[20]; Name: Text[50])
    var
        Row: Record "Test Page Part Agcr Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Insert();
    end;

    // OBS 1: does the part's OnAfterGetCurrRecord fire as part of the host simply opening --
    // nothing here ever references CurrPage.AgcrPart or Host.AgcrPart -- or does it stay
    // unfired until something touches the part?
    [Test]
    procedure Z_OBS_NoTouch_WhatFiresOnOpenViewAlone()
    var
        Host: TestPage "Test Page Part Agcr Host";
        Trace: Codeunit "Test Page Part Agcr Trace";
    begin
        Initialize();
        SeedRow('X', 'Alpha');

        Host.OpenView();
        Host.Close();

        Error('OBS order=%1', Trace.GetTrace());
    end;

    // OBS 2: the same, but the test reads a control on the part (Host.AgcrPart."No.") after
    // OpenView -- does that first TestPage-side touch make the part's triggers run (and if
    // so, in what order relative to the host's own OnOpenPage/OnAfterGetCurrRecord, which
    // already ran during OpenView)?
    [Test]
    procedure Z_OBS_WithTouch_WhatFiresWhenTestTouchesThePart()
    var
        Host: TestPage "Test Page Part Agcr Host";
        Trace: Codeunit "Test Page Part Agcr Trace";
        PartNo: Code[20];
    begin
        Initialize();
        SeedRow('X', 'Alpha');

        Host.OpenView();
        PartNo := Host.AgcrPart."No.".Value();
        Host.Close();

        Error('OBS order=%1 partNo=%2', Trace.GetTrace(), PartNo);
    end;

    // OBS 3: does navigating the host to a SECOND row (GoToRecord) refresh the part's row
    // too -- and does its OnAfterGetCurrRecord fire again for the new row -- given the first
    // probe already established (or not) whether touching the part matters?
    [Test]
    procedure Z_OBS_GoToRecord_WhatFiresOnSecondRow()
    var
        Row2: Record "Test Page Part Agcr Row";
        Host: TestPage "Test Page Part Agcr Host";
        Trace: Codeunit "Test Page Part Agcr Trace";
        PartNo: Code[20];
    begin
        Initialize();
        SeedRow('X', 'Alpha');
        SeedRow('Y', 'Bravo');
        Row2.Get('Y');

        Host.OpenView();
        PartNo := Host.AgcrPart."No.".Value(); // establish the part once, on row X
        Trace.Reset(); // isolate what GoToRecord alone does
        Host.GoToRecord(Row2);
        PartNo := Host.AgcrPart."No.".Value();
        Host.Close();

        Error('OBS order=%1 partNo=%2', Trace.GetTrace(), PartNo);
    end;
}

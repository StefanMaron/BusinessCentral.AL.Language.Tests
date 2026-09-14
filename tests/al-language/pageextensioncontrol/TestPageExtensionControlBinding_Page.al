// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-pages
// Scope: in-scope
// Fixtures used: Assert (60021), and the table/page/pageextension below
//
// The subject is a control DECLARED BY A PAGEEXTENSION, read through a TestPage. The existing
// pageextensiontrigger suite covers a pageextension's page TRIGGERS on a TestPage; its
// pageextension adds no layout control at all, so nothing upstream measures this.
//
// TWO CONTROLS ON PURPOSE, and the pair is the whole design. AL Runner issue
// StefanMaron/BusinessCentral.AL.Runner#4145 reports NavTestFieldNotFoundException for an
// extension control bound to an extension GLOBAL, and names two candidate causes it could not
// separate: the page metadata not carrying the extension's control at all, or the extension's
// InitializeComponent (where source expressions are registered) being skipped.
//
// A control bound to Rec discriminates them. If BOTH controls are found, the metadata carries
// extension controls and the global-bound one is a source-expression problem. If NEITHER is
// found, it is the metadata. One control alone cannot tell those apart -- which is exactly why
// the issue asked for this shape rather than a single reproducer.

table 60987 "PXC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Rec Text"; Text[20]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

page 60991 "PXC Card"
{
    PageType = Card;
    SourceTable = "PXC Row";
    ApplicationArea = All;
    Caption = 'PXC Card';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
        }
    }
}

pageextension 60997 "PXC Card Ext" extends "PXC Card"
{
    layout
    {
        addlast(Content)
        {
            // Bound to a variable the PAGEEXTENSION declares.
            field(ExtGlobalField; ExtGlobal) { ApplicationArea = All; }

            // Bound to a field of the page's own SourceTable, from the same pageextension.
            // Same declaration site, different binding -- that is what separates the two causes.
            field(ExtRecField; Rec."Rec Text") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        ExtGlobal := 'EXTGLOBAL';
    end;

    var
        ExtGlobal: Text[20];
}

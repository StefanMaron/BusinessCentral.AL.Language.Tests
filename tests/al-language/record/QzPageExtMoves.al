// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "Test Page Control Fld PageExt" (TestPageControlFieldPageExtension.al): table 87692, page 87693, pageextension 87694.
// Facts: movefirst, movelast, moveafter and movebefore in a page extension (inside one group and from one group into another): whether the
//   page opens, whether the moved controls read and write their fields through a TestPage, and the rows "Page Control Field" reports for the page.
// Base layout: General = Id, A, B; Details = C, D, E. The extension: movefirst(General; B), movelast(General; C), moveafter(D; A), movebefore(D; E).

table 87692 "LT QZ Move Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Text[20]) { }
        field(3; B; Text[20]) { }
        field(4; C; Text[20]) { }
        field(5; D; Text[20]) { }
        field(6; E; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 87693 "LT QZ Move Card"
{
    PageType = Card;
    SourceTable = "LT QZ Move Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(ACtl; Rec.A) { ApplicationArea = All; }
                field(BCtl; Rec.B) { ApplicationArea = All; }
            }
            group(Details)
            {
                field(CCtl; Rec.C) { ApplicationArea = All; }
                field(DCtl; Rec.D) { ApplicationArea = All; }
                field(ECtl; Rec.E) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 87694 "LT QZ Move Ext" extends "LT QZ Move Card"
{
    layout
    {
        movefirst(General; BCtl)
        movelast(General; CCtl)
        moveafter(DCtl; ACtl)
        movebefore(DCtl; ECtl)
    }
}

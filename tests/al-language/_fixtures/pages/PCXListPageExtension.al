// Fixtures for record/TestPageControlFieldPageExtension.al — a page whose control set is
// only complete once a PAGEEXTENSION has been merged into it.
//
// Deliberately self-contained rather than an extension of "ALT Control Tree Page" (60427):
// a pageextension over a shared fixture page changes what every other test reading that page
// observes, and "Page Control Field" is exactly the table that would notice.
//
// The base page declares ONE field control and the extension adds ONE, so the merged count
// is a meaningful assertion — with more controls on either side, a provider that dropped one
// could still produce a plausible-looking total.
table 60520 "PCX Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "PCX No."; Integer)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "PCX No.")
        {
            Clustered = true;
        }
    }
}

// The added control is bound to a field this extension contributes, not to a base-table
// field: answering the control correctly therefore requires resolving its binding against
// the EXTENDED table.
tableextension 60522 "PCX Row Ext" extends "PCX Row"
{
    fields
    {
        field(50; "PCX Note"; Text[30])
        {
            DataClassification = CustomerContent;
        }
    }
}

page 60521 "PCX List"
{
    PageType = List;
    SourceTable = "PCX Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'PCX List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("PCX No."; Rec."PCX No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

pageextension 60523 "PCX List Ext" extends "PCX List"
{
    layout
    {
        addlast(Content)
        {
            field("PCX Note"; Rec."PCX Note")
            {
                ApplicationArea = All;
            }
        }
    }
}

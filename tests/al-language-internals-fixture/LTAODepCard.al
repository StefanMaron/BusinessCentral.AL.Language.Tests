// Fixture for corpus issue 641 item 2 (writer AO): a card with an invisible control, declared in this DEPENDENCY app.
// The test that sets the invisible control lives in tests/al-language/pages/lt-ao-testpage/AoTests.al.
table 61050 "LT AO Dep Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Hidden; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 61051 "LT AO Dep Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AO Dep Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Hidden; Rec.Hidden) { ApplicationArea = All; Visible = false; }
        }
    }
}

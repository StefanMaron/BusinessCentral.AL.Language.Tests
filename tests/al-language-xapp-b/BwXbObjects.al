// Objects of cross-app fixture B (writer BW). Tests: tests/al-language/tableextension/lt-bw-cross-app/.
//   61110: extends cross-app fixture A's table 61101 with an Option field (corpus #668 item 102) and a Text field (#664 item 14), and declares
//          procedures whose names equal procedures of that table (#668 item 87, the cross-app half).
//   61111 / 61112: add only a Blob field and only a Text field to A's rename tables (#668 item 96).
//   61110 "LT BW XB Master Card": a page with a protected variable whose type is a table of the AL Internals Test Fixture app; cross-app
//          fixture C extends the page without depending on the fixture app (#668 item 95).

tableextension 61110 "LT BW XB Base Ext" extends "LT BW XA Base"
{
    fields
    {
        field(61110; "BW XB Kind"; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = First,Second,Third;
        }
        field(61111; "BW XB Note"; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }

    procedure BwOverload(Value: Text): Text
    begin
        exit('extension of app B, Text ' + Value);
    end;
}

tableextension 61111 "LT BW XB Rename Blob Ext" extends "LT BW XA Rename Blob"
{
    fields
    {
        field(61112; "BW XB Blob"; Blob)
        {
            DataClassification = SystemMetadata;
        }
    }
}

tableextension 61112 "LT BW XB Rename Text Ext" extends "LT BW XA Rename Text"
{
    fields
    {
        field(61113; "BW XB Text"; Text[50])
        {
            DataClassification = SystemMetadata;
        }
    }
}

table 61110 "LT BW XB Master"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 61110 "LT BW XB Master Card"
{
    PageType = Card;
    SourceTable = "LT BW XB Master";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
            field(BlahFilterText; BlahFilterText) { Caption = 'Blah Filter'; }
        }
    }

    protected var
        TheBlah: Record "ALT XApp Mut Probe";

    var
        BlahFilterText: Text;

    trigger OnOpenPage()
    begin
        TheBlah.SetRange("No.", 'BW-BLAH');
        BlahFilterText := TheBlah.GetFilters();
    end;
}

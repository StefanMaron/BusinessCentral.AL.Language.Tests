// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
page 60841 "TRT Card"
{
    PageType = Card;
    SourceTable = "TRT Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // A brand-new row belongs to the tenant; the enum's own default (Extension) is what a
        // blank record would carry, and is wrong.
        Rec.Validate(Kind, Rec.Kind::Tenant);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // The page's last word before the row is persisted.
        Rec.Note := 'stamped-by-oninsert';
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Echo: Record "TRT Echo";
    begin
        Echo.Bump('CURR');
    end;

}

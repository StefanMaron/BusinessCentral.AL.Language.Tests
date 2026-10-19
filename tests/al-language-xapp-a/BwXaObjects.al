// Objects of cross-app fixture A that other apps extend or use (writer BW). Tests: tests/al-language/tableextension/lt-bw-cross-app/.
//   61101 "LT BW XA Base": cross-app fixture B extends it with an Option field and a Text field and declares procedures whose names
//         equal procedures of this table (corpus #668 items 87 and 102, #664 item 14).
//   61102 / 61103: rename targets; cross-app fixture B adds only a Blob field to 61102 and only a Text field to 61103 (#668 item 96).
//   61104 "LT BW XA Local Publisher": a local integration event (#664 item 144).

table 61101 "LT BW XA Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    procedure BwSame(): Text
    begin
        exit('table of app A');
    end;

    procedure BwOverload(Value: Integer): Text
    begin
        exit('table of app A, Integer ' + Format(Value));
    end;

    procedure BwCaseName(): Text
    begin
        exit('table of app A, BwCaseName');
    end;

    procedure BwCallSameFromA(): Text
    begin
        exit(BwSame());
    end;
}

table 61102 "LT BW XA Rename Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61103 "LT BW XA Rename Text"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 61104 "LT BW XA Local Publisher"
{
    [IntegrationEvent(false, false)]
    local procedure OnBwLocal(var Log: Text)
    begin
    end;

    procedure Raise(): Text
    var
        Log: Text;
    begin
        OnBwLocal(Log);
        exit(Log);
    end;
}

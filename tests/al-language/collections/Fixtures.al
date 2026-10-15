// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: LT ClT Fixtures (74600-74605), self-contained otherwise
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Fixtures for the List/Dictionary probes: an interface with two implementations, an enum with a gap, a table.
// BC versions: 29 (27 and 28 by CI)

interface "LT ClT Shape"
{
    procedure Name(): Text;
}

codeunit 74600 "LT ClT Circle" implements "LT ClT Shape"
{
    var
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure Name(): Text
    begin
        exit('circle' + Tag);
    end;
}

codeunit 74601 "LT ClT Square" implements "LT ClT Shape"
{
    procedure Name(): Text
    begin
        exit('square');
    end;
}

enum 74602 "LT ClT Color"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { }
    value(5; Blue) { Caption = 'Blue Caption'; }
}

table 74603 "LT ClT Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

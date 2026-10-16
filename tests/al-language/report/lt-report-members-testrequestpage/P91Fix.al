// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); this file holds the tables 71591, 71592 and the helper codeunit 71593 (not a test codeunit)

table 71591 "LT P91 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71592 "LT P91 Store"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71593 "LT P91 Helper"
{
    procedure Seed()
    var
        Row: Record "LT P91 Row";
        Store: Record "LT P91 Store";
    begin
        Row.DeleteAll();
        Store.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Grp := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Grp := 1;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Grp := 2;
        Row.Name := 'three';
        Row.Insert();
        Row.Id := 4;
        Row.Grp := 2;
        Row.Name := 'four';
        Row.Insert();
    end;
}

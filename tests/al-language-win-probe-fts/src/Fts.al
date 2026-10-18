table 79950 "WC Fts Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[100]) { OptimizeForTextSearch = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 79951 "WC Fts Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Fts_InsertAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "WC Fts Row";
    begin
        Row.Id := 1;
        Row.Description := 'hello world';
        Row.Insert();
        Row.SetFilter(Description, '@*hello*');
        Observer.Observe('count', Format(Row.Count()));
        Observer.Finish();
    end;
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/createguid-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74184, test codeunit 74185
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 4 (NP Retail blockers): the shape of the Guids that CreateGuid() and the SystemId of an inserted row produce, over 50 calls:
// length with and without braces, upper case hex digits only, the version character (the 15th character of the form without braces) and the variant
// character (the 20th), the number of distinct values, and whether the values come in increasing order. No generated Guid is asserted, only counts.
// BC versions: 27, 28, 29

table 74184 "LT CGF Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74185 "LT CGF CreateGuid Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(Guids: List of [Guid]; Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        G: Guid;
        T: Text;
        Versions: Dictionary of [Text, Integer];
        Variants: Dictionary of [Text, Integer];
        Distinct: List of [Text];
        BadLength: Integer;
        BadBraced: Integer;
        NotUpper: Integer;
        Ascending: Integer;
        Prev: Text;
        V: Text;
        K: Text;
        Summary: Text;
    begin
        foreach G in Guids do begin
            T := Format(G, 0, 4);
            if StrLen(T) <> 36 then
                BadLength += 1;
            if StrLen(Format(G)) <> 38 then
                BadBraced += 1;
            if T <> UpperCase(T) then
                NotUpper += 1;
            V := CopyStr(T, 15, 1);
            if Versions.ContainsKey(V) then
                Versions.Set(V, Versions.Get(V) + 1)
            else
                Versions.Add(V, 1);
            V := UpperCase(CopyStr(T, 20, 1));
            if Variants.ContainsKey(V) then
                Variants.Set(V, Variants.Get(V) + 1)
            else
                Variants.Add(V, 1);
            if not Distinct.Contains(T) then
                Distinct.Add(T);
            if (Prev <> '') and (T > Prev) then
                Ascending += 1;
            Prev := T;
        end;
        Observer.Observe(Prefix + '_count', Format(Guids.Count()));
        Observer.Observe(Prefix + '_bad_length36', Format(BadLength));
        Observer.Observe(Prefix + '_bad_braced38', Format(BadBraced));
        Observer.Observe(Prefix + '_not_upper', Format(NotUpper));
        Observer.Observe(Prefix + '_distinct', Format(Distinct.Count()));
        Summary := '';
        foreach K in Versions.Keys() do
            Summary += K + 'x' + Format(Versions.Get(K)) + ' ';
        Observer.Observe(Prefix + '_version_chars', Summary);
        Summary := '';
        foreach K in Variants.Keys() do
            Summary += K + 'x' + Format(Variants.Get(K)) + ' ';
        Observer.Observe(Prefix + '_variant_chars', Summary);
        Observer.Observe(Prefix + '_ascending_steps_of_49', Format(Ascending));
    end;

    [Test]
    procedure CreateGuid_ShapeOver50Calls()
    var
        Observer: Codeunit "Probe Observer";
        Guids: List of [Guid];
        i: Integer;
    begin
        for i := 1 to 50 do
            Guids.Add(CreateGuid());
        Shape(Guids, Observer, 'create');
        Observer.Finish();
    end;

    [Test]
    procedure SystemId_ShapeOver50InsertedRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CGF Row";
        Guids: List of [Guid];
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 50 do begin
            Row.Id := i;
            Row.Insert();
            Guids.Add(Row.SystemId);
        end;
        Shape(Guids, Observer, 'systemid');
        Observer.Finish();
    end;

    [Test]
    procedure SystemId_AssignedBeforeInsertIsKept()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CGF Row";
        Own: Guid;
        Back: Record "LT CGF Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Observer.Observe('before_insert_null', Format(IsNullGuid(Row.SystemId)));
        Row.Insert();
        Observer.Observe('after_insert_null', Format(IsNullGuid(Row.SystemId)));
        Own := Row.SystemId;
        Back.GetBySystemId(Own);
        Observer.Observe('get_by_systemid_id', Format(Back.Id));
        Row.Id := 2;
        Row.SystemId := CreateGuid();
        Own := Row.SystemId;
        Row.Insert();
        Observer.Observe('kept_assigned', Format(Row.SystemId = Own));
        Observer.Finish();
    end;
}

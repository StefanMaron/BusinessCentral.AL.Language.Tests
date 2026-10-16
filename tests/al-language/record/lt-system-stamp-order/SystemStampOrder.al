// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-systemmodifiedat-field
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71694, test codeunit 71695
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 56 (Handlers): System fields (the stamp is made strictly later than the previous stamp of the session; PnASystemFields.al pins temporary records, propagation and Modify but not the order of stamps of back-to-back writes)
// RISKY: none; only relations are observed (>=, <=), never a clock value. Whether two stamps of rapid writes are EQUAL is host-dependent and is observed as the ordering text only.
// BC versions: 29 (27 and 28 by CI)

table 71694 "LT P159 Stamp Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71695 "LT P159 System Stamp Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Relation(First: DateTime; Second: DateTime): Text
    begin
        if Second > First then
            exit('later');
        if Second = First then
            exit('equal');
        exit('earlier');
    end;

    [Test]
    procedure P159_BackToBackInserts_StampsNeverGoBack()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P159 Stamp Row";
        Previous: DateTime;
        i: Integer;
        NeverEarlier: Boolean;
        Distinct: Integer;
    begin
        Row.DeleteAll();
        NeverEarlier := true;
        for i := 1 to 20 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
            Row.Get(i);
            if (i > 1) and (Row.SystemCreatedAt < Previous) then
                NeverEarlier := false;
            if (i > 1) and (Row.SystemCreatedAt > Previous) then
                Distinct += 1;
            Previous := Row.SystemCreatedAt;
        end;
        Observer.Observe('never-earlier', Format(NeverEarlier));
        Observer.Observe('distinct-steps-at-most-19', Format(Distinct <= 19));
        Observer.Observe('createdat-not-blank', Format(Previous <> 0DT));
        Observer.Expect('never-earlier', 'Yes');
        Observer.Expect('distinct-steps-at-most-19', 'Yes');
        Observer.Expect('createdat-not-blank', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P159_ModifyAfterInsert_ModifiedNotBeforeCreated()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P159 Stamp Row";
        CreatedAt: DateTime;
        ModifiedAtInsert: DateTime;
        ModifiedAtFirst: DateTime;
        ModifiedAtSecond: DateTime;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        CreatedAt := Row.SystemCreatedAt;
        ModifiedAtInsert := Row.SystemModifiedAt;
        Row.Qty := 1;
        Row.Modify();
        Row.Get(1);
        ModifiedAtFirst := Row.SystemModifiedAt;
        Row.Qty := 2;
        Row.Modify();
        Row.Get(1);
        ModifiedAtSecond := Row.SystemModifiedAt;
        Observer.Observe('modified-at-insert-vs-created', Relation(CreatedAt, ModifiedAtInsert));
        Observer.Observe('first-modify-vs-insert', Relation(ModifiedAtInsert, ModifiedAtFirst));
        Observer.Observe('second-modify-vs-first', Relation(ModifiedAtFirst, ModifiedAtSecond));
        Observer.Observe('created-unchanged-by-modify', Format(Row.SystemCreatedAt = CreatedAt));
        Observer.Expect('modified-at-insert-vs-created', 'equal');
        Observer.Expect('first-modify-vs-insert', 'equal');
        Observer.Expect('second-modify-vs-first', 'equal');
        Observer.Expect('created-unchanged-by-modify', 'Yes');
        Observer.Verify();
    end;
}

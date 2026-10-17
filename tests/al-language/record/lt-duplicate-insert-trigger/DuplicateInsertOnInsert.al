// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 74766 (with OnInsert) and 74767 (without), codeunits 74797 (log), 74798 (runner) and 74796 (tests)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: Insert of a record whose primary key already exists, in a table with an OnInsert trigger and in a table without one: Insert(true) with the result left unused,
//   Insert(true) with the result used, Insert(), Insert(false) unused and used. Whether it raised (the statement runs inside Codeunit.Run so the test survives),
//   the error text and code, whether OnInsert ran (log) and in which order relative to the error, the returned value, and the row count afterwards.
//   The own-table version of the Vendor and Item Journal Line cases of the Microsoft tests.
// BC versions: all (CI)

table 74766 "LT DIO With Trigger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT DIO Log";
    begin
        Log.Add('OnInsert ' + Format(Id) + '/' + Name);
    end;
}

table 74767 "LT DIO Without Trigger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74797 "LT DIO Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

codeunit 74798 "LT DIO Runner"
{
    var
        Mode: Integer;
        UseTrigger: Boolean;
        Returned: Boolean;

    procedure Setup(NewMode: Integer; NewUseTrigger: Boolean)
    begin
        Mode := NewMode;
        UseTrigger := NewUseTrigger;
        Returned := false;
    end;

    procedure ReturnedValue(): Boolean
    begin
        exit(Returned);
    end;

    trigger OnRun()
    var
        W: Record "LT DIO With Trigger";
        N: Record "LT DIO Without Trigger";
    begin
        W.Id := 1;
        W.Name := 'duplicate';
        N.Id := 1;
        N.Name := 'duplicate';
        case Mode of
            1: // unused, with trigger flag true
                if UseTrigger then W.Insert(true) else N.Insert(true);
            2: // used, true
                if UseTrigger then Returned := W.Insert(true) else Returned := N.Insert(true);
            3: // unused, no argument
                if UseTrigger then W.Insert() else N.Insert();
            4: // unused, false
                if UseTrigger then W.Insert(false) else N.Insert(false);
            5: // used, false
                if UseTrigger then Returned := W.Insert(false) else Returned := N.Insert(false);
            6: // used, no argument
                if UseTrigger then Returned := W.Insert() else Returned := N.Insert();
        end;
    end;
}

codeunit 74796 "LT DIO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        W: Record "LT DIO With Trigger";
        N: Record "LT DIO Without Trigger";
        Log: Codeunit "LT DIO Log";
    begin
        W.DeleteAll();
        N.DeleteAll();
        W.Id := 1;
        W.Name := 'original';
        W.Insert();
        N.Id := 1;
        N.Name := 'original';
        N.Insert();
        Log.Take();
    end;

    local procedure Attempt(var Observer: Codeunit "Probe Observer"; Tag: Text; Mode: Integer; UseTrigger: Boolean)
    var
        Runner: Codeunit "LT DIO Runner";
        Log: Codeunit "LT DIO Log";
        W: Record "LT DIO With Trigger";
        N: Record "LT DIO Without Trigger";
        Ran: Boolean;
    begin
        Seed();
        Runner.Setup(Mode, UseTrigger);
        Ran := Runner.Run();
        Observer.Observe(Tag + '.ran', Format(Ran));
        if not Ran then
            Observer.ObserveError(Tag + '.err')
        else
            Observer.Observe(Tag + '.returned', Format(Runner.ReturnedValue()));
        Observer.Observe(Tag + '.log', Log.Take());
        Observer.Observe(Tag + '.countWith', Format(W.Count()));
        Observer.Observe(Tag + '.countWithout', Format(N.Count()));
        W.Get(1);
        N.Get(1);
        Observer.Observe(Tag + '.nameWith', W.Name);
        Observer.Observe(Tag + '.nameWithout', N.Name);
    end;

    [Test]
    procedure DuplicateInsert_WithOnInsert_TrueUnused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Attempt(Observer, 'insertTrueUnused', 1, true);
        Observer.Finish();
    end;

    [Test]
    procedure DuplicateInsert_WithOnInsert_TrueUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Attempt(Observer, 'insertTrueUsed', 2, true);
        Observer.Finish();
    end;

    [Test]
    procedure DuplicateInsert_WithOnInsert_NoArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Attempt(Observer, 'insertUnused', 3, true);
        Attempt(Observer, 'insertUsed', 6, true);
        Observer.Finish();
    end;

    [Test]
    procedure DuplicateInsert_WithOnInsert_FalseArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Attempt(Observer, 'insertFalseUnused', 4, true);
        Attempt(Observer, 'insertFalseUsed', 5, true);
        Observer.Finish();
    end;

    [Test]
    procedure DuplicateInsert_WithoutOnInsert_Contrast()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Attempt(Observer, 'insertTrueUnused', 1, false);
        Attempt(Observer, 'insertTrueUsed', 2, false);
        Attempt(Observer, 'insertUnused', 3, false);
        Attempt(Observer, 'insertFalseUnused', 4, false);
        Attempt(Observer, 'insertFalseUsed', 5, false);
        Observer.Finish();
    end;
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 67605, codeunit 67605
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// An asserterror around a call that does not raise gives the ASSERTERROR text; the observed value shows that case.
// Facts: Evaluate(FieldRef, Text) called as a statement (result not used) with text that does not parse: does it raise, with which code and text,
// and what the field holds afterwards (Decimal, Date, Boolean, Code, Option, Integer).
// BC versions: 27, 28, 29

table 67605 "LT N582 Eval Fld"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Dt; Date) { }
        field(4; Dec; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(7; Num; Integer) { }
        field(8; Txt; Text[5]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67605 "LT N582 Eval FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalStatement(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text)
    var
        Row: Record "LT N582 Eval Fld";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.Id := 1;
        Row.Cd := 'KEEP';
        Row.Dt := 20240101D;
        Row.Dec := 9;
        Row.Flag := true;
        Row.Opt := Row.Opt::One;
        Row.Num := 9;
        Row.Txt := 'KEEP';
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(FieldNo);
        ClearLastError();
        asserterror Evaluate(FldRef, Txt);
        Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Format(FldRef.Value));
    end;

    [Test]
    procedure N582_Evaluate_FieldRef_Statement_BadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalStatement(Observer, 'decimal abc', 4, 'abc');
        EvalStatement(Observer, 'decimal empty', 4, '');
        EvalStatement(Observer, 'decimal ok', 4, '12.5');
        EvalStatement(Observer, 'date abc', 3, 'abc');
        EvalStatement(Observer, 'date empty', 3, '');
        EvalStatement(Observer, 'date 32th', 3, '320124');
        EvalStatement(Observer, 'boolean maybe', 5, 'maybe');
        EvalStatement(Observer, 'boolean empty', 5, '');
        EvalStatement(Observer, 'boolean yes', 5, 'Yes');
        EvalStatement(Observer, 'code too long', 2, 'ABCDEFGHIJKLMNOP');
        EvalStatement(Observer, 'code ok', 2, 'abc');
        EvalStatement(Observer, 'text too long', 8, 'ABCDEFGHIJ');
        EvalStatement(Observer, 'option Nope', 6, 'Nope');
        EvalStatement(Observer, 'option empty', 6, '');
        EvalStatement(Observer, 'option out of range', 6, '7');
        EvalStatement(Observer, 'option ok', 6, 'Two');
        EvalStatement(Observer, 'integer abc', 7, 'abc');
        EvalStatement(Observer, 'integer overflow', 7, '99999999999');
        Observer.Finish();
    end;
}

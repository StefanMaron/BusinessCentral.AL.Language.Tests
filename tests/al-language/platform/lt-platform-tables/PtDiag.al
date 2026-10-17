// Diagnostic: why does Codeunit.Run of the platform table runner raise the generic error?

codeunit 67197 "LT PT Diag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Ops: Codeunit "LT PT Ops";

    [Test]
    procedure RunnerOnOwnTable_HasRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_hasrows', Ops.Perform(67104, 'hasrows', '', false));
        Observer.Finish();
    end;

    [Test]
    procedure RunnerOnOwnTable_Columns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('own_columns', Ops.Perform(67104, 'columns', '', false));
        Observer.Finish();
    end;

    [Test]
    procedure RunnerUnknownOp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('unknown_op', Ops.Perform(67104, 'nothing', '', false));
        Observer.Finish();
    end;

    [Test]
    procedure Inline_OpenLanguageSelection()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        RR.Open(2000000050);
        Observer.Observe('fieldcount', Format(RR.FieldCount()));
        Observer.Observe('isempty', Format(RR.IsEmpty()));
        Observer.Finish();
    end;

    [Test]
    procedure Perform_LanguageSelection_Columns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('columns', Ops.Perform(2000000050, 'columns', '', false));
        Observer.Finish();
    end;
}

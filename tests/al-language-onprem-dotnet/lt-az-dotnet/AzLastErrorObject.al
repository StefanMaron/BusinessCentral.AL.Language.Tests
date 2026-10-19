// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject has scope OnPrem).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained objects 99470-99474
// Probe: corpus issue 652 item 16, writer AZ: the exception class of more error kinds, ToString of an exception raised below OnRun
// (in a nested procedure and in another codeunit), and Equals between a last-error exception and objects that are not exceptions.
// Already pinned: lt-dotnet-interop/GetLastErrorObjectKinds.al (TestField, Modify/Delete of a missing row, Evaluate, division by zero, Equals
// between two last-error exceptions).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtAzExc) { }
        type("System.Object"; LtAzObj) { }
        type("System.String"; LtAzString) { }
    }
}

table 99470 "LT AZ Lek Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[5]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 99471 "LT AZ Lek Deep"
{
    procedure Raise()
    begin
        Error('LT AZ deep error');
    end;
}

codeunit 99472 "LT AZ Lek Thrower"
{
    var
        Mode: Integer;

    trigger OnRun()
    var
        Row: Record "LT AZ Lek Row";
        Deep: Codeunit "LT AZ Lek Deep";
        Short: Text[3];
        Long: Text;
        Big: Integer;
        Info: ErrorInfo;
    begin
        case Mode of
            1:
                Nested();
            2:
                Deep.Raise();
            3:
                begin
                    Row.DeleteAll();
                    Row.Id := 1;
                    Row.Insert();
                    Row.Insert();
                end;
            4:
                begin
                    Long := 'abcdef';
                    Short := Long;
                end;
            5:
                begin
                    Big := 2147483647;
                    Big := Big + 1;
                end;
            6:
                begin
                    Row.Id := 7;
                    Row.FieldError(Name, 'is wrong');
                end;
            7:
                begin
                    Info.Message := 'LT AZ errorinfo without create';
                    Error(Info);
                end;
            8:
                Row.Get(-4242);
        end;
    end;

    local procedure Nested()
    begin
        Error('LT AZ nested error');
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 99473 "LT AZ Lek Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RunMode(Mode: Integer; var Exc: DotNet LtAzExc; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Thrower: Codeunit "LT AZ Lek Thrower";
    begin
        Commit();
        Thrower.SetMode(Mode);
        Observer.Observe(Name + '_ran', Format(Thrower.Run()));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_text', GetLastErrorText());
        Exc := GetLastErrorObject();
        Observer.Observe(Name + '_class', Exc.GetType().FullName);
        Observer.Observe(Name + '_message', Exc.Message);
    end;

    [Test]
    procedure Kinds_ClassAndMessage()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(3, Exc, Observer, 'dupinsert');
        RunMode(4, Exc, Observer, 'textoverflow');
        RunMode(5, Exc, Observer, 'intoverflow');
        RunMode(6, Exc, Observer, 'fielderror');
        RunMode(7, Exc, Observer, 'errorinfo_nocreate');
        RunMode(8, Exc, Observer, 'getmissing');
        Observer.Finish();
    end;

    [Test]
    procedure ToString_NestedProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(1, Exc, Observer, 'nested');
        Observer.Observe('nested_tostring', Exc.ToString());
        Observer.Observe('nested_format', Format(Exc));
        Observer.Finish();
    end;

    [Test]
    procedure ToString_OtherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
    begin
        RunMode(2, Exc, Observer, 'deep');
        Observer.Observe('deep_tostring', Exc.ToString());
        Observer.Finish();
    end;

    [Test]
    procedure Equals_NonExceptionObjects()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtAzExc;
        Obj: DotNet LtAzObj;
        Str: DotNet LtAzString;
        Same: DotNet LtAzObj;
    begin
        RunMode(1, Exc, Observer, 'nested');
        Str := 'LT AZ nested error';
        Observer.Observe('equals_string_of_message', Format(Exc.Equals(Str)));
        Obj := Obj.Object();
        Observer.Observe('equals_new_object', Format(Exc.Equals(Obj)));
        Same := Exc;
        Observer.Observe('equals_self_as_object', Format(Exc.Equals(Same)));
        Observer.Observe('object_equals_exception', Format(Same.Equals(Exc)));
        Observer.Finish();
    end;
}

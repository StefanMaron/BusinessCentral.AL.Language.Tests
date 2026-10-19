// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-simple-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 83851, codeunits 83852 and 83853
// Probe: corpus #664 item 40 (microsoft/AL issue 2229): the word Labels (a report section keyword) as a field, procedure, parameter and variable name
// Facts: Labels as table field name, procedure name, parameter name, global and local variable name: the code compiles and runs
// BC versions: 27, 28, 29

table 83851 "LT BN3 Labels Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Labels; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Doubled(): Integer
    begin
        exit(Labels * 2);
    end;
}

codeunit 83852 "LT BN3 Labels Helper"
{
    var
        Count: Integer;

    procedure Labels(Labels: Boolean): Text
    begin
        Count += 1;
        exit(Format(not Labels) + '/' + Format(Count));
    end;

    procedure LocalLabels(): Integer
    var
        Labels: Integer;
    begin
        Labels := 41;
        Labels += 1;
        exit(Labels);
    end;
}

codeunit 83853 "LT BN3 Labels Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Labels: Text;

    [Test]
    procedure BN3_Labels_AsFieldProcedureParameterVariable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT BN3 Labels Helper";
        Row: Record "LT BN3 Labels Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Labels := 21;
        Row.Insert();
        Row.Get(1);
        Observer.Observe('field', Format(Row.Labels));
        Observer.Observe('field via procedure', Format(Row.Doubled()));
        Row.SetRange(Labels, 21);
        Observer.Observe('filter', Row.GetFilter(Labels) + '|' + Format(Row.Count()));
        Observer.Observe('field caption', Row.FieldCaption(Labels));
        Observer.Observe('procedure true', Helper.Labels(true));
        Observer.Observe('procedure false', Helper.Labels(false));
        Observer.Observe('local variable', Format(Helper.LocalLabels()));
        Labels := 'global';
        Observer.Observe('global variable', Labels);
        Observer.Expect('field', '21');
        Observer.Expect('field via procedure', '42');
        Observer.Expect('filter', '21|1');
        Observer.Expect('field caption', 'Labels');
        Observer.Expect('procedure true', 'No/1');
        Observer.Expect('procedure false', 'Yes/2');
        Observer.Expect('local variable', '42');
        Observer.Expect('global variable', 'global');
        Observer.Verify();
    end;
}

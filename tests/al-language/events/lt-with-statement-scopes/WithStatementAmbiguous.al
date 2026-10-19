// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 72784 and 72785, test codeunit 72786
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: a name that is a record member and also a member of the enclosing codeunit may be refused as ambiguous (compile error) or may bind silently; this file is separate so only it drops.
// Facts: inside "with Rec do", which declaration an unqualified name binds to when a codeunit global variable, a codeunit local variable, a codeunit procedure or a built-in record method has the same name as a field or table procedure.
table 72784 "LT WithAmb Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit('row-describe');
    end;

    procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 2);
    end;
}

table 72785 "LT WithAmb Other"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Integer) { }
        field(3; Qty; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72786 "LT WithAmb"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Name: Text[30];
        Total: Integer;

    local procedure Describe(): Text
    begin
        exit('codeunit-describe');
    end;

    local procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 100);
    end;

    local procedure Count(): Integer
    begin
        exit(-1);
    end;

    [Test]
    procedure P195_With_GlobalVariableSameNameAsField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Row.DeleteAll();
        Name := 'global-name';
        Row.Name := 'field-name';
        with Row do begin
            Observer.Observe('inside-read', Name);
            Name := 'written-inside';
        end;
        Observer.Observe('row-field-after', Row.Name);
        Observer.Observe('global-after', Name);
        Observer.Observe('outside-read', Name);
        Observer.Expect('inside-read', 'field-name');
        Observer.Expect('row-field-after', 'written-inside');
        Observer.Expect('global-after', 'global-name');
        Observer.Expect('outside-read', 'global-name');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_LocalVariableSameNameAsField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
        Qty: Integer;
    begin
        Row.DeleteAll();
        Qty := 5;
        Row.Qty := 9;
        with Row do begin
            Observer.Observe('inside-read', Format(Qty));
            Qty := Qty + 1;
        end;
        Observer.Observe('local-after', Format(Qty));
        Observer.Observe('field-after', Format(Row.Qty));
        Observer.Expect('inside-read', '9');
        Observer.Expect('local-after', '5');
        Observer.Expect('field-after', '10');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_ProcedureSameNameAsTableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Observer.Observe('outside', Describe());
        with Row do begin
            Observer.Observe('inside-describe', Describe());
            Observer.Observe('inside-twice', Format(Twice(3)));
        end;
        Observer.Observe('qualified-row', Row.Describe());
        Observer.Observe('outside-twice', Format(Twice(3)));
        Observer.Expect('outside', 'codeunit-describe');
        Observer.Expect('inside-describe', 'row-describe');
        Observer.Expect('inside-twice', '6');
        Observer.Expect('qualified-row', 'row-describe');
        Observer.Expect('outside-twice', '300');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_BuiltInMethodSameNameAsCodeunitProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Observer.Observe('outside-count', Format(Count()));
        with Row do
            Observer.Observe('inside-count', Format(Count()));
        Observer.Expect('outside-count', '-1');
        Observer.Expect('inside-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P195_NestedWith_DifferentFieldTypes_SameName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WithAmb Row";
        Other: Record "LT WithAmb Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.Name := 'text-name';
        Other.Name := 42;
        Row.Qty := 7;
        Other.Qty := 'text-qty';
        with Row do
            with Other do begin
                Observer.Observe('name-inner-int', Format(Name));
                Observer.Observe('qty-inner-text', Format(Qty));
                Total := Name + 1;
            end;
        Observer.Observe('total-from-inner-int', Format(Total));
        with Other do
            with Row do begin
                Observer.Observe('name-inner-text', Format(Name));
                Observer.Observe('qty-inner-int', Format(Qty));
            end;
        Observer.Expect('name-inner-int', '42');
        Observer.Expect('qty-inner-text', 'text-qty');
        Observer.Expect('total-from-inner-int', '43');
        Observer.Expect('name-inner-text', 'text-name');
        Observer.Expect('qty-inner-int', '7');
        Observer.Verify();
    end;
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67171 - 67176
// Probe: TableRelation arms. (1) An Option with a blank first member (" ") used as const(" ") in an if/else chain of two tables: Validate of a value of each table with
// the option at each member; (2) rename of a parent row that rows of different kinds reference, where the relation is `if (Kind = filter(<> C)) Parent.Code`:
// the reference field of every row afterwards; (3) a relation with two where() conditions on non-key fields of the target: Validate with a value that fails
// none, one or both conditions, and its error text and code. Settles: relation-option-blank-const, rename-follows-filter-condition-arms,
// table-relation-several-where-non-key. Object ids 67171 - 67177.

table 67171 "LT TR One"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67172 "LT TR Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67173 "LT TR Option Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",A; }
        field(3; Ref; Code[10])
        {
            TableRelation = if (Opt = const(" ")) "LT TR One" else
            if (Opt = const(A)) "LT TR Two";
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67174 "LT TR Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Active; Boolean) { }
        field(3; Kind; Option) { OptionMembers = A,B; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67175 "LT TR Kind Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Ref; Code[10]) { TableRelation = if (Kind = filter(<> C)) "LT TR Parent".Code; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67176 "LT TR Where Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[10]) { TableRelation = "LT TR Parent".Code where(Active = const(true), Kind = const(A)); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67177 "LT TR Arms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        One: Record "LT TR One";
        Two: Record "LT TR Two";
        Parent: Record "LT TR Parent";
    begin
        One.DeleteAll();
        Two.DeleteAll();
        Parent.DeleteAll();
        One.Code := 'ONE';
        One.Insert();
        Two.Code := 'TWO';
        Two.Insert();
        AddParent('P1', true, 0);
        AddParent('ACTIVEB', true, 1);
        AddParent('INACTIVEA', false, 0);
        AddParent('INACTIVEB', false, 1);
    end;

    local procedure AddParent(Code: Code[10]; Active: Boolean; Kind: Integer)
    var
        Parent: Record "LT TR Parent";
    begin
        Parent.Init();
        Parent.Code := Code;
        Parent.Active := Active;
        Parent.Kind := Kind;
        Parent.Insert();
    end;

    [TryFunction]
    local procedure TryValidateOption(Opt: Integer; Value: Code[10])
    var
        Child: Record "LT TR Option Child";
    begin
        Child.Init();
        Child.Opt := Opt;
        Child.Validate(Ref, Value);
    end;

    local procedure OptionOutcome(Opt: Integer; Value: Code[10]): Text
    begin
        ClearLastError();
        if TryValidateOption(Opt, Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure OptionBlankConst_ArmPerMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('blank_opt_value_of_one', OptionOutcome(0, 'ONE'));
        Observer.Observe('blank_opt_value_of_two', OptionOutcome(0, 'TWO'));
        Observer.Observe('blank_opt_missing', OptionOutcome(0, 'NONE'));
        Observer.Observe('a_opt_value_of_one', OptionOutcome(1, 'ONE'));
        Observer.Observe('a_opt_value_of_two', OptionOutcome(1, 'TWO'));
        Observer.Observe('a_opt_missing', OptionOutcome(1, 'NONE'));
        Observer.Observe('blank_opt_blank_value', OptionOutcome(0, ''));
        Observer.Finish();
    end;

    local procedure KindChild(Id: Integer; Kind: Integer; Ref: Code[10])
    var
        Child: Record "LT TR Kind Child";
    begin
        Child.Init();
        Child.Id := Id;
        Child.Kind := Kind;
        Child.Ref := Ref;
        Child.Insert();
    end;

    local procedure RefOf(Id: Integer): Text
    var
        Child: Record "LT TR Kind Child";
    begin
        if not Child.Get(Id) then
            exit('<missing>');
        exit(Child.Ref);
    end;

    [Test]
    procedure Rename_FollowsOnlyTheArmsThatApply()
    var
        Parent: Record "LT TR Parent";
        Child: Record "LT TR Kind Child";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Child.DeleteAll();
        KindChild(1, 0, 'P1');
        KindChild(2, 1, 'P1');
        KindChild(3, 2, 'P1');
        Parent.Get('P1');
        Parent.Rename('P2');
        Observer.Observe('kind_a_ref', RefOf(1));
        Observer.Observe('kind_b_ref', RefOf(2));
        Observer.Observe('kind_c_ref', RefOf(3));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryValidateWhere(Value: Code[10])
    var
        Child: Record "LT TR Where Child";
    begin
        Child.Init();
        Child.Validate(Ref, Value);
    end;

    local procedure WhereOutcome(Value: Code[10]): Text
    begin
        ClearLastError();
        if TryValidateWhere(Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SeveralWhere_NonKeyFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('active_and_kind_a', WhereOutcome('P1'));
        Observer.Observe('active_kind_b', WhereOutcome('ACTIVEB'));
        Observer.Observe('inactive_kind_a', WhereOutcome('INACTIVEA'));
        Observer.Observe('inactive_kind_b', WhereOutcome('INACTIVEB'));
        Observer.Observe('missing', WhereOutcome('MISSING'));
        Observer.Observe('blank', WhereOutcome(''));
        Observer.Finish();
    end;
}

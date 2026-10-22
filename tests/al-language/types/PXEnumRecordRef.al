// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-getbysystemid-method
// https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: self-contained enums 69185 to 69187, table 69185, codeunit 69185; writer QX: table 87571 (QX_Get_EnumKey_NotFoundErrors)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Enum to Enum: an enum of another type is assigned only when the TARGET enum states AssignmentCompatibility = true (the source's property does not matter; without it
// the compiler gives AL0122, must-not-compile cases 0074 and 0075). The value is taken by ORDINAL: 1 gives the target member with ordinal 1, 9 and 0 likewise; an ordinal the
// target lacks (7) is kept (Format shows '7', AsInteger 7, and the result equals the source). Assigned to a table field the ordinal is kept; Get(Code, Enum) and
// SetRange(Kind, Enum) take the other enum type's value by ordinal (found for a declared ordinal, no row for the lacking one).
// Integer to Enum: `D := Int`, `Rec.Kind := Int`, Get(Code, Int) and SetRange(Kind, Int or literal) compile with and without AssignmentCompatibility and take the number as
// the ordinal; an ordinal the enum lacks (5, 7) is kept, GetFilter shows '5'.
// RecordRef.GetBySystemId(Guid): answers true and loads ALL fields of the row; for an unknown or null Guid it answers false and leaves the buffer as it was (the previous
// row's values stay); the row is found outside the RecordRef's filters and the filters stay; with the result dropped a missing Guid raises "The <table> does not exist.
// Identification fields and values: {<guid>}" / DB:RecordNotFound, a found one does not; a RecordRef never opened answers false (Number() is 0).
// BC versions: 27.5

enum 69185 "PX Src Compat"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
    value(7; Seven) { }
    value(9; Nine) { }
}

enum 69186 "PX Dst Compat"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
    value(9; Nueve) { }
}

enum 69187 "PX Dst Plain"
{
    Extensible = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
}

table 69185 "PX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "PX Dst Compat") { }
        field(3; Plain; Enum "PX Dst Plain") { }
        field(4; Info; Text[30]) { }
        field(5; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Code, Kind) { Clustered = true; }
        key(Sec; Info) { }
    }
}

codeunit 69185 "PX Enum Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnumToEnum_TargetAllowsAssignment_Ordinals()
    var
        S: Enum "PX Src Compat";
        D: Enum "PX Dst Compat";
        Observer: Codeunit "Probe Observer";
    begin
        S := S::One;
        D := S;
        Observer.Observe('one_ordinal', Format(D.AsInteger()));
        Observer.Observe('one_text', Format(D));
        S := S::Nine;
        D := S;
        Observer.Observe('nine_ordinal', Format(D.AsInteger()));
        Observer.Observe('nine_text', Format(D));
        S := S::None;
        D := S;
        Observer.Observe('none_ordinal', Format(D.AsInteger()));
        Observer.Observe('none_text', Format(D));
        S := S::Seven;
        D := S;
        Observer.Observe('seven_lacked_ordinal', Format(D.AsInteger()));
        Observer.Observe('seven_lacked_text', '[' + Format(D) + ']');
        Observer.Observe('seven_equals_source', Format(D = S));
        Observer.Expect('one_ordinal', '1');
        Observer.Expect('one_text', 'Uno');
        Observer.Expect('nine_ordinal', '9');
        Observer.Expect('nine_text', 'Nueve');
        Observer.Expect('none_ordinal', '0');
        Observer.Expect('none_text', 'None');
        Observer.Expect('seven_lacked_ordinal', '7');
        Observer.Expect('seven_lacked_text', '[7]');
        Observer.Expect('seven_equals_source', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EnumToEnum_InFieldAssignmentAndKey()
    var
        Row: Record "PX Row";
        Found: Record "PX Row";
        S: Enum "PX Src Compat";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Nueve;
        Row.Insert();
        S := S::Nine;
        Observer.Observe('get_found', Format(Found.Get('A', S)));
        Row.Kind := S;
        Observer.Observe('field_assign_ordinal', Format(Row.Kind.AsInteger()));
        S := S::Seven;
        Observer.Observe('get_lacking_ordinal_found', Format(Found.Get('A', S)));
        Row.SetRange(Kind, S);
        Observer.Observe('setrange_lacking_count', Format(Row.Count()));
        Observer.Expect('get_found', 'Yes');
        Observer.Expect('field_assign_ordinal', '9');
        Observer.Expect('get_lacking_ordinal_found', 'No');
        Observer.Expect('setrange_lacking_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerToEnum_AssignmentKeyAndSetRange()
    var
        Row: Record "PX Row";
        Found: Record "PX Row";
        Int: Integer;
        D: Enum "PX Dst Compat";
        P: Enum "PX Dst Plain";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Dos;
        Row.Insert();
        Int := 2;
        D := Enum::"PX Dst Compat".FromInteger(Int);
        Observer.Observe('frominteger', Format(D));
        Observer.Observe('get_integer_found', Format(Found.Get('A', Int)));
        Int := 9;
        Observer.Observe('get_integer_missing_row', Format(Found.Get('A', Int)));
        Row.SetRange(Kind, 2);
        Observer.Observe('setrange_literal_count', Format(Row.Count()));
        Int := 2;
        Row.SetRange(Kind, Int);
        Observer.Observe('setrange_variable_count', Format(Row.Count()));
        Int := 5;
        Row.SetRange(Kind, Int);
        Observer.Observe('setrange_lacking_count', Format(Row.Count()));
        Observer.Observe('setrange_lacking_filter', Row.GetFilter(Kind));
        Row.Kind := Int;
        Observer.Observe('field_assign_lacking_ordinal', Format(Row.Kind.AsInteger()));
        P := Enum::"PX Dst Plain".FromInteger(1);
        Observer.Observe('plain_frominteger', Format(P));
        Int := 9;
        D := Int;
        Observer.Observe('assign_declared_compat', Format(D) + '/' + Format(D.AsInteger()));
        Int := 5;
        D := Int;
        Observer.Observe('assign_lacking_compat', '[' + Format(D) + ']/' + Format(D.AsInteger()));
        Int := 2;
        P := Int;
        Observer.Observe('assign_declared_plain', Format(P) + '/' + Format(P.AsInteger()));
        Int := 7;
        P := Int;
        Observer.Observe('assign_lacking_plain', '[' + Format(P) + ']/' + Format(P.AsInteger()));
        Observer.Expect('frominteger', 'Dos');
        Observer.Expect('get_integer_found', 'Yes');
        Observer.Expect('get_integer_missing_row', 'No');
        Observer.Expect('setrange_literal_count', '1');
        Observer.Expect('setrange_variable_count', '1');
        Observer.Expect('setrange_lacking_count', '0');
        Observer.Expect('setrange_lacking_filter', '5');
        Observer.Expect('field_assign_lacking_ordinal', '5');
        Observer.Expect('plain_frominteger', 'Uno');
        Observer.Expect('assign_declared_compat', 'Nueve/9');
        Observer.Expect('assign_lacking_compat', '[5]/5');
        Observer.Expect('assign_declared_plain', 'Dos/2');
        Observer.Expect('assign_lacking_plain', '[7]/7');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_GetBySystemId_FoundAndNotFound()
    var
        Row: Record "PX Row";
        RecRef: RecordRef;
        Id: Guid;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Info := 'first';
        Row.Amount := 1.5;
        Row.Insert();
        Id := Row.SystemId;
        Row.Code := 'B';
        Row.Kind := Row.Kind::Dos;
        Row.Info := 'second';
        Row.Amount := 2.5;
        Row.Insert();
        RecRef.Open(Database::"PX Row");
        Found := RecRef.GetBySystemId(Id);
        Observer.Observe('found', Format(Found));
        Observer.Observe('code', Format(RecRef.Field(1).Value));
        Observer.Observe('kind', Format(RecRef.Field(2).Value));
        Observer.Observe('info', Format(RecRef.Field(4).Value));
        Observer.Observe('amount', Format(RecRef.Field(5).Value));
        Observer.Observe('systemid_matches', Format(Format(RecRef.Field(RecRef.SystemIdNo()).Value) = Format(Id)));
        Observer.Observe('count_after_found', Format(RecRef.Count()));
        Found := RecRef.GetBySystemId(CreateGuid());
        Observer.Observe('missing_found', Format(Found));
        Observer.Observe('missing_code_after', Format(RecRef.Field(1).Value));
        Observer.Observe('missing_info_after', Format(RecRef.Field(4).Value));
        Found := RecRef.GetBySystemId('00000000-0000-0000-0000-000000000000');
        Observer.Observe('null_guid_found', Format(Found));
        Observer.Expect('found', 'Yes');
        Observer.Expect('code', 'A');
        Observer.Expect('kind', 'Uno');
        Observer.Expect('info', 'first');
        Observer.Expect('amount', '1.5');
        Observer.Expect('systemid_matches', 'Yes');
        Observer.Expect('count_after_found', '2');
        Observer.Expect('missing_found', 'No');
        Observer.Expect('missing_code_after', 'A');
        Observer.Expect('missing_info_after', 'first');
        Observer.Expect('null_guid_found', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_GetBySystemId_ResultUnused()
    var
        Row: Record "PX Row";
        RecRef: RecordRef;
        Id: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Insert();
        Id := Row.SystemId;
        RecRef.Open(Database::"PX Row");
        RecRef.GetBySystemId(Id);
        Observer.Observe('unused_found_no_error', Format(RecRef.Field(1).Value));
        asserterror RecRef.GetBySystemId(CreateGuid());
        Observer.ObserveError('unused_missing');
        Observer.Expect('unused_found_no_error', 'A');
        Observer.Expect('unused_missing|text', 'The PX Row does not exist. Identification fields and values: {x}');
        Observer.Expect('unused_missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_GetBySystemId_WithFilters_AndClosedRef()
    var
        Row: Record "PX Row";
        RecRef: RecordRef;
        Closed: RecordRef;
        Id: Guid;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Info := 'x';
        Row.Insert();
        Id := Row.SystemId;
        RecRef.Open(Database::"PX Row");
        RecRef.Field(4).SetRange('other');
        Found := RecRef.GetBySystemId(Id);
        Observer.Observe('found_outside_filter', Format(Found));
        Observer.Observe('filters_kept', RecRef.GetFilters());
        Found := Closed.GetBySystemId(Id);
        Observer.Observe('never_opened_ref_found', Format(Found));
        Observer.Observe('never_opened_ref_number', Format(Closed.Number()));
        Observer.Expect('found_outside_filter', 'Yes');
        Observer.Expect('filters_kept', 'Info: other');
        Observer.Expect('never_opened_ref_found', 'No');
        Observer.Expect('never_opened_ref_number', '0');
        Observer.Verify();
    end;

    // ---- Writer QX (Microsoft's DemoTool: ProductionOrder.Get(Type, ProductionOrderNo) with an Integer for the Enum key field Status and no
    // such row): the not-found error of a Get keyed by an Integer, an Option and an enum of another type on an Enum key field (table 87571,
    // key Status (Enum) then No.), and on table PX Row (key Code then Kind). Result unused: the error text and code. ----

    [Test]
    procedure QX_Get_EnumKey_NotFoundErrors()
    var
        Row: Record "LT QX Enum First Row";
        PxRow: Record "PX Row";
        Int: Integer;
        Opt: Option None,Uno,Dos;
        Other: Enum "PX Src Compat";
        Own: Enum "PX Dst Compat";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Status := Row.Status::Dos;
        Row."No." := 'P1';
        Row.Insert();
        Int := 2;
        Observer.Observe('integer found', Format(Row.Get(Int, 'P1')));
        Int := 2;
        asserterror Row.Get(Int, 'P9');
        Observer.ObserveError('integer declared ordinal, no row');
        Int := 7;
        asserterror Row.Get(Int, 'P1');
        Observer.ObserveError('integer ordinal the enum lacks');
        asserterror Row.Get(1, 'P1');
        Observer.ObserveError('integer literal');
        Opt := Opt::Uno;
        asserterror Row.Get(Opt, 'P1');
        Observer.ObserveError('option');
        Other := Other::Seven;
        asserterror Row.Get(Other, 'P1');
        Observer.ObserveError('other enum ordinal the key enum lacks');
        Other := Other::One;
        asserterror Row.Get(Other, 'P1');
        Observer.ObserveError('other enum declared ordinal');
        Own := Own::Nueve;
        asserterror Row.Get(Own, 'P1');
        Observer.ObserveError('own enum');
        PxRow.DeleteAll();
        Int := 9;
        asserterror PxRow.Get('A', Int);
        Observer.ObserveError('px row integer second key field');
        Row.DeleteAll();
        Observer.Expect('integer found', 'Yes');
        Observer.Expect('integer declared ordinal, no row|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''Dos'',No.=''P9''');
        Observer.Expect('integer declared ordinal, no row|code', 'DB:RecordNotFound');
        Observer.Expect('integer ordinal the enum lacks|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''7'',No.=''P1''');
        Observer.Expect('integer ordinal the enum lacks|code', 'DB:RecordNotFound');
        Observer.Expect('integer literal|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''Uno'',No.=''P1''');
        Observer.Expect('integer literal|code', 'DB:RecordNotFound');
        Observer.Expect('option|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''Uno'',No.=''P1''');
        Observer.Expect('option|code', 'DB:RecordNotFound');
        Observer.Expect('other enum ordinal the key enum lacks|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''Seven'',No.=''P1''');
        Observer.Expect('other enum ordinal the key enum lacks|code', 'DB:RecordNotFound');
        Observer.Expect('other enum declared ordinal|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''One'',No.=''P1''');
        Observer.Expect('other enum declared ordinal|code', 'DB:RecordNotFound');
        Observer.Expect('own enum|text', 'The LT QX Enum First Row does not exist. Identification fields and values: Status=''Nueve'',No.=''P1''');
        Observer.Expect('own enum|code', 'DB:RecordNotFound');
        Observer.Expect('px row integer second key field|text', 'The PX Row does not exist. Identification fields and values: Code=''A'',Kind=''Nueve''');
        Observer.Expect('px row integer second key field|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}

table 87571 "LT QX Enum First Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Status; Enum "PX Dst Compat") { }
        field(2; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; Status, "No.") { Clustered = true; }
    }
}

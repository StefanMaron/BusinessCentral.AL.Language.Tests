// Batch 6, md:899 [Table Relations Metadata] filter(...) condition: the form filter(A|B) is measured by session/PWPlatformTables.al (condition type FILTER, value 0|1).
// What is left open is the other filter forms and the forms around them: a filter range, a filter on a Code field, a condition on the RELATED table (where Txt = field(...)
// / const / filter), a three-branch else chain, and the two relation flags. Observe-only: one text line per relation row of the own source table.

table 67345 "W6 TR Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 67346 "W6 TR Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = A,B,C; }
        field(3; Kc; Code[10]) { }
        field(4; Other; Text[20]) { }
        field(10; RefRange; Code[10]) { TableRelation = if (Kind = filter(A .. B)) "W6 TR Target".Id; }
        field(11; RefCodeFilter; Code[10]) { TableRelation = if (Kc = filter('X|Y')) "W6 TR Target".Id; }
        field(12; RefNotEqual; Code[10]) { TableRelation = if (Kc = filter('<>X')) "W6 TR Target".Id; }
        field(13; RefRelatedField; Code[10]) { TableRelation = "W6 TR Target".Id where(Txt = field(Other)); }
        field(14; RefRelatedConst; Code[10]) { TableRelation = "W6 TR Target".Id where(Txt = const('K')); }
        field(15; RefRelatedFilter; Code[10]) { TableRelation = "W6 TR Target".Id where(Txt = filter('K|L')); }
        field(16; RefThreeBranches; Code[10])
        {
            TableRelation = if (Kind = const(A)) "W6 TR Target".Id else if (Kind = const(B)) "W6 TR Target".Txt else if (Kind = const(C)) "W6 TR Target".Id where(Txt = const('Z'));
        }
        field(17; RefNoValidate; Code[10])
        {
            TableRelation = "W6 TR Target".Id;
            ValidateTableRelation = false;
        }
        field(18; RefNoTest; Code[10])
        {
            TableRelation = "W6 TR Target".Id;
            TestTableRelation = false;
        }
        field(19; RefPlain; Code[10]) { TableRelation = "W6 TR Target".Id; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67347 "W6 Table Relations Meta"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RelationsOf(FieldNumber: Integer): Text
    var
        Rel: Record "Table Relations Metadata";
        Result: Text;
    begin
        Rel.SetRange("Table ID", Database::"W6 TR Source");
        Rel.SetRange("Field No.", FieldNumber);
        Result := 'rows=' + Format(Rel.Count()) + ' ';
        if Rel.FindSet() then
            repeat
                Result += StrSubstNo('[%1.%2 condfield %3 %4 "%5"] ', Rel."Related Table ID", Rel."Related Field No.", Rel."Condition Field No.", Rel."Condition Type", Rel."Condition Value");
            until Rel.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Relations_ConditionOnTheSourceField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('RefRange', RelationsOf(10));
        Observer.Observe('RefCodeFilter', RelationsOf(11));
        Observer.Observe('RefNotEqual', RelationsOf(12));
        Observer.Observe('RefThreeBranches', RelationsOf(16));
        Observer.Expect('RefRange', 'rows=1 [67345.1 condfield 2 FILTER "0..1"] ');
        Observer.Expect('RefCodeFilter', 'rows=1 [67345.1 condfield 3 FILTER "X|Y"] ');
        Observer.Expect('RefNotEqual', 'rows=1 [67345.1 condfield 3 FILTER "<>X"] ');
        Observer.Expect('RefThreeBranches', 'rows=3 [67345.1 condfield 2 CONST "0"] [67345.2 condfield 2 CONST "1"] [67345.1 condfield 2 CONST "2"] ');
        Observer.Verify();
    end;

    [Test]
    procedure Relations_ConditionOnTheRelatedTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('RefRelatedField', RelationsOf(13));
        Observer.Observe('RefRelatedConst', RelationsOf(14));
        Observer.Observe('RefRelatedFilter', RelationsOf(15));
        Observer.Expect('RefRelatedField', 'rows=1 [67345.1 condfield 0 CONST ""] ');
        Observer.Expect('RefRelatedConst', 'rows=1 [67345.1 condfield 0 CONST ""] ');
        Observer.Expect('RefRelatedFilter', 'rows=1 [67345.1 condfield 0 CONST ""] ');
        Observer.Verify();
    end;

}

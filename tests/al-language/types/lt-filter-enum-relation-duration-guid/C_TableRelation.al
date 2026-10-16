// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own tables 72684 to 72688, test codeunit 72689 (P85)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TableRelation with conditional arms on Zone = filter('') / filter(<> ''), a value in neither arm, and where(Field = const / field / filter) conditions: Validate outcome and error text
// BC versions: 29 (27 and 28 by CI)

table 72684 "LT P85 Loc"
{
    DataClassification = SystemMetadata;
    fields { field(1; Code; Code[10]) { } }
    keys { key(PK; Code) { Clustered = true; } }
}

table 72685 "LT P85 Bin"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Zone; Code[10]) { }
        field(2; Code; Code[10]) { }
    }
    keys { key(PK; Zone, Code) { Clustered = true; } }
}

table 72686 "LT P85 Item"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Grp; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 72687 "LT P85 Rel"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Zone; Code[10]) { }
        field(3; Kind; Option) { OptionMembers = A,B,C; }
        field(4; Place; Code[10])
        {
            TableRelation = if (Zone = filter('')) "LT P85 Loc".Code
            else if (Zone = filter(<> '')) "LT P85 Bin".Code where(Zone = field(Zone));
        }
        field(5; KindPlace; Code[10])
        {
            TableRelation = if (Kind = const(A)) "LT P85 Loc".Code
            else if (Kind = const(B)) "LT P85 Bin".Code;
        }
        field(6; Grp; Code[10]) { }
        field(7; ItemConst; Code[10]) { TableRelation = "LT P85 Item".Code where(Grp = const('G1')); }
        field(8; ItemField; Code[10]) { TableRelation = "LT P85 Item".Code where(Grp = field(Grp)); }
        field(9; ItemFilter; Code[10]) { TableRelation = "LT P85 Item".Code where(Grp = filter('G1|G2')); }
        field(10; ItemFilterNot; Code[10]) { TableRelation = "LT P85 Item".Code where(Grp = filter(<> 'G1')); }
        field(11; ItemNoCheck; Code[10]) { TableRelation = "LT P85 Item".Code where(Grp = const('G1')); ValidateTableRelation = false; }
        field(12; ZoneArms; Code[10])
        {
            TableRelation = if (Zone = filter('A|B')) "LT P85 Loc".Code
            else if (Zone = filter('C')) "LT P85 Item".Code;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 72689 "LT P85 Relation Arms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Loc: Record "LT P85 Loc";
        Bin: Record "LT P85 Bin";
        Item: Record "LT P85 Item";
        R: Record "LT P85 Rel";
    begin
        R.DeleteAll();
        Loc.DeleteAll();
        Bin.DeleteAll();
        Item.DeleteAll();
        Loc.Code := 'LOC1';
        Loc.Insert();
        Loc.Code := 'SHARED';
        Loc.Insert();
        Bin.Zone := 'Z1';
        Bin.Code := 'BIN1';
        Bin.Insert();
        Bin.Zone := 'Z2';
        Bin.Code := 'BIN2';
        Bin.Insert();
        Bin.Zone := 'Z1';
        Bin.Code := 'SHARED';
        Bin.Insert();
        Item.Code := 'I1';
        Item.Grp := 'G1';
        Item.Insert();
        Item.Code := 'I2';
        Item.Grp := 'G2';
        Item.Insert();
        Item.Code := 'I3';
        Item.Grp := 'G3';
        Item.Insert();
    end;

    [TryFunction]
    local procedure TryPlace(var R: Record "LT P85 Rel"; V: Code[10])
    begin
        R.Validate(Place, V);
    end;

    local procedure PlaceOutcome(Zone: Code[10]; V: Code[10]): Text
    var
        R: Record "LT P85 Rel";
    begin
        R.Init();
        R.Zone := Zone;
        if TryPlace(R, V) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Zone_Blank_Arm_Loc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('blank_loc1', PlaceOutcome('', 'LOC1'));
        Observer.Observe('blank_shared', PlaceOutcome('', 'SHARED'));
        Observer.Observe('blank_bin1', PlaceOutcome('', 'BIN1'));
        Observer.Observe('blank_empty_value', PlaceOutcome('', ''));
        Observer.Observe('blank_unknown', PlaceOutcome('', 'NOPE'));
        Observer.Finish();
    end;

    [Test]
    procedure Zone_Filled_Arm_Bin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('z1_bin1', PlaceOutcome('Z1', 'BIN1'));
        Observer.Observe('z1_shared', PlaceOutcome('Z1', 'SHARED'));
        Observer.Observe('z1_bin2_other_zone', PlaceOutcome('Z1', 'BIN2'));
        Observer.Observe('z2_bin2', PlaceOutcome('Z2', 'BIN2'));
        Observer.Observe('z2_shared_other_zone', PlaceOutcome('Z2', 'SHARED'));
        Observer.Observe('z1_loc1', PlaceOutcome('Z1', 'LOC1'));
        Observer.Observe('z1_empty_value', PlaceOutcome('Z1', ''));
        Observer.Observe('z9_unknown_zone', PlaceOutcome('Z9', 'BIN1'));
        Observer.Finish();
    end;

    [Test]
    procedure Zone_Error_Text_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P85 Rel";
    begin
        Seed();
        R.Init();
        asserterror R.Validate(Place, 'NOPE');
        Observer.ObserveError('blank_zone_nope');
        R.Zone := 'Z1';
        asserterror R.Validate(Place, 'NOPE');
        Observer.ObserveError('z1_nope');
        asserterror R.Validate(Place, 'BIN2');
        Observer.ObserveError('z1_bin2');
        R.Zone := '';
        asserterror R.Validate(Place, 'BIN1');
        Observer.ObserveError('blank_bin1');
        Observer.Finish();
    end;

    [Test]
    procedure Where_Const()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P85 Rel";
    begin
        Seed();
        R.Init();
        R.Validate(ItemConst, 'I1');
        Observer.Observe('i1', R.ItemConst);
        asserterror R.Validate(ItemConst, 'I2');
        Observer.ObserveError('i2_other_group');
        asserterror R.Validate(ItemConst, 'NOPE');
        Observer.ObserveError('nope');
        R.Validate(ItemConst, '');
        Observer.Observe('blank_ok', R.ItemConst);
        Observer.Finish();
    end;

    [Test]
    procedure Where_Field()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P85 Rel";
    begin
        Seed();
        R.Init();
        R.Grp := 'G2';
        R.Validate(ItemField, 'I2');
        Observer.Observe('g2_i2', R.ItemField);
        asserterror R.Validate(ItemField, 'I1');
        Observer.ObserveError('g2_i1');
        R.Grp := '';
        asserterror R.Validate(ItemField, 'I1');
        Observer.ObserveError('blank_group_i1');
        R.Validate(ItemField, '');
        Observer.Observe('blank_group_blank_value', R.ItemField);
        R.Grp := 'G9';
        asserterror R.Validate(ItemField, 'I3');
        Observer.ObserveError('g9_i3');
        Observer.Finish();
    end;

    [Test]
    procedure Where_ValidateTableRelation_False()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P85 Rel";
    begin
        Seed();
        R.Init();
        R.Validate(ItemNoCheck, 'NOPE');
        Observer.Observe('nope_accepted', R.ItemNoCheck);
        R.Validate(ItemNoCheck, 'I2');
        Observer.Observe('other_group_accepted', R.ItemNoCheck);
        Observer.Finish();
    end;
}

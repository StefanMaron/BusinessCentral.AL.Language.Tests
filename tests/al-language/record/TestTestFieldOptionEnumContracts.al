// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained enums 68850..68853, table 68854, codeunit 68855
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins TestField on Option and Enum fields:
//  - TestField(F) on a field that holds its zero member raises "<field> must not be <caption> in <table>: <key>=<value>",
//    code TestField, where <caption> is the member's caption (the option caption, the enum caption; a member
//    without a caption shows its name; a blank member shows a space, which leaves three spaces in a row). It
//    is NOT the "must have a value" text that Text and Integer fields give.
//  - TestField(F, Value) with another member raises "<field> must be equal to '<caption of Value>'  in <table>: <key>=<value>.
//    Current value is '<caption of the current member>'." (two spaces after the closing quote).
//  - A member other than the zero one passes TestField(F).
// BC versions: 27.5

enum 68850 "Probe TF EnumBlank"
{
    Extensible = true;

    value(0; " ") { }
    value(1; One) { Caption = 'One cap'; }
}

enum 68851 "Probe TF EnumBlankCap"
{
    Extensible = true;

    value(0; " ") { Caption = '(All)'; }
    value(1; One) { Caption = 'One cap'; }
}

enum 68852 "Probe TF EnumNamed"
{
    Extensible = true;

    value(0; Zero) { Caption = 'Zero cap'; }
    value(1; One) { Caption = 'One cap'; }
}

enum 68853 "Probe TF EnumNoCap"
{
    Extensible = true;

    value(0; Zero) { }
    value(1; One) { }
}

table 68854 "Probe TF Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; OptBlank; Option)
        {
            OptionMembers = " ",A,B;
            OptionCaption = ' ,A cap,B cap';
        }
        field(3; OptNamed; Option)
        {
            OptionMembers = Alpha,Beta;
            OptionCaption = 'Alpha cap,Beta cap';
        }
        field(4; EnBlank; Enum "Probe TF EnumBlank") { }
        field(5; EnBlankCap; Enum "Probe TF EnumBlankCap") { }
        field(6; EnNamed; Enum "Probe TF EnumNamed") { }
        field(7; EnNoCap; Enum "Probe TF EnumNoCap") { }
        field(8; OptNoCap; Option) { OptionMembers = First,Second; }
        field(9; Txt; Text[10]) { }
        field(10; Int; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68855 "Probe TestField Option Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestField_ZeroMember_RaisesMustNotBeTheCaption()
    var
        TfRec: Record "Probe TF Table";
    begin
        TfRec.Id := 5;

        asserterror TfRec.TestField(OptBlank);
        Assert.AreEqual('OptBlank must not be   in Probe TF Table: Id=5', GetLastErrorText(), 'blank option member');
        Assert.AreEqual('TestField', GetLastErrorCode(), 'code');
        asserterror TfRec.TestField(OptNamed);
        Assert.AreEqual('OptNamed must not be Alpha cap in Probe TF Table: Id=5', GetLastErrorText(), 'named option member');
        asserterror TfRec.TestField(EnBlank);
        Assert.AreEqual('EnBlank must not be   in Probe TF Table: Id=5', GetLastErrorText(), 'blank enum member, no caption');
        asserterror TfRec.TestField(EnBlankCap);
        Assert.AreEqual('EnBlankCap must not be (All) in Probe TF Table: Id=5', GetLastErrorText(), 'blank enum member with a caption');
        asserterror TfRec.TestField(EnNamed);
        Assert.AreEqual('EnNamed must not be Zero cap in Probe TF Table: Id=5', GetLastErrorText(), 'named enum member');
        asserterror TfRec.TestField(EnNoCap);
        Assert.AreEqual('EnNoCap must not be Zero in Probe TF Table: Id=5', GetLastErrorText(), 'enum member without a caption shows its name');
        asserterror TfRec.TestField(OptNoCap);
        Assert.AreEqual('OptNoCap must not be First in Probe TF Table: Id=5', GetLastErrorText(), 'option without captions shows the member name');
    end;

    [Test]
    procedure TestField_TextAndInteger_KeepTheMustHaveAValueText()
    var
        TfRec: Record "Probe TF Table";
    begin
        TfRec.Id := 5;

        asserterror TfRec.TestField(Txt);
        Assert.AreEqual('Txt must have a value in Probe TF Table: Id=5. It cannot be zero or empty.', GetLastErrorText(), 'text');
        asserterror TfRec.TestField(Int);
        Assert.AreEqual('Int must have a value in Probe TF Table: Id=5. It cannot be zero or empty.', GetLastErrorText(), 'integer');
    end;

    [Test]
    procedure TestField_WithAValue_NamesBothCaptions()
    var
        TfRec: Record "Probe TF Table";
    begin
        TfRec.Id := 5;

        asserterror TfRec.TestField(OptBlank, TfRec.OptBlank::A);
        Assert.AreEqual('OptBlank must be equal to ''A cap''  in Probe TF Table: Id=5. Current value is '' ''.', GetLastErrorText(), 'zero option member against A');
        asserterror TfRec.TestField(OptNamed, TfRec.OptNamed::Beta);
        Assert.AreEqual('OptNamed must be equal to ''Beta cap''  in Probe TF Table: Id=5. Current value is ''Alpha cap''.', GetLastErrorText(), 'named option');
        asserterror TfRec.TestField(EnBlankCap, TfRec.EnBlankCap::One);
        Assert.AreEqual('EnBlankCap must be equal to ''One cap''  in Probe TF Table: Id=5. Current value is ''(All)''.', GetLastErrorText(), 'enum with a blank captioned zero member');
        asserterror TfRec.TestField(EnNamed, TfRec.EnNamed::One);
        Assert.AreEqual('EnNamed must be equal to ''One cap''  in Probe TF Table: Id=5. Current value is ''Zero cap''.', GetLastErrorText(), 'named enum');

        TfRec.OptBlank := TfRec.OptBlank::B;
        asserterror TfRec.TestField(OptBlank, TfRec.OptBlank::A);
        Assert.AreEqual('OptBlank must be equal to ''A cap''  in Probe TF Table: Id=5. Current value is ''B cap''.', GetLastErrorText(), 'non-zero option member');
        TfRec.EnBlank := TfRec.EnBlank::One;
        asserterror TfRec.TestField(EnBlank, TfRec.EnBlank::" ");
        Assert.AreEqual('EnBlank must be equal to '' ''  in Probe TF Table: Id=5. Current value is ''One cap''.', GetLastErrorText(), 'non-zero enum member against the blank one');
        asserterror TfRec.TestField(Txt, 'x');
        Assert.AreEqual('Txt must be equal to ''x''  in Probe TF Table: Id=5. Current value is ''''.', GetLastErrorText(), 'text');
    end;

    [Test]
    procedure TestField_NonZeroMember_Passes()
    var
        TfRec: Record "Probe TF Table";
    begin
        TfRec.Id := 5;
        TfRec.OptBlank := TfRec.OptBlank::B;
        TfRec.EnBlank := TfRec.EnBlank::One;

        TfRec.TestField(OptBlank);
        TfRec.TestField(EnBlank);
        TfRec.TestField(OptBlank, TfRec.OptBlank::B);
    end;
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
// Scope: in-scope
// Fixtures used: ALT Key Probe (60977), Assert (60021)
//
// Pins the built-in "Key" system virtual table (2000000063): one row per key declared on a
// table, computed from the table's own metadata rather than stored anywhere. It is the sibling
// of Table Metadata (2000000136) and Field (2000000041), already pinned elsewhere in this
// directory.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4147, which measures the
// runner serving NO provider for this table -- id 2000000063 appears nowhere under AlRunner/,
// against 5 references for Table Relations Metadata (2000000141), which #4129 did serve. A
// table with no provider falls through to an empty temp store and answers "no rows" to every
// read, silently. Nothing here predicts the runner's answer.
//
// THE FIXTURE DECLARES THREE KEYS ON PURPOSE, with deliberately non-default properties:
// a clustered primary key, a second key that is NOT clustered, and a third that is disabled.
// A provider answering a fixed or blank row for every Get would satisfy none of the arms
// below, and the negatives carry as much weight as the positives for that reason.

table 60977 "ALT Key Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Bucket"; Code[20]) { }
        field(3; "Amount"; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        // Two fields, so the KeyFields column has something a single-field key cannot produce.
        key(Secondary; "Bucket", "Entry No.") { }
        // Enabled = false: the Enabled column must report it, and a provider that hardcodes
        // true fails here rather than silently agreeing with the other two keys.
        key(Disabled; "Amount") { Enabled = false; }
    }
}

codeunit 60936 "Test Key Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ProbeTableId: Integer;

    local procedure Initialize()
    var
        Probe: Record "ALT Key Probe";
    begin
        ProbeTableId := Database::"ALT Key Probe";
        Probe.DeleteAll();
    end;

    [Test]
    procedure Record_Key_OnTheProbeTable_ReturnsOneRowPerDeclaredKey()
    // THE SUBJECT. Three keys are declared, so three rows. A table with no provider answers 0,
    // which is the #4147 shape.
    var
        KeyRec: Record "Key";
    begin
        Initialize();

        KeyRec.SetRange(TableNo, ProbeTableId);
        Assert.AreEqual(
            3, KeyRec.Count(),
            'The Key virtual table must report one row per key the table declares, and this table declares three.');
    end;

    [Test]
    procedure Record_Key_PrimaryKey_IsClusteredAndNamesItsField()
    // The first key: clustered, one field. Reads two columns that a blank row cannot satisfy.
    var
        KeyRec: Record "Key";
    begin
        Initialize();

        KeyRec.Get(ProbeTableId, 1);
        Assert.AreEqual('Entry No.', KeyRec."Key", 'Key 1 must name the field its declaration lists.');
        Assert.AreEqual(true, KeyRec.Clustered, 'Key 1 is declared Clustered = true.');
        Assert.AreEqual(true, KeyRec.Enabled, 'Key 1 carries no Enabled = false, so it is enabled.');
    end;

    [Test]
    procedure Record_Key_SecondaryKey_ListsBothFieldsAndIsNotClustered()
    // The discriminator against a provider that answers the primary key for every index: this
    // key has TWO fields and is NOT clustered, so both columns differ from key 1's.
    var
        KeyRec: Record "Key";
    begin
        Initialize();

        KeyRec.Get(ProbeTableId, 2);
        Assert.AreEqual(
            'Bucket,Entry No.', KeyRec."Key",
            'A multi-field key lists its fields comma-separated, in declaration order.');
        Assert.AreEqual(false, KeyRec.Clustered, 'Only the primary key is clustered.');
    end;

    [Test]
    procedure Record_Key_DisabledKey_ReportsEnabledFalse()
    // The negative direction. A provider hardcoding Enabled = true passes the two arms above
    // and fails here, which is the point of declaring a disabled key at all.
    var
        KeyRec: Record "Key";
    begin
        Initialize();

        KeyRec.Get(ProbeTableId, 3);
        Assert.AreEqual('Amount', KeyRec."Key", 'Key 3 must name its own field.');
        Assert.AreEqual(false, KeyRec.Enabled, 'Key 3 is declared Enabled = false.');
    end;

    [Test]
    procedure Record_Key_UnknownTable_ReturnsNoRows()
    // The control. An id no table claims must answer zero rows rather than raising -- BC's own
    // provider catches NavMetadataNotFoundException and yields nothing. Without this arm, a
    // provider that answered zero for EVERYTHING would look correct here.
    var
        KeyRec: Record "Key";
    begin
        Initialize();

        KeyRec.SetRange(TableNo, 1999999);
        Assert.AreEqual(
            0, KeyRec.Count(),
            'A table id nothing declares must yield no Key rows, and must not raise.');
    end;
}

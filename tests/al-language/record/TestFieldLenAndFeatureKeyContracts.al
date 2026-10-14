// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained enum 68880, table 68881, codeunit 68882
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. The Feature Key rows are the 27.5 list and are pinned for BC versions below 28 only.
//
// Pins:
//  - the Len column of the Field table for one field of each type: Text and Code the declared length
//    (1, 10, 20, 30, 250, 2048), Integer 4, BigInteger 8, Decimal 12, Boolean 4, Date 4, Time 4, DateTime 8,
//    Duration 8, Guid 16, Option 4, Enum 4, Blob 8, Media 16, MediaSet 16, RecordId 448, DateFormula 32,
//    TableFilter 504, a FlowField Integer 4, and the system fields: SystemId 16, SystemCreatedAt 8,
//    SystemCreatedBy 16, SystemModifiedAt 8, SystemModifiedBy 16.
//  - the "Feature Key" table of the 27.5 platform: its columns (field numbers 1 to 10) and its 16 rows with ID,
//    Enabled and "Data Update Required".
// BC versions: 27.5 (the Feature Key rows); the field lengths 27.5
enum 68880 "Probe Len Enum"
{
    Extensible = true;

    value(0; A) { }
}

table 68881 "Probe Len Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1; Text[30]) { }
        field(3; F2; Code[20]) { }
        field(4; F3; Integer) { }
        field(5; F4; BigInteger) { }
        field(6; F5; Decimal) { }
        field(7; F6; Boolean) { }
        field(8; F7; Date) { }
        field(9; F8; Time) { }
        field(10; F9; DateTime) { }
        field(11; F10; Duration) { }
        field(12; F11; Guid) { }
        field(13; F12; Option) { OptionMembers = A,B; }
        field(14; F13; Enum "Probe Len Enum") { }
        field(15; F14; Blob) { }
        field(16; F15; Media) { }
        field(17; F16; MediaSet) { }
        field(18; F17; RecordId) { }
        field(19; F18; DateFormula) { }
        field(20; F19; Text[250]) { }
        field(21; F20; Code[10]) { }
        field(22; F21; Text[2048]) { }
        field(23; F22; Text[1]) { }
        field(24; F23; TableFilter) { }
        field(25; F24; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Probe Len Table");
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68882 "Probe Field Len Feature Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure FieldLen_OfEveryType()
    var
        FieldRec: Record Field;
        Lens: Text;
    begin
        FieldRec.SetRange(TableNo, Database::"Probe Len Table");
        FieldRec.FindSet();
        repeat
            Lens += FieldRec.FieldName + ':' + Format(FieldRec.Type) + ':' + Format(FieldRec.Len) + ' ';
        until FieldRec.Next() = 0;

        Assert.AreEqual(
            'Id:Integer:4 F1:Text:30 F2:Code:20 F3:Integer:4 F4:BigInteger:8 F5:Decimal:12 F6:Boolean:4 F7:Date:4 F8:Time:4 ' +
            'F9:DateTime:8 F10:Duration:8 F11:GUID:16 F12:Option:4 F13:Option:4 F14:BLOB:8 F15:Media:16 F16:MediaSet:16 ' +
            'F17:RecordID:448 F18:DateFormula:32 F19:Text:250 F20:Code:10 F21:Text:2048 F22:Text:1 F23:TableFilter:504 ' +
            'F24:Integer:4 $systemId:GUID:16 SystemCreatedAt:DateTime:8 SystemCreatedBy:GUID:16 SystemModifiedAt:DateTime:8 ' +
            'SystemModifiedBy:GUID:16 ',
            Lens, 'name, type and length per field');
    end;

#if not BC28PLUS
    [Test]
    procedure FeatureKey_Columns_AndRows_OfThe27Platform()
    var
        FieldRec: Record Field;
        FeatureKey: Record "Feature Key";
        Columns: Text;
        Rows: Text;
    begin
        FieldRec.SetRange(TableNo, Database::"Feature Key");
        FieldRec.FindSet();
        repeat
            Columns += Format(FieldRec."No.") + '=' + FieldRec.FieldName + '(' + Format(FieldRec.Type) + ') ';
        until FieldRec.Next() = 0;
        Assert.AreEqual(
            '1=ID(Text) 2=Enabled(Option) 3=Description(Text) 4=Learn More Link(Text) 5=Mandatory By(Text) 6=Can Try(Boolean) ' +
            '7=Is One Way(Boolean) 8=Data Update Required(Boolean) 9=Mandatory By Version(Text) 10=Description In English(Text) ' +
            '2000000000=$systemId(GUID) 2000000001=SystemCreatedAt(DateTime) 2000000002=SystemCreatedBy(GUID) ' +
            '2000000003=SystemModifiedAt(DateTime) 2000000004=SystemModifiedBy(GUID) ',
            Columns, 'columns');

        Assert.AreEqual(16, FeatureKey.Count(), 'row count');
        FeatureKey.FindSet();
        repeat
            Rows += FeatureKey.ID + ':' + Format(FeatureKey."Data Update Required") + ' ';
        until FeatureKey.Next() = 0;
        Assert.AreEqual(
            'AdvancedTellMe:No CalcOnlyVisibleFlowFields:No ConcealedMaskType:No ' +
            'ConcurrentInventoryPosting:No ConcurrentJobPosting:No ConcurrentResourcePosting:No ' +
            'DisableSoapWebServicesOnMicrosoftUIPages:No EnableMcpAccess:No FinancialReportDefaults:No ' +
            'FullTextSearch:No GLCurrencyRevaluation:Yes Manufacturing_FlushingMethod_ActivateManualWoPick:Yes ' +
            'ReminderTermsCommunicationTexts:No SalesPrices:Yes SaveValueToDatabasePromptly:No ' +
            'SemanticMetadataSearch:No ',
            Rows, 'rows');
    end;
#endif
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-truncate-method
// Scope: in-scope
// Fixtures used: CFM Header (60441), CFM Line (60440), CFV Header (60941), ALT Parent (60004),
//                ALT Child (60005), ALT Media (60010), ALT Universal (60000), AutoInc Unique Probe (67823),
//                AutoInc Edge Composite (67834), shared Assert (60021); self-contained tables 68159, 68160
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins: the full text and code of the CalcFields errors (type mismatch, not a FlowField, recursion),
// that Average into an Integer FlowField truncates toward zero, that Lookup reads the first row in
// primary key order, that a FlowField on a temporary record reads the persistent source, that the
// SetAutoCalcFields list survives Reset and Clear, which rows Truncate removes with a filter and the
// text of its refusals, and the unique-index and AutoIncrement error texts and codes.
// BC versions: 27.5

table 68159 "Probe Captioned Table"
{
    Caption = 'Captioned Table';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'The Id'; }
        field(2; Plain; Integer) { Caption = 'Plain Cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68160 "Probe Truncate Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68158 "Probe CalcFields Truncate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Commit();
    end;

    local procedure SeedQuantities(Q1: Integer; Q2: Integer; Q3: Integer; Q4: Integer; Count: Integer)
    var
        CfmLine: Record "CFM Line";
        CfmHeader: Record "CFM Header";
        Index: Integer;
        Quantity: Integer;
    begin
        CfmLine.DeleteAll();
        CfmHeader.DeleteAll();
        CfmHeader.Init();
        CfmHeader."No." := 'P1';
        CfmHeader.Insert();
        for Index := 1 to Count do begin
            case Index of
                1:
                    Quantity := Q1;
                2:
                    Quantity := Q2;
                3:
                    Quantity := Q3;
                4:
                    Quantity := Q4;
            end;
            CfmLine.Init();
            CfmLine."Entry No." := Index;
            CfmLine."Doc No." := 'P1';
            CfmLine.Quantity := Quantity;
            CfmLine.Amount := Quantity;
            CfmLine.Insert();
        end;
        Commit();
    end;

    local procedure AverageQuantity(Q1: Integer; Q2: Integer; Q3: Integer; Q4: Integer; Count: Integer): Integer
    var
        CfmHeader: Record "CFM Header";
    begin
        SeedQuantities(Q1, Q2, Q3, Q4, Count);
        CfmHeader.Get('P1');
        CfmHeader.CalcFields("Average Quantity Int");
        exit(CfmHeader."Average Quantity Int");
    end;

    [Test]
    procedure CalcFields_AverageIntoIntegerFlowField_TruncatesTowardZero()
    begin
        Initialize();

        Assert.AreEqual(1, AverageQuantity(1, 2, 0, 0, 2), '1.5');
        Assert.AreEqual(2, AverageQuantity(2, 3, 0, 0, 2), '2.5');
        Assert.AreEqual(1, AverageQuantity(1, 1, 1, 2, 4), '1.25');
        Assert.AreEqual(1, AverageQuantity(1, 2, 2, 0, 3), '1.67');
        Assert.AreEqual(-1, AverageQuantity(-1, -2, 0, 0, 2), '-1.5');
        Assert.AreEqual(-2, AverageQuantity(-2, -3, 0, 0, 2), '-2.5');
        Assert.AreEqual(-1, AverageQuantity(-1, -2, -2, 0, 3), '-1.67');
    end;

    [Test]
    procedure CalcFields_TypeMismatch_FullTextAndCode()
    var
        CfmHeader: Record "CFM Header";
        Expected: Text;
    begin
        Initialize();
        SeedQuantities(1, 2, 0, 0, 2);
        CfmHeader.Get('P1');

        asserterror CfmHeader.CalcFields("Bad Sum Qty Decimal");

        Expected := 'The following fields must have the same type:' + '\' + '\' +
            'Field: Bad Sum Qty Decimal <-- Quantity' + '\' +
            'Table: CFM Header <-- CFM Line' + '\' +
            'Type: Decimal <-- Integer';
        Assert.AreEqual(Expected, GetLastErrorText(), 'text: each line break is a carriage return followed by a backslash');
        Assert.AreEqual('DB:TypeMisMatch', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure CalcFields_OnANormalField_UsesTheFieldAndTableCaptions_CodeDbOk()
    var
        CfmHeader: Record "CFM Header";
        Captioned: Record "Probe Captioned Table";
    begin
        Initialize();
        SeedQuantities(1, 2, 0, 0, 2);
        CfmHeader.Get('P1');

        asserterror CfmHeader.CalcFields("No.");
        Assert.AreEqual('The No. field in the CFM Header table must be a FlowField.', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'code');

        Captioned.DeleteAll();
        Captioned.Id := 1;
        Captioned.Insert();
        Commit();
        asserterror Captioned.CalcFields(Plain);
        Assert.AreEqual('The Plain Cap field in the Captioned Table table must be a FlowField.', GetLastErrorText(), 'the field caption and the table caption, not the names');
    end;

    [Test]
    procedure CalcFields_SelfReferencingFormula_FullTextAndCode()
    // CLAIM: the recursion is reported as the stack overflow text with code StackOverflow.
    var
        CfvHeader: Record "CFV Header";
    begin
        Initialize();
        CfvHeader.DeleteAll();
        CfvHeader.Init();
        CfvHeader."No." := 'D1';
        CfvHeader.Insert();
        Commit();

        asserterror CfvHeader.CalcFields("Self Ref Amount");

        Assert.AreEqual('There is insufficient memory to execute this function. This can be caused by recursive function calls. Contact your system administrator.', GetLastErrorText(), 'text');
        Assert.AreEqual('StackOverflow', GetLastErrorCode(), 'code');
    end;

    local procedure SeedParent()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        AltChild.DeleteAll();
        AltParent.DeleteAll();
        AltParent.Init();
        AltParent."Entry No." := 1;
        AltParent.Code := 'P';
        AltParent.Insert();
        AltChild.Init();
        AltChild."Entry No." := 5;
        AltChild."Parent Entry No." := 1;
        AltChild.Code := 'AA';
        AltChild.Insert();
        AltChild.Init();
        AltChild."Entry No." := 2;
        AltChild."Parent Entry No." := 1;
        AltChild.Code := 'ZZ';
        AltChild.Insert();
        AltChild.Init();
        AltChild."Entry No." := 9;
        AltChild."Parent Entry No." := 1;
        AltChild.Code := 'MM';
        AltChild.Insert();
        Commit();
    end;

    [Test]
    procedure CalcFields_Lookup_OverSeveralRows_ReadsTheFirstInPrimaryKeyOrder()
    // CLAIM: the child with the lowest primary key (2 = ZZ) wins, not the lowest code (AA) and not the first inserted (5).
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        SeedParent();

        AltParent.Get(1);
        AltParent.CalcFields("First Child Code");

        Assert.AreEqual('ZZ', AltParent."First Child Code", 'lookup');
    end;

    [Test]
    procedure CalcFields_OnATemporaryRecord_ReadsThePersistentSourceTable()
    var
        TempParent: Record "ALT Parent" temporary;
    begin
        Initialize();
        SeedParent();

        TempParent.Init();
        TempParent."Entry No." := 1;
        TempParent.Insert();
        TempParent.CalcFields("Child Count");

        Assert.AreEqual(3, TempParent."Child Count", 'the three real child rows');
    end;

    [Test]
    procedure SetAutoCalcFields_SurvivesResetAndClear()
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        SeedParent();

        AltParent.Get(1);
        Assert.AreEqual(0, AltParent."Child Count", 'control: Get without SetAutoCalcFields does not calculate');

        AltParent.SetAutoCalcFields("Child Count");
        AltParent.Get(1);
        Assert.AreEqual(3, AltParent."Child Count", 'after SetAutoCalcFields');

        AltParent.Reset();
        AltParent.Get(1);
        Assert.AreEqual(3, AltParent."Child Count", 'after Reset');

        Clear(AltParent);
        AltParent.Get(1);
        Assert.AreEqual(3, AltParent."Child Count", 'after Clear');
    end;

    [Test]
    procedure Truncate_WithFilterOnANormalField_RemovesOnlyTheFilteredRows()
    var
        TruncateRow: Record "Probe Truncate Row";
    begin
        Initialize();
        TruncateRow.DeleteAll();
        TruncateRow.Id := 1;
        TruncateRow.Txt := 'a';
        TruncateRow.Insert();
        TruncateRow.Id := 2;
        TruncateRow.Txt := 'b';
        TruncateRow.Insert();
        TruncateRow.Id := 3;
        TruncateRow.Txt := 'a';
        TruncateRow.Insert();
        Commit();

        TruncateRow.SetRange(Txt, 'a');
        TruncateRow.Truncate();

        TruncateRow.Reset();
        Assert.AreEqual(1, TruncateRow.Count(), 'one row is left');
        Assert.IsTrue(TruncateRow.Get(2), 'the unfiltered row');
    end;

    [Test]
    procedure Truncate_Refusals_Texts()
    var
        TempRow: Record "Probe Truncate Row" temporary;
        AltMedia: Record "ALT Media";
        AllObjects: Record AllObj;
    begin
        Initialize();
        TempRow.Id := 1;
        TempRow.Insert();

        asserterror TempRow.Truncate();
        Assert.AreEqual('Temporary tables does not support truncation.', GetLastErrorText(), 'temporary');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'code');

        asserterror AltMedia.Truncate();
        Assert.AreEqual('Truncate is not supported when the field has Media and/or MediaSet fields.', GetLastErrorText(), 'Media fields');

        asserterror AllObjects.Truncate();
        Assert.AreEqual('The table does not support truncation.', GetLastErrorText(), 'virtual table');
    end;

    [Test]
    procedure UniqueIndex_Violation_FullTextAndCode_PrimaryKeyIsReportedFirst()
    var
        UniqueProbe: Record "AutoInc Unique Probe";
        FirstKey: Integer;
        SecondKey: Integer;
    begin
        Initialize();
        UniqueProbe.DeleteAll();
        UniqueProbe.Code := 'X';
        UniqueProbe.Insert(true);
        FirstKey := UniqueProbe."Entry No.";
        Clear(UniqueProbe);
        UniqueProbe.Code := 'Y';
        UniqueProbe.Insert(true);
        SecondKey := UniqueProbe."Entry No.";
        Commit();

        Clear(UniqueProbe);
        UniqueProbe.Code := 'X';
        asserterror UniqueProbe.Insert(true);
        Assert.AreEqual('There is already a record in table AutoInc Unique Probe that has the same values in a unique index for the following fields: Code=''X''', GetLastErrorText(), 'Insert');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');

        Clear(UniqueProbe);
        UniqueProbe.Get(SecondKey);
        UniqueProbe.Code := 'X';
        asserterror UniqueProbe.Modify();
        Assert.AreEqual('There is already a record in table AutoInc Unique Probe that has the same values in a unique index for the following fields: Code=''X''', GetLastErrorText(), 'Modify');

        Clear(UniqueProbe);
        UniqueProbe."Entry No." := SecondKey;
        UniqueProbe.Code := 'X';
        asserterror UniqueProbe.Insert();
        Assert.AreEqual('The record in table AutoInc Unique Probe already exists. Identification fields and values: Entry No.=''' + Format(SecondKey) + '''', GetLastErrorText(), 'a duplicate primary key is reported before the unique key');
        Assert.AreNotEqual(FirstKey, SecondKey, 'two rows');
    end;

    [Test]
    procedure AutoIncrement_Rename_FullTextAndCode()
    var
        EdgeComposite: Record "AutoInc Edge Composite";
        Cr: Text[1];
        KeyValue: Integer;
        Expected: Text;
    begin
        Initialize();
        Cr[1] := 13;
        EdgeComposite.DeleteAll();
        EdgeComposite.Code := 'A';
        EdgeComposite.Insert(true);
        KeyValue := EdgeComposite."Entry No.";
        EdgeComposite.Get(KeyValue, 'A');
        Commit();

        asserterror EdgeComposite.Rename(KeyValue + 50, 'A');

        Expected := 'You cannot change the value of an AutoIncrement field.' + Cr + '\' + Cr + '\' +
            'Field: Entry No.' + Cr + '\' +
            'Table: AutoInc Edge Composite' + Cr + '\' + Cr + '\' +
            'Identification fields and values:' + Cr + '\' +
            'Entry No.=''' + Format(KeyValue + 50) + ''',Code=''A''';
        Assert.AreEqual(Expected, GetLastErrorText(), 'text (the key shown is the new one)');
        Assert.AreEqual('DB:ModifyOnIdentityField', GetLastErrorCode(), 'code');
    end;
}

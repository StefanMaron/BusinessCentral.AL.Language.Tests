// FieldRef.Relation and Validate on fields that are not FieldClass = Normal.
//
// A FlowFilter or FlowField that declares a TableRelation keeps that relation in its metadata.
// FieldRef.Relation answers it the same way it does for a Normal field, including picking the
// arm of a conditional relation from the current record, and Validate checks it unless the
// field says ValidateTableRelation = false.
//
// The first half uses the fixture table ALTRelationFieldClass.al. The second half asks the same
// questions of Base Application fields, which this app does not compile, so they reach the
// runner's metadata by a different route than the fixture does.
//
// The last two tests are regression coverage for conditional relations on Base Application
// Normal fields whose discriminator is an Enum or an Option; they are not about field class.
//
// Every expected value is a concrete table id or 0, never "non-zero".

codeunit 60483 "Test Relation Field Class"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure FieldRef_Relation_FlowFilter_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Field Class");

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", RecRef.Field(3).Relation(),
            'a FlowFilter declaring TableRelation = "ALT Rel Where Parent"."Code" must answer 60480');
    end;

    [Test]
    procedure FieldRef_Relation_FlowFilterWithoutTableRelation_ReturnsZero()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Field Class");

        Assert.AreEqual(
            0, RecRef.Field(7).Relation(),
            'a FlowFilter declaring no TableRelation must answer 0');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalFlowFilter_SelectsTheIfArm()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Field Class");
        RecRef.Field(2).Value := 0; // Kind::A

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", RecRef.Field(4).Relation(),
            'with Kind = A the if() arm of the FlowFilter''s relation applies (60480)');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalFlowFilter_SelectsTheElseArm()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Field Class");
        RecRef.Field(2).Value := 1; // Kind::B

        Assert.AreEqual(
            Database::"ALT Relation Parent B", RecRef.Field(4).Relation(),
            'with Kind = B the else arm of the FlowFilter''s relation applies (60030)');
    end;

    [Test]
    procedure FieldRef_Relation_FlowField_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Field Class");

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", RecRef.Field(6).Relation(),
            'a FlowField declaring TableRelation = "ALT Rel Where Parent"."Code" must answer 60480');
    end;

    [Test]
    procedure Validate_FlowFilter_UnknownValue_IsRefused()
    var
        Rec: Record "ALT Rel Field Class";
    begin
        Initialize();

        asserterror Rec.Validate("Filter Ref", 'NO-SUCH-PARENT');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure Validate_FlowFilter_KnownValue_IsAccepted()
    var
        Parent: Record "ALT Rel Where Parent";
        Rec: Record "ALT Rel Field Class";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-KNOWN';
        Parent.Insert();

        // The positive direction of the test above: a check that refused every value would
        // pass that one and fail this one.
        Rec.Validate("Filter Ref", 'P-KNOWN');

        Assert.AreEqual('P-KNOWN', Rec."Filter Ref", 'an existing parent code must be accepted');
    end;

    [Test]
    procedure Validate_FlowFilterWithValidateTableRelationFalse_AcceptsUnknownValue()
    var
        Rec: Record "ALT Rel Field Class";
    begin
        Initialize();

        // Same relation and same value as Validate_FlowFilter_UnknownValue_IsRefused; only
        // ValidateTableRelation differs.
        Rec.Validate("Filter Ref No Validate", 'NO-SUCH-PARENT');

        Assert.AreEqual('NO-SUCH-PARENT', Rec."Filter Ref No Validate",
            'ValidateTableRelation = false must leave an unknown value in place');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFlowFilter_ReturnsRelatedTableId()
    var
        AnalysisLine: Record "Analysis Line";
        RecRef: RecordRef;
    begin
        Initialize();

        // "Analysis Line"."Location Filter": FieldClass = FlowFilter, TableRelation = Location.
        RecRef.Open(Database::"Analysis Line");

        Assert.AreEqual(
            Database::Location, RecRef.Field(AnalysisLine.FieldNo("Location Filter")).Relation(),
            'Analysis Line."Location Filter" must answer Location (14)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationConditionalFlowFilter_SelectsCustomerArm()
    var
        AnalysisLine: Record "Analysis Line";
        RecRef: RecordRef;
    begin
        Initialize();

        // "Analysis Line"."Source No. Filter", a FlowFilter:
        //   if ("Source Type Filter" = const(Customer)) Customer
        //   else if ("Source Type Filter" = const(Vendor)) Vendor
        //   else if ("Source Type Filter" = const(Item)) Item
        // and "Source Type Filter" is itself a FlowFilter of Enum "Analysis Source Type".
        AnalysisLine."Source Type Filter" := AnalysisLine."Source Type Filter"::Customer;
        RecRef.GetTable(AnalysisLine);

        Assert.AreEqual(
            Database::Customer, RecRef.Field(AnalysisLine.FieldNo("Source No. Filter")).Relation(),
            'with Source Type Filter = Customer, "Source No. Filter" must answer Customer (18)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationConditionalFlowFilter_SelectsItemArm()
    var
        AnalysisLine: Record "Analysis Line";
        RecRef: RecordRef;
    begin
        Initialize();

        // Same field as the test above, the third arm, so an answer fixed to one arm fails one
        // of the two.
        AnalysisLine."Source Type Filter" := AnalysisLine."Source Type Filter"::Item;
        RecRef.GetTable(AnalysisLine);

        Assert.AreEqual(
            Database::Item, RecRef.Field(AnalysisLine.FieldNo("Source No. Filter")).Relation(),
            'with Source Type Filter = Item, "Source No. Filter" must answer Item (27)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFlowField_ReturnsRelatedTableId()
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        Initialize();

        // "G/L Entry"."Account Id": FieldClass = FlowField, TableRelation = "G/L Account".SystemId.
        RecRef.Open(Database::"G/L Entry");

        Assert.AreEqual(
            Database::"G/L Account", RecRef.Field(GLEntry.FieldNo("Account Id")).Relation(),
            'G/L Entry."Account Id" must answer G/L Account (15)');
    end;

    [Test]
    procedure Relation_BaseApplicationEnumDiscriminator_ArmOrderIsNotOrdinalOrder()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // "Gen. Journal Line"."Account No." has eight arms on Enum "Gen. Journal Account Type".
        // The arm for "Allocation Account" (ordinal 10) is written BEFORE the arm for Employee
        // (ordinal 6), so matching an arm by position or by ordinal gives a different table
        // than matching it by value.
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        Assert.AreEqual(Database::Employee, GenJnlLine.Relation(GenJnlLine."Account No."),
            'Account Type = Employee must answer Employee (5200)');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Allocation Account";
        Assert.AreEqual(Database::"Allocation Account", GenJnlLine.Relation(GenJnlLine."Account No."),
            'Account Type = Allocation Account must answer Allocation Account');

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"IC Partner";
        Assert.AreEqual(Database::"IC Partner", GenJnlLine.Relation(GenJnlLine."Account No."),
            'Account Type = IC Partner must answer IC Partner (413)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationOptionDiscriminator_MemberWithNoArmReturnsZero()
    var
        SalesLineDisc: Record "Sales Line Discount";
        RecRef: RecordRef;
    begin
        Initialize();

        // "Sales Line Discount"."Sales Code" on Option "Sales Type"
        // (Customer, Customer Disc. Group, All Customers, Campaign):
        //   if (const("Customer Disc. Group")) "Customer Discount Group"
        //   else if (const(Customer)) Customer
        //   else if (const(Campaign)) Campaign
        // The arms are not in option order, and "All Customers" has no arm at all.
        SalesLineDisc."Sales Type" := SalesLineDisc."Sales Type"::"Customer Disc. Group";
        RecRef.GetTable(SalesLineDisc);
        Assert.AreEqual(Database::"Customer Discount Group",
            RecRef.Field(SalesLineDisc.FieldNo("Sales Code")).Relation(),
            'Sales Type = Customer Disc. Group must answer Customer Discount Group (340)');

        SalesLineDisc."Sales Type" := SalesLineDisc."Sales Type"::"All Customers";
        RecRef.GetTable(SalesLineDisc);
        Assert.AreEqual(0, RecRef.Field(SalesLineDisc.FieldNo("Sales Code")).Relation(),
            'Sales Type = All Customers matches no arm, so Relation must answer 0');
    end;
}

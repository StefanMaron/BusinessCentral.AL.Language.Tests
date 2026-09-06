// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope, but ONLY for a Target = OnPrem app - see the header note below
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHY THIS FILE IS IN THE ONPREM APP AND NOT THE CLOUD ONE
//   Microsoft declares "Object" (2000000001) Scope = OnPrem in System.app, so a Target = Cloud
//   app cannot name the record type at all - the compiler rejects it with
//
//     error AL0296: The application object or method 'Object' has scope 'OnPrem' and cannot
//                   be used for 'Cloud' development
//
//   and the RecordRef way round is refused at runtime too, because 2000000001 sits in
//   SystemTables.InternalTables. Both refusals are decided by the CALLING APP'S COMPILATION
//   TARGET and by nothing else - NavRecordRef.IsOpenAllowed reads, in full:
//
//       private bool IsOpenAllowed(CompilationTarget compilationTarget, int tableId)
//       {
//           if (!compilationTarget.IsOnPremTarget())
//               return IsSystemTableAllowedForRecordRefUsage(tableId);
//           return true;
//       }
//
//   so the InternalTables membership test is never reached for an OnPrem target, and an
//   OnPrem app needs no RecordRef here anyway: it can declare `Record "Object"` directly.
//
//   That distinction is the reason this file exists. Corpus PR #153 put the SIBLING id
//   2000000071 in front of a tier from the Cloud app and was withdrawn after all 8 BC legs of
//   run 33968379281 refused it before a single assertion ran. 2000000001 was then treated as
//   settled by MEMBERSHIP IN THE SAME FrozenSet rather than by its own measurement - a
//   reasonable inference, but an inference. These tests replace it with a measurement.
//
// WHAT THIS TABLE IS, AND WHAT IS ACTUALLY BEING ASKED
//   System.app calls 2000000001 the "legacy object metadata storage system superseded by
//   Application Object Metadata table", declares it ObsoleteState = Pending, and keys it on
//   Type + "Company Name" + ID. It is not a virtual table: it is one of the ids on
//   SystemTables.ApplicationDatabaseTables, so it has a real SQL schema in the application
//   database - which TestObjectMetadataSystemTable already pins from the other side, since
//   "Object Metadata" carries a row for 2000000001 itself.
//
//   Having a schema is not the same as having rows, and THAT is the open question. The classic
//   object registry this table served was written by a development environment that no longer
//   exists; the modern publish path writes "Object Metadata" (2000000071) and "Application
//   Object Metadata" (2000000207) instead. Nothing in the shipped runtime assemblies was found
//   writing 2000000001. So the expectation under test is that the table is present, readable,
//   and EMPTY - and the point of asking a tier is that "nothing appears to write it" is a
//   reading of Microsoft's code, not a fact about a running system.
//
//   Every test below is anchored so that "empty" cannot be confused with "unreadable": the
//   centerpiece carries a CONTROL ARM reading the sibling table in the same session, and the
//   per-object probes name objects this repository itself publishes rather than depending on
//   which Microsoft apps a particular tier happens to carry.

codeunit 61202 "Test Object Sys Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Object_Get_UnknownKey_RaisesRecordNotFound()
    // CLAIM: an OnPrem app can name, open and query 2000000001 - the whole refusal that
    // withdrew corpus PR #153 is about the caller's target, not about this id - and Get
    // SELECTS rather than inventing a row for a key nobody registered.
    //
    // 61299 is deliberately the last id of this app's own 61200-61299 range and is
    // deliberately unused, so it names nothing under either possible answer to the row-set
    // question below. DO NOT ADD AN OBJECT 61299 WITHOUT CHANGING THIS TEST.
    var
        Obj: Record "Object";
    begin
        Initialize();

        asserterror Obj.Get(Obj.Type::Codeunit, '', 61299);
        Assert.ExpectedErrorCannotFind(Database::"Object");
    end;

    [Test]
    procedure Object_HoldsNoRows_WhileObjectMetadataDoes()
    // CLAIM: on a modern tier the legacy object registry is EMPTY. Its schema exists, it can
    // be read, and there is nothing in it.
    //
    // THE CONTROL ARM IS THE POINT. A test that only asserted Count = 0 would pass just as
    // happily against a read that silently returned nothing at all, which is the failure mode
    // an obsolete OnPrem system table is most likely to have. So the sibling application-
    // database table is read FIRST, in the same session, from the same app: "Object Metadata"
    // is populated on a real tier - TestObjectMetadataSystemTable pins its row set exactly -
    // so if that read produces rows and this one produces none, the emptiness is an answer
    // rather than an artifact.
    var
        Obj: Record "Object";
        ObjectMetadata: Record "Object Metadata";
        ObjectRows: Integer;
    begin
        Initialize();

        // Control: the read path from this app to the application-database system tables works.
        Assert.IsTrue(
            not ObjectMetadata.IsEmpty(),
            'CONTROL ARM: Object Metadata must be populated, otherwise an empty Object proves nothing.');

        ObjectRows := Obj.Count();
        Assert.AreEqual(
            0, ObjectRows,
            StrSubstNo(
                'The legacy Object registry must hold no rows on a modern tier; found %1.',
                ObjectRows));
    end;

    [Test]
    procedure Object_HasNoRowForAnyObjectThisRepositoryPublishes()
    // CLAIM: the tier-INDEPENDENT half of the test above, and the one that stays meaningful
    // even if some tier is ever found carrying legacy rows. No object either of this
    // repository's two apps publishes appears in the table - under ANY Type and ANY company,
    // which is why each probe filters on ID alone rather than using the three-part key.
    //
    // Named objects rather than a global count, so this cannot be satisfied by a tier that
    // happens to carry unrelated historical rows.
    var
        Obj: Record "Object";
    begin
        Initialize();

        // This codeunit, in the OnPrem app - published moments before this line ran.
        AssertNoRowForId(61202, 'this test codeunit');
        // A table published by the Cloud coverage app this one depends on.
        AssertNoRowForId(60000, 'ALT Universal, a table the Cloud coverage app publishes');
        // A Base Application table, so the claim is not only about this repository's ids.
        AssertNoRowForId(18, 'Customer, a Base Application table');
    end;

    [Test]
    procedure ObjectMetadata_ObjectIdRelation_ResolvesToNoObjectRow()
    // CLAIM: "Object Metadata"."Object ID" declares
    //
    //     TableRelation = Object.ID WHERE(Type = FIELD("Object Type"))
    //
    // and on a real tier that relation resolves to NOTHING, because its target table is empty.
    // Microsoft has the accompanying `TestTableRelation = false;` line commented out with
    // "This property is currently not supported", so nothing raises - the relation is simply
    // never satisfiable.
    //
    // This is the assertion with the most consequence outside this file: any consumer that
    // treats the declared relation as evidence that Object is populated is reasoning from a
    // schema rather than from data. The row chosen is Object Metadata's own table id, which
    // TestObjectMetadataSystemTable proves exists, so the left-hand side of the join is real
    // and only the right-hand side is missing.
    var
        Obj: Record "Object";
        ObjectMetadata: Record "Object Metadata";
    begin
        Initialize();

        ObjectMetadata.SetRange("Object Type", ObjectMetadata."Object Type"::Table);
        ObjectMetadata.SetRange("Object ID", 2000000071);
        Assert.IsTrue(ObjectMetadata.FindFirst(), 'Object Metadata must have a row for its own table id.');

        // The exact lookup the declared relation describes: same ordinal for Type, same id.
        Assert.IsFalse(
            Obj.Get(ObjectMetadata."Object Type", '', ObjectMetadata."Object ID"),
            'The row Object Metadata''s declared TableRelation points at must not exist.');

        // ...and not under some other Type or company either.
        AssertNoRowForId(2000000071, 'Object Metadata, the id the declared relation points at');
    end;

    [Test]
    procedure Object_Type_OptionOrdinals_MatchMicrosoftsDeclaredPositions()
    // CLAIM: the Type option is
    //
    //     TableData,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System,FieldNumber
    //
    // - with two DELIBERATE GAPS, at ordinals 2 and 4. Those gaps are the whole reason this
    // test is worth its space: a consumer that resolves these by counting members left to
    // right, instead of by name, puts Report at 2 and Codeunit at 4 and files every object
    // under the wrong type. Nothing raises when that happens, because every value involved is
    // a valid ordinal of the option.
    //
    // This test needs no rows, so it is the one assertion here that is unaffected by whatever
    // answer the tier gives to the row-set question.
    var
        Obj: Record "Object";
        Ordinal: Integer;
    begin
        Initialize();

        Ordinal := Obj.Type::TableData;
        Assert.AreEqual(0, Ordinal, 'Type::TableData must be ordinal 0.');
        Ordinal := Obj.Type::Table;
        Assert.AreEqual(1, Ordinal, 'Type::Table must be ordinal 1.');
        Ordinal := Obj.Type::Report;
        Assert.AreEqual(3, Ordinal, 'Type::Report must be ordinal 3 - ordinal 2 is an unnamed gap.');
        Ordinal := Obj.Type::Codeunit;
        Assert.AreEqual(5, Ordinal, 'Type::Codeunit must be ordinal 5 - ordinal 4 is an unnamed gap.');
        Ordinal := Obj.Type::XMLport;
        Assert.AreEqual(6, Ordinal, 'Type::XMLport must be ordinal 6.');
        Ordinal := Obj.Type::MenuSuite;
        Assert.AreEqual(7, Ordinal, 'Type::MenuSuite must be ordinal 7.');
        Ordinal := Obj.Type::Page;
        Assert.AreEqual(8, Ordinal, 'Type::Page must be ordinal 8.');
        Ordinal := Obj.Type::Query;
        Assert.AreEqual(9, Ordinal, 'Type::Query must be ordinal 9.');
        Ordinal := Obj.Type::System;
        Assert.AreEqual(10, Ordinal, 'Type::System must be ordinal 10.');
        Ordinal := Obj.Type::FieldNumber;
        Assert.AreEqual(11, Ordinal, 'Type::FieldNumber must be ordinal 11.');
    end;

    [Test]
    procedure Object_Type_SharesItsOrdinalsWithObjectMetadataObjectType()
    // CLAIM: the two option strings agree on the prefix they share, which is what makes
    // "Object Metadata"."Object ID"'s WHERE(Type = FIELD("Object Type")) a coherent join in
    // the first place - it compares one option's value against the other's.
    //
    // "Object Metadata"."Object Type" carries the same twelve members and the same two gaps,
    // then extends the list with PageExtension at ordinal 14. So the agreement is real but
    // BOUNDED, and asserting the extension is what stops this test being read as "the two
    // options are the same option".
    var
        Obj: Record "Object";
        ObjectMetadata: Record "Object Metadata";
        ObjOrdinal: Integer;
        MetaOrdinal: Integer;
    begin
        Initialize();

        ObjOrdinal := Obj.Type::Table;
        MetaOrdinal := ObjectMetadata."Object Type"::Table;
        Assert.AreEqual(ObjOrdinal, MetaOrdinal, 'Table must have the same ordinal in both options.');

        ObjOrdinal := Obj.Type::Codeunit;
        MetaOrdinal := ObjectMetadata."Object Type"::Codeunit;
        Assert.AreEqual(ObjOrdinal, MetaOrdinal, 'Codeunit must have the same ordinal in both options.');

        ObjOrdinal := Obj.Type::FieldNumber;
        MetaOrdinal := ObjectMetadata."Object Type"::FieldNumber;
        Assert.AreEqual(ObjOrdinal, MetaOrdinal, 'FieldNumber, the last shared member, must agree too.');

        // The bound: Object Metadata names a member Object's option cannot, past the shared
        // prefix and past a further gap.
        MetaOrdinal := ObjectMetadata."Object Type"::PageExtension;
        Assert.AreEqual(14, MetaOrdinal, 'Object Metadata''s option extends to PageExtension at ordinal 14.');
    end;

    local procedure AssertNoRowForId(ObjectId: Integer; Description: Text)
    // Filters on ID alone: a row under any Type, and under any "Company Name", counts.
    var
        Obj: Record "Object";
        Found: Integer;
    begin
        Obj.SetRange(ID, ObjectId);
        Found := Obj.Count();
        Assert.AreEqual(
            0, Found,
            StrSubstNo('Object must hold no row for id %1 (%2); found %3.', ObjectId, Description, Found));
    end;

    local procedure Initialize()
    begin
        // "Object" is a read-only platform table in the application database, not written by
        // test code -- nothing to DeleteAll, and nothing this app is allowed to seed.
    end;
}

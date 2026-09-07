// Fixture for "a TableRelation declared by a tableextension IN SOURCE is enforced by Validate".
//
// The corpus already extends a Base Application table from source (TestPageCurrFieldNo_Ext.al
// extends Job) and already pins that a tableextension-contributed TableRelation is enforced
// (tableextension/TestTableExtFieldTableRelation.al). Neither covers this combination: that
// file's subject, Customer 5900 "Service Zone Code", is contributed by tableextension 6450
// "Serv. Customer" shipped INSIDE the Base Application package, so its relation is one this
// corpus never declares. Counted across every tableextension declared in this corpus's own AL
// -- 60024, 60025, 60205, 60390 -- exactly zero declare a TableRelation of any kind. So
// "a relation an extension declares here is enforced" was not pinned anywhere.
//
// Job is the base table for the same reason TestPageCurrFieldNo_Ext.al uses it: an
// always-available Base Application table with no involvement in the claim. The claim is about
// where the relation was DECLARED, not about Job.
//
// "ALT Relation Parent" (60028) is the related table, already in this corpus and already used
// by fieldref/TestFieldRefRelation.al, so the related side is a shape other tests pin too.
tableextension 60406 "ALT Src Ext Relation" extends Job
{
    fields
    {
        // The subject: a plain single-arm relation, declared by THIS extension, on a field
        // this extension adds. No OnValidate trigger and no ValidateTableRelation property, so
        // the relation check is the only thing in Validate that can raise on it.
        field(60406; "ALT Src Ext Rel Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "ALT Relation Parent"."Code";
        }

        // Control: same extension, same type, same length, NO TableRelation. This is what
        // makes the refusal above an assertion about the relation rather than about the field,
        // the value, or extension fields in general -- an implementation that refused every
        // value written to an extension field would fail the test that uses this one.
        field(60407; "ALT Src Ext No Rel"; Code[20])
        {
            DataClassification = CustomerContent;
        }
    }
}

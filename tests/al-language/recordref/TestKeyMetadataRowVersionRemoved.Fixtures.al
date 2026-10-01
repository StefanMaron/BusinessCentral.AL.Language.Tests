// Fixtures for TestKeyMetadataRowVersionRemoved.al (codeunit 68540).
//
// "KRV Row" declares, on one source table, every key shape the codeunit asks about:
// a key on SystemRowVersion, a key on SystemModifiedAt, a key on a live field, a key on an
// ObsoleteState = Pending field (itself Pending), and a key on an ObsoleteState = Removed
// field (itself Removed). Declaring a Removed field from scratch compiles cleanly; see
// record/TestFieldObsoleteStateFixture.Table.al.
//
// The two tableextensions put the same questions to precompiled Base Application tables:
// a key on SystemRowVersion over "Customer Bank Account", and over Item a live key plus a
// Removed key on a Removed field.
//
// Written by agent stma-auto-4 (AL Runner issues #5135, #5136).

table 68540 "KRV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Live Value"; Integer) { }
        field(3; "Pending Value"; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'pending in fixture';
            ObsoleteTag = '1.0';
        }
        field(4; "Removed Value"; Integer)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'removed in fixture';
            ObsoleteTag = '1.0';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(RowVersionKey; SystemRowVersion) { }
        key(ModifiedAtKey; SystemModifiedAt) { }
        key(PendingKey; "Pending Value")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'pending in fixture';
            ObsoleteTag = '1.0';
        }
        key(RemovedKey; "Removed Value")
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'removed in fixture';
            ObsoleteTag = '1.0';
        }
        key(LiveKey; "Live Value") { }
    }
}

tableextension 68540 "KRV Bank Account Ext" extends "Customer Bank Account"
{
    keys
    {
        key(KRVRowVersionKey; SystemRowVersion) { }
    }
}

tableextension 68541 "KRV Item Ext" extends Item
{
    fields
    {
        field(68540; "KRV Legacy Value"; Integer)
        {
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'removed in fixture';
            ObsoleteTag = '1.0';
        }
        field(68541; "KRV Live Value"; Integer)
        {
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(KRVLegacyKey; "KRV Legacy Value")
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'removed in fixture';
            ObsoleteTag = '1.0';
        }
        key(KRVLiveKey; "KRV Live Value") { }
    }
}

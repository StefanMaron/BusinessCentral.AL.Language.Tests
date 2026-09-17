// Fixture for "PCN Tests" (60535): what a [ModalPageHandler] saw in "PCN Line" (60534) at a
// chosen moment, read by the test AFTER the modal round trip has finished. The shape is
// "Opf Result" (60638)'s, and it is here for one arm only.
//
// The two-row discriminator asks whether Cancel keeps the part row that New() already committed.
// Without this witness a final count of 0 has two causes -- Cancel rolled a committed row back,
// or New() never committed the first row and Cancel dropped two pending ones -- and nothing in
// the fixture separates them. The handler records the count right after the second New(), which
// is the moment the first row is expected to have been committed, so a 0 leg is attributable.
table 60536 "PCN Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line Count"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

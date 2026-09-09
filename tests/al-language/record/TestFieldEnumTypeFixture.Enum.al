// Fixture for TestFieldEnumTypeVirtualTable.al.
//
// SPARSE and out-of-order ordinals on purpose: 0, 5, 10 rather than 0, 1, 2. A provider that
// treats an AL ordinal as a 0..Count-1 array index answers the wrong member for 5 and 10 while
// still being right about 0, so the ordinals are what separates a real lookup from an index.
// The middle member declares no Caption, so AL's own default (the member name) is what must
// appear for it.

enum 60469 "ALT Field Enum Kind"
{
    Extensible = false;
    Caption = 'ALT Field Enum Kind';

    value(0; Unassigned)
    {
        Caption = 'Not assigned';
    }
    value(5; Middle)
    {
    }
    value(10; "Far Out")
    {
        Caption = 'Far out value';
    }
}

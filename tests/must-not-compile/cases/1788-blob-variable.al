// @expect AL0157 | 'Blob' is not a valid variable type.
// Corpus issue 670 item 84 (Blob data type docs): a Blob exists only as a table field; a local or global variable of type Blob is refused,
// so only a Blob field value can go into a Variant (types/lt-variant-unsupported-kinds/VariantUnsupportedKinds.al:128 pins that).
codeunit 50788 "MNC C1788"
{
    procedure Probe()
    var
        B: Blob;
        V: Variant;
    begin
        V := B;
    end;
}

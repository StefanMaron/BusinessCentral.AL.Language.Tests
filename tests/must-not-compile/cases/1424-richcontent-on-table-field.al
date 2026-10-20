// @expect AL0800 | The field 'R' specifies ExtendedDataType 'RichContent'. This ExtendedDataType can only be set on a control.
// @expect AL0800 | The field 'B' specifies ExtendedDataType 'RichContent'. This ExtendedDataType can only be set on a control.
// @expect AL0844 | The property 'ExtendedDatatype' can only be used if the field's type is one of these values:
// ExtendedDatatype = RichContent on a Text table field (AL0800) and on a Blob table field (AL0800 and AL0844, a Blob takes no
// ExtendedDatatype). Corpus issue 664 item 106 (Learn: rich text content controls). Writer BO. (3 diagnostics)
table 51431 "MNC BO 1424"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; R; Text[2048]) { ExtendedDatatype = RichContent; }
        field(3; B; Blob) { ExtendedDatatype = RichContent; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

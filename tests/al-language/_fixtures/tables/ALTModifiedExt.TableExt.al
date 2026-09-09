// ALTModifiedExt: changes an existing field's Caption through modify(...), and adds a field
// alongside it.
//
// The two halves reach the built table by DIFFERENT routes in BC's own emitted metadata — an
// added field is folded into the base table's document, while a modify(...) change stays in
// this extension's own delta — so a fixture carrying only one of them cannot tell the two
// apart. Field 11 of the base table is deliberately NOT modified; it is the control.
//
// Caption is used because it is one of the few properties AL permits a table field's
// modify(...) to set at all (NotBlank, MinValue, MaxValue, Editable and most others are
// rejected with AL0246/AL0294 in this position) AND is readable from AL.
tableextension 60499 "ALT Modified Ext" extends "ALT Modified"
{
    fields
    {
        modify("Overridden Field")
        {
            Caption = 'Extension Overridden Caption';
        }
        field(50000; "Added Field"; Text[50])
        {
            Caption = 'Added Field Caption';
            DataClassification = SystemMetadata;
        }
    }
}

// @expect AL0175 | Operator '>' cannot be applied to operands of type 'PageStyle' and 'PageStyle'
// PageStyle is option-like: it supports = and <> but not an ordering operator. The same holds for HttpRequestType, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel.
codeunit 59105 "MNC PageStyle Gt 0989"
{
    procedure Run1(): Boolean
    var
        Style: PageStyle;
    begin
        exit(Style > PageStyle::None);
    end;
}

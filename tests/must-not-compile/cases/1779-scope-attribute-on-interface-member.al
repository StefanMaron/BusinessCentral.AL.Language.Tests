// @expect AL0187 | Attribute 'Scope' is valid only for normal methods.
// @expect AL0919 | The Scope attribute is not allowed on interface members.
// Corpus #670 item 68. [Scope('Cloud')] on an interface member gives AL0187 and AL0919 on BC 27, 28 and 29 (the same pair for
// [Scope('OnPrem')]).
interface "MNC CW I1779"
{
    [Scope('Cloud')]
    procedure Req(): Text;
}

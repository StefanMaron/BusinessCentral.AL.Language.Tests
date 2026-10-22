// @expect AL0185 | Interface 'Integer' is missing
// @expect AL0851 | The type 'NamedType' doesn't support casting.
// Corpus #664 item 19. 'as' with a target that is not an interface: AL0185 for a Variant source, AL0851 for a List source.
codeunit 51388 "MNC BM C1388"
{
    procedure P()
    var
        L: List of [Integer];
        V: Variant;
        i: Integer;
    begin
        i := V as Integer;
        i := L as Integer;
    end;
}

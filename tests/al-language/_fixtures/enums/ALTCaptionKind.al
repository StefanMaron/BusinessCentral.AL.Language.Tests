enum 60910 "ALT Caption Kind"
{
    Extensible = false;

    value(0; None)
    {
        Caption = 'None';
    }
    // Caption text deliberately differs in shape from the member name (spaces vs.
    // PascalCase run-together) so a runner that collapsed Caption to Name would produce
    // a visibly wrong, not merely differently-cased, string.
    value(1; ArchivedRecord)
    {
        Caption = 'Archived Item';
    }
    // No Caption property at all — proves the "no explicit Caption" fallback
    // (AL's documented default caption for an enum value is its member name).
    value(2; NoCaptionDeclared)
    {
    }
}

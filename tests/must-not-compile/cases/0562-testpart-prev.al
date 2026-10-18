// @expect AL0666 | 'Prev' is not available in runtime version '
// TestPart.Prev only exists in runtime versions 3.0 until 13.0 (Previous() is the method of runtime 16.0).
page 50562 "MNC O Sub List"
{
    PageType = ListPart;
    SourceTable = Integer;
    layout { area(Content) { repeater(R) { field(N; Rec.Number) { } } } }
}

page 50563 "MNC O Host"
{
    PageType = Card;
    layout { area(Content) { part(Lines; "MNC O Sub List") { } } }
}

codeunit 50562 "MNC O 0562"
{
    procedure Probe()
    var Pg: TestPage "MNC O Host";
    begin
        Pg.Lines.Prev();
    end;
}

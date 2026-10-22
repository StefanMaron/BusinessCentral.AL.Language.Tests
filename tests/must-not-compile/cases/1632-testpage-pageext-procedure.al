// @expect AL0132 | 'TestPage MNC CE Card 1632' does not contain a definition for 'ExtProc'
// A test codeunit names a procedure that a page extension adds, through a TestPage variable of the base page (microsoft/AL issue 7118).
table 51632 "MNC CE Row 1632"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51632 "MNC CE Card 1632"
{
    PageType = Card;
    SourceTable = "MNC CE Row 1632";
    layout { area(Content) { field(Id; Rec.Id) { } } }
    procedure BaseProc(): Integer
    begin
        exit(1);
    end;
}
pageextension 51632 "MNC CE Ext 1632" extends "MNC CE Card 1632"
{
    procedure ExtProc(): Integer
    begin
        exit(2);
    end;
}
codeunit 51632 "MNC CE Tests 1632"
{
    Subtype = Test;
    [Test]
    procedure CallExtProc()
    var
        Card: TestPage "MNC CE Card 1632";
        N: Integer;
    begin
        Card.OpenView();
        N := Card.ExtProc();
    end;
}

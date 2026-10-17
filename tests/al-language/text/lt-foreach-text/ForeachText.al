// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-foreach-statement
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71884
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: foreach over a Text value (the way Microsoft's System Application loops over a Text): the loop variable as Char, as Text[1],
//   over a Text variable, a Text constant and a Code variable; the visit order, the count, an empty text, and a surrogate pair.
//   Each visited character is recorded as its code (Format(Ch) is avoided so control characters stay readable).
// BC versions: 27, 28, 29
codeunit 71884 "LT Foreach Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TextConstant: Label 'x-y', Locked = true;

    local procedure CodesOf(T: Text): Text
    var
        Ch: Char;
        Count: Integer;
        Visited: Text;
    begin
        foreach Ch in T do begin
            Count += 1;
            Visited += Format(Ch) + ':' + Format(Ch + 0) + ' ';
        end;
        exit(Format(Count) + '|' + Visited);
    end;

    [Test]
    procedure Foreach_Text_Char_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('base64_chars', CodesOf('a+/=b'));
        Observer.Observe('empty', CodesOf(''));
        Observer.Observe('one', CodesOf('z'));
        Observer.Observe('blank_between', CodesOf('a  b'));
        Observer.Observe('trailing_blank', CodesOf('ab '));
        Observer.Observe('umlaut', CodesOf('a' + 'ä' + 'b'));
        Observer.Finish();
    end;

    [Test]
    procedure Foreach_Text_Char_Sources()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        TextVar: Text;
        CodeVar: Code[10];
        Text5: Text[5];
        Visited: Text;
    begin
        TextVar := 'a+/=b';
        foreach Ch in TextVar do
            Visited += Format(Ch);
        Observer.Observe('text_var', Visited);
        Visited := '';
        CodeVar := 'ab-c';
        foreach Ch in CodeVar do
            Visited += Format(Ch);
        Observer.Observe('code_var', Visited);
        Visited := '';
        Text5 := 'q w';
        foreach Ch in Text5 do
            Visited += Format(Ch);
        Observer.Observe('text5_var', Visited);
        Visited := '';
        foreach Ch in TextConstant do
            Visited += Format(Ch);
        Observer.Observe('text_constant', Visited);
        Observer.Finish();
    end;

    [Test]
    procedure Foreach_Text_Text1_Variable()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Text[1];
        Source: Text;
        Visited: Text;
        Count: Integer;
    begin
        Source := 'a+/=b';
        foreach Ch in Source do begin
            Visited += Ch + ',';
            Count += 1;
        end;
        Observer.Observe('text1_visited', Visited);
        Observer.Observe('text1_count', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure Foreach_Text_ModifyDuringLoop()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        T: Text;
        Visited: Text;
    begin
        T := 'abc';
        foreach Ch in T do begin
            Visited += Format(Ch);
            T := 'xyz123';
        end;
        Observer.Observe('visited', Visited);
        Observer.Observe('after', T);
        Observer.Finish();
    end;

    [Test]
    procedure Foreach_Text_SurrogatePair()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        T: Text;
        High: Text[1];
        Low: Text[1];
        Count: Integer;
        Codes: Text;
    begin
        High[1] := 55357;
        Low[1] := 56832;
        T := 'a' + High + Low + 'b';
        foreach Ch in T do begin
            Count += 1;
            Codes += Format(Ch + 0) + ' ';
        end;
        Observer.Observe('count', Format(Count));
        Observer.Observe('codes', Codes);
        Observer.Observe('strlen', Format(StrLen(T)));
        Observer.Finish();
    end;
}

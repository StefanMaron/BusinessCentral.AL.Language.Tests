// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: BigText.AddText with a position, GetSubText overloads, Length, TextPos
// BC versions: 29 (27 and 28 by CI)

codeunit 70324 "LT P93 BigText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var Big: BigText; S: Text; Pos: Integer)
    begin
        Big.AddText(S, Pos);
    end;

    [TryFunction]
    local procedure TryAddBig(var Big: BigText; Other: BigText; Pos: Integer)
    begin
        Big.AddText(Other, Pos);
    end;

    [TryFunction]
    local procedure TrySub(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean; var R: Text; var Ret: Integer)
    begin
        if WithLen then
            Ret := Big.GetSubText(R, Pos, Len)
        else
            Ret := Big.GetSubText(R, Pos);
    end;

    [TryFunction]
    local procedure TrySubBig(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean; var R: Text; var Ret: Integer)
    var
        Target: BigText;
    begin
        if WithLen then
            Ret := Big.GetSubText(Target, Pos, Len)
        else
            Ret := Big.GetSubText(Target, Pos);
        if Target.Length() > 0 then
            Target.GetSubText(R, 1);
    end;

    local procedure Content(Big: BigText): Text
    var
        T: Text;
    begin
        if Big.Length() = 0 then
            exit('');
        Big.GetSubText(T, 1);
        exit(T);
    end;

    local procedure Add(var Big: BigText; S: Text; Pos: Integer): Text
    begin
        if TryAdd(Big, S, Pos) then
            exit('ok len=' + Format(Big.Length()) + ' content=' + Content(Big));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' len=' + Format(Big.Length()));
    end;

    local procedure AddB(var Big: BigText; S: Text; Pos: Integer): Text
    var
        Other: BigText;
    begin
        Other.AddText(S);
        if TryAddBig(Big, Other, Pos) then
            exit('ok len=' + Format(Big.Length()) + ' content=' + Content(Big));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' len=' + Format(Big.Length()));
    end;

    local procedure Sub(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean): Text
    var
        R: Text;
        Ret: Integer;
    begin
        R := 'unset';
        if TrySub(Big, Pos, Len, WithLen, R, Ret) then
            exit('ret=' + Format(Ret) + ' text=[' + R + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SubB(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean): Text
    var
        R: Text;
        Ret: Integer;
    begin
        R := 'unset';
        if TrySubBig(Big, Pos, Len, WithLen, R, Ret) then
            exit('ret=' + Format(Ret) + ' text=[' + R + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Mk(S: Text): BigText
    var
        Big: BigText;
    begin
        Big.AddText(S);
        exit(Big);
    end;

    [Test]
    procedure AddText_Position_Text()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('start-empty', Add(Big, 'abc', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('start', Add(Big, 'XY', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('middle', Add(Big, 'XY', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('end', Add(Big, 'XY', 7));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('last-char', Add(Big, 'XY', 6));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('beyond', Add(Big, 'XY', 9));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('far-beyond', Add(Big, 'XY', 1000));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('zero', Add(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('negative', Add(Big, 'XY', -1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('empty-text', Add(Big, '', 3));
        Clear(Big);
        Observer.Observe('empty-big-beyond', Add(Big, 'XY', 5));
        Clear(Big);
        Observer.Observe('empty-big-zero', Add(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('repeat-1', Add(Big, 'XY', 3));
        Observer.Observe('repeat-2', Add(Big, 'Z', 3));
        Observer.Observe('repeat-end', Add(Big, 'E', Big.Length() + 1));
        Observer.Finish();
    end;

    [Test]
    procedure AddText_Position_Big()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('start-empty', AddB(Big, 'abc', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('start', AddB(Big, 'XY', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('middle', AddB(Big, 'XY', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('end', AddB(Big, 'XY', 7));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('beyond', AddB(Big, 'XY', 9));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('zero', AddB(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('negative', AddB(Big, 'XY', -1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('empty-other', AddB(Big, '', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Big.AddText(Big, 4);
        Observer.Observe('self-middle', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Observer.Finish();
    end;

    [Test]
    procedure AddText_NoPosition()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
        Other: BigText;
    begin
        Big.AddText('abc');
        Big.AddText('def');
        Observer.Observe('text-append', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Other.AddText('ghi');
        Big.AddText(Other);
        Observer.Observe('big-append', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Big.AddText('');
        Observer.Observe('empty-append', 'len=' + Format(Big.Length()));
        Big.AddText('jkl', 1);
        Observer.Observe('pos1', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Clear(Big);
        Observer.Observe('cleared-len', Format(Big.Length()));
        Big.AddText('ä€');
        Observer.Observe('unicode-len', Format(Big.Length()));
        Observer.Observe('unicode', Content(Big));
        Observer.Finish();
    end;

    [Test]
    procedure GetSubText_Text()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Big.AddText('abcdef');
        Observer.Observe('all', Sub(Big, 1, 0, false));
        Observer.Observe('from3', Sub(Big, 3, 0, false));
        Observer.Observe('last', Sub(Big, 6, 0, false));
        Observer.Observe('len-mid', Sub(Big, 2, 3, true));
        Observer.Observe('len-exact', Sub(Big, 4, 3, true));
        Observer.Observe('len-too-long', Sub(Big, 4, 10, true));
        Observer.Observe('len-zero', Sub(Big, 2, 0, true));
        Observer.Observe('len-negative', Sub(Big, 2, -1, true));
        Observer.Observe('pos-after-end', Sub(Big, 7, 0, false));
        Observer.Observe('pos-after-end-len', Sub(Big, 7, 1, true));
        Observer.Observe('pos-far', Sub(Big, 100, 1, true));
        Observer.Observe('pos-zero', Sub(Big, 0, 0, false));
        Observer.Observe('pos-zero-len', Sub(Big, 0, 2, true));
        Observer.Observe('pos-negative', Sub(Big, -1, 2, true));
        Observer.Observe('len-1', Sub(Big, 1, 1, true));
        Observer.Observe('empty-big', Sub(Mk(''), 1, 0, false));
        Observer.Observe('empty-big-len', Sub(Mk(''), 1, 3, true));
        Observer.Finish();
    end;

    [Test]
    procedure GetSubText_Big()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Big.AddText('abcdef');
        Observer.Observe('all', SubB(Big, 1, 0, false));
        Observer.Observe('from3', SubB(Big, 3, 0, false));
        Observer.Observe('len-mid', SubB(Big, 2, 3, true));
        Observer.Observe('len-too-long', SubB(Big, 4, 10, true));
        Observer.Observe('len-zero', SubB(Big, 2, 0, true));
        Observer.Observe('len-negative', SubB(Big, 2, -1, true));
        Observer.Observe('pos-after-end', SubB(Big, 7, 0, false));
        Observer.Observe('pos-far', SubB(Big, 100, 1, true));
        Observer.Observe('pos-zero', SubB(Big, 0, 0, false));
        Observer.Observe('pos-negative', SubB(Big, -1, 2, true));
        Observer.Observe('empty-big', SubB(Mk(''), 1, 0, false));
        Observer.Finish();
    end;

    [Test]
    procedure GetSubText_TargetOverwritten()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
        Target: BigText;
        T: Text;
        Ret: Integer;
    begin
        Big.AddText('abcdef');
        Target.AddText('old-content');
        Ret := Big.GetSubText(Target, 2, 2);
        Observer.Observe('big-target-ret', Format(Ret));
        Observer.Observe('big-target-len', Format(Target.Length()));
        Observer.Observe('big-target', Content(Target));
        T := 'old';
        Ret := Big.GetSubText(T, 2, 2);
        Observer.Observe('text-target-ret', Format(Ret));
        Observer.Observe('text-target', T);
        T := 'old';
        Ret := Big.GetSubText(T, 4, 0);
        Observer.Observe('text-len0-ret', Format(Ret));
        Observer.Observe('text-len0', '[' + T + ']');
        Observer.Finish();
    end;

    [Test]
    procedure LengthAndTextPos()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('len-empty', Format(Big.Length()));
        Big.AddText('Hello World Hello');
        Observer.Observe('len', Format(Big.Length()));
        Observer.Observe('pos-hello', Format(Big.TextPos('Hello')));
        Observer.Observe('pos-world', Format(Big.TextPos('World')));
        Observer.Observe('pos-lower', Format(Big.TextPos('hello')));
        Observer.Observe('pos-missing', Format(Big.TextPos('xyz')));
        Observer.Observe('pos-empty', Format(Big.TextPos('')));
        Observer.Observe('pos-space', Format(Big.TextPos(' ')));
        Observer.Observe('pos-whole', Format(Big.TextPos('Hello World Hello')));
        Observer.Observe('pos-longer', Format(Big.TextPos('Hello World Hello!')));
        Observer.Observe('pos-last-char', Format(Big.TextPos('o')));
        Big.AddText('XY', 1);
        Observer.Observe('len-after-insert', Format(Big.Length()));
        Observer.Observe('pos-after-insert', Format(Big.TextPos('Hello')));
        Observer.Observe('pos-inserted', Format(Big.TextPos('XY')));
        Observer.Finish();
    end;
}

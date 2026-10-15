//sub:types
// ReportLayoutType members and ordinals (md:967 of the batch list = line 966 of docs/probes-needed.md), and a for loop over a Boolean (md:980 = line 979).

codeunit 67768 "W3 Types Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Value: ReportLayoutType): Text
    begin
        exit('f0=' + Format(Value, 0, 0) + ' f1=' + Format(Value, 0, 1) + ' f2=' + Format(Value, 0, 2) + ' f9=' + Format(Value, 0, 9));
    end;

    [Test]
    procedure ReportLayoutType_MembersNamesAndOrdinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('RDLC', Forms(ReportLayoutType::RDLC));
        Observer.Observe('Word', Forms(ReportLayoutType::Word));
        Observer.Observe('Excel', Forms(ReportLayoutType::Excel));
        Observer.Observe('Custom', Forms(ReportLayoutType::Custom));
        Observer.Observe('default value', Forms(DefaultValue()));
        Observer.Expect('RDLC', 'f0=RDLC f1=RDLC f2=0 f9=0');
        Observer.Expect('Word', 'f0=Word f1=Word f2=1 f9=1');
        Observer.Expect('Excel', 'f0=Excel f1=Excel f2=2 f9=2');
        Observer.Expect('Custom', 'f0=Custom f1=Custom f2=3 f9=3');
        Observer.Expect('default value', 'f0=RDLC f1=RDLC f2=0 f9=0');
        Observer.Verify();
    end;

    local procedure DefaultValue() Result: ReportLayoutType
    begin
    end;

    [Test]
    procedure ReportLayoutType_EvaluateOrdinalsAndNames()
    var
        Observer: Codeunit "Probe Observer";
        Value: ReportLayoutType;
        I: Integer;
        Ok: Boolean;
        Names: Text;
    begin
        for I := 0 to 5 do begin
            Clear(Value);
            Ok := Evaluate(Value, Format(I));
            Names += Format(I) + '=' + Format(Ok) + ':' + Format(Value) + '|';
        end;
        Observer.Observe('ordinals', Names);
        Names := '';
        Ok := Evaluate(Value, 'Word');
        Names += 'Word=' + Format(Ok) + ':' + Format(Value) + '|';
        Ok := Evaluate(Value, 'Rdlc');
        Names += 'Rdlc=' + Format(Ok) + ':' + Format(Value) + '|';
        Ok := Evaluate(Value, 'RDLC');
        Names += 'RDLC=' + Format(Ok) + ':' + Format(Value) + '|';
        Ok := Evaluate(Value, 'custom');
        Names += 'custom=' + Format(Ok) + ':' + Format(Value) + '|';
        Ok := Evaluate(Value, 'Nothing');
        Names += 'Nothing=' + Format(Ok) + ':' + Format(Value) + '|';
        Observer.Observe('names', Names);
        Observer.Expect('ordinals', '0=Yes:RDLC|1=Yes:Word|2=Yes:Excel|3=Yes:Custom|4=No:RDLC|5=No:RDLC|');
        Observer.Expect('names', 'Word=Yes:Word|Rdlc=Yes:RDLC|RDLC=Yes:RDLC|custom=Yes:Custom|Nothing=No:Custom|');
        Observer.Verify();
    end;

    [Test]
    procedure ForBoolean_FalseToTrue()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Passes: Integer;
        Seen: Text;
    begin
        for B := false to true do begin
            Passes += 1;
            Seen += Format(B) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('values', Seen);
        Observer.Observe('value after the loop', Format(B));
        Observer.Expect('passes', '2');
        Observer.Expect('values', 'No,Yes,');
        Observer.Expect('value after the loop', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ForBoolean_TrueDowntoFalse()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Passes: Integer;
        Seen: Text;
    begin
        for B := true downto false do begin
            Passes += 1;
            Seen += Format(B) + ',';
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('values', Seen);
        Observer.Observe('value after the loop', Format(B));
        Observer.Expect('passes', '2');
        Observer.Expect('values', 'Yes,No,');
        Observer.Expect('value after the loop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ForBoolean_TrueToFalse_NoPass()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Passes: Integer;
    begin
        for B := true to false do
            Passes += 1;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('value after the loop', Format(B));
        Observer.Expect('passes', '0');
        Observer.Expect('value after the loop', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ForBoolean_FalseToFalse_OnePass()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Passes: Integer;
    begin
        for B := false to false do
            Passes += 1;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('value after the loop', Format(B));
        Observer.Expect('passes', '1');
        Observer.Expect('value after the loop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ForBoolean_ChangeTheCounterInsideTheLoop()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        Passes: Integer;
    begin
        for B := false to true do begin
            Passes += 1;
            if Passes > 5 then
                break;
            B := false;
        end;
        Observer.Observe('passes', Format(Passes));
        Observer.Observe('value after the loop', Format(B));
        Observer.Expect('passes', '2');
        Observer.Expect('value after the loop', 'No');
        Observer.Verify();
    end;
}

// Batch 7 probes: arrays of Option. Observe only.
codeunit 68558 "W7 Option Arrays"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionArray_UntouchedElementsAndMemberNames()
    var
        Observer: Codeunit "Probe Observer";
        Kinds: array[5] of Option "None",Released,FirmPlanned,Purchase;
        i: Integer;
    begin
        for i := 1 to 5 do
            Observer.Observe('untouched element ' + Format(i), Format(Kinds[i]) + ' | ' + Format(Kinds[i], 0, 9));
        Observer.Observe('array length', Format(ArrayLen(Kinds)));
        Observer.Observe('member Purchase', Format(Kinds[1]::Purchase));
        Observer.Observe('member FirmPlanned', Format(Kinds[2]::FirmPlanned));
        Observer.Observe('member Purchase as integer', Format(Kinds[1]::Purchase, 0, 9));
        Observer.Expect('untouched element 1', 'None | 0');
        Observer.Expect('untouched element 2', 'None | 0');
        Observer.Expect('untouched element 3', 'None | 0');
        Observer.Expect('untouched element 4', 'None | 0');
        Observer.Expect('untouched element 5', 'None | 0');
        Observer.Expect('array length', '5');
        Observer.Expect('member Purchase', 'Purchase');
        Observer.Expect('member FirmPlanned', 'FirmPlanned');
        Observer.Expect('member Purchase as integer', '3');
        Observer.Verify();
    end;

    [Test]
    procedure OptionArray_AssignmentAndComparison()
    var
        Observer: Codeunit "Probe Observer";
        Kinds: array[5] of Option "None",Released,FirmPlanned,Purchase;
        Other: array[2, 2] of Option A,B,C;
        i: Integer;
    begin
        Kinds[2] := Kinds[2]::Purchase;
        Kinds[3] := Kinds[3]::Released;
        Kinds[4] := 2;
        Kinds[5] := Kinds[2];
        for i := 1 to 5 do
            Observer.Observe('element ' + Format(i), Format(Kinds[i]) + ' | ' + Format(Kinds[i], 0, 9));
        Observer.Observe('2 = Purchase', Format(Kinds[2] = Kinds[2]::Purchase));
        Observer.Observe('2 = 5', Format(Kinds[2] = Kinds[5]));
        Observer.Observe('3 < 2', Format(Kinds[3] < Kinds[2]));
        Observer.Observe('1 = None', Format(Kinds[1] = Kinds[1]::None));
        Observer.Observe('4 = FirmPlanned', Format(Kinds[4] = Kinds[4]::FirmPlanned));
        Observer.Observe('2 as integer = 3', Format(Kinds[2] = 3));
        Other[1, 2] := Other[1, 2]::C;
        Observer.Observe('two dimensions [1,1]', Format(Other[1, 1]));
        Observer.Observe('two dimensions [1,2]', Format(Other[1, 2]));
        Observer.Observe('two dimensions [2,2]', Format(Other[2, 2]));
        Observer.Expect('element 1', 'None | 0');
        Observer.Expect('element 2', 'Purchase | 3');
        Observer.Expect('element 3', 'Released | 1');
        Observer.Expect('element 4', 'FirmPlanned | 2');
        Observer.Expect('element 5', 'Purchase | 3');
        Observer.Expect('2 = Purchase', 'Yes');
        Observer.Expect('2 = 5', 'Yes');
        Observer.Expect('3 < 2', 'Yes');
        Observer.Expect('1 = None', 'Yes');
        Observer.Expect('4 = FirmPlanned', 'Yes');
        Observer.Expect('2 as integer = 3', 'Yes');
        Observer.Expect('two dimensions [1,1]', 'A');
        Observer.Expect('two dimensions [1,2]', 'C');
        Observer.Expect('two dimensions [2,2]', 'A');
        Observer.Verify();
    end;

    local procedure TakeOptions(var Values: array[3] of Option A,B,C): Text
    var
        Result: Text;
        i: Integer;
    begin
        Values[2] := Values[2]::C;
        for i := 1 to ArrayLen(Values) do
            Result += Format(Values[i]) + ',';
        exit(Result);
    end;

    [Test]
    procedure OptionArray_PassedByReference()
    var
        Observer: Codeunit "Probe Observer";
        Values: array[3] of Option A,B,C;
    begin
        Observer.Observe('inside the procedure', TakeOptions(Values));
        Observer.Observe('outside, element 2', Format(Values[2]));
        Observer.Observe('outside, element 3', Format(Values[3]));
        Observer.Expect('inside the procedure', 'A,C,A,');
        Observer.Expect('outside, element 2', 'C');
        Observer.Expect('outside, element 3', 'A');
        Observer.Verify();
    end;
}

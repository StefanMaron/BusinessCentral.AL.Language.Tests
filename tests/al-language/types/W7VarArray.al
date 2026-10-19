// Batch 7 probes: an array variable passed to a var array parameter of another size, and by value. Observe only.
codeunit 68569 "W7 Var Array"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LengthOf(var A: array[3] of Integer): Integer
    begin
        exit(ArrayLen(A));
    end;

    local procedure ReadThird(var A: array[3] of Integer): Integer
    begin
        exit(A[3]);
    end;

    local procedure WriteThird(var A: array[3] of Integer)
    begin
        A[3] := 99;
    end;

    local procedure LengthOfValue(A: array[3] of Integer): Integer
    begin
        exit(ArrayLen(A));
    end;

    local procedure ReadThirdOfValue(A: array[3] of Integer): Integer
    begin
        exit(A[3]);
    end;

    [Test]
    procedure VarArray_SmallerArgument_Length()
    var
        Observer: Codeunit "Probe Observer";
        Small: array[2] of Integer;
    begin
        Small[1] := 11;
        Small[2] := 22;
        Observer.Observe('ArrayLen inside', Format(LengthOf(Small)));
        Observer.Observe('ArrayLen outside', Format(ArrayLen(Small)));
        Observer.Expect('ArrayLen inside', '2');
        Observer.Expect('ArrayLen outside', '2');
        Observer.Verify();
    end;

    [Test]
    procedure VarArray_LargerArgument()
    var
        Observer: Codeunit "Probe Observer";
        Large: array[5] of Integer;
    begin
        Large[3] := 33;
        Large[5] := 55;
        Observer.Observe('ArrayLen inside', Format(LengthOf(Large)));
        Observer.Observe('A[3] read', Format(ReadThird(Large)));
        WriteThird(Large);
        Observer.Observe('outside, element 3 after write', Format(Large[3]));
        Observer.Observe('outside, element 5', Format(Large[5]));
        Observer.Expect('ArrayLen inside', '5');
        Observer.Expect('A[3] read', '33');
        Observer.Expect('outside, element 3 after write', '99');
        Observer.Expect('outside, element 5', '55');
        Observer.Verify();
    end;

    [Test]
    procedure ValueArray_SmallerAndLargerArgument()
    var
        Observer: Codeunit "Probe Observer";
        Small: array[2] of Integer;
        Large: array[5] of Integer;
    begin
        Small[2] := 22;
        Large[3] := 33;
        Observer.Observe('small: ArrayLen inside', Format(LengthOfValue(Small)));
        Observer.Observe('large: ArrayLen inside', Format(LengthOfValue(Large)));
        Observer.Observe('large: A[3]', Format(ReadThirdOfValue(Large)));
        Observer.Expect('small: ArrayLen inside', '2');
        Observer.Expect('large: ArrayLen inside', '5');
        Observer.Expect('large: A[3]', '33');
        Observer.Verify();
    end;

}

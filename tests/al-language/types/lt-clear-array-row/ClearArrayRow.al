// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); ALT Universal (60000); own codeunit 67553
// Probe: Clear(Arr[2]) on a two-dimensional array (a whole row) for Integer, Text, Decimal and Record arrays: which elements are reset and which keep their values; Clear of a single element and of a one-dimensional element for comparison (issue 581 item 7).
// BC versions: 27+

codeunit 67553 "LT Clear Array Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpText(var A: array[3, 2] of Text; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 2 do
                Observer.Observe(Name + Format(i) + Format(j), '[' + A[i, j] + ']');
    end;

    [Test]
    procedure Clear_Row_TextArray2D()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 2] of Text;
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 2 do
                A[i, j] := 't' + Format(i) + Format(j);
        Clear(A[2]);
        DumpText(A, 'text', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Row_IntegerArray2D()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 2] of Integer;
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 2 do
                A[i, j] := i * 10 + j;
        Clear(A[2]);
        for i := 1 to 3 do
            for j := 1 to 2 do
                Observer.Observe('int' + Format(i) + Format(j), Format(A[i, j]));
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Row_DecimalArray2D()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 2] of Decimal;
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 2 do
                A[i, j] := i * 10 + j + 0.5;
        Clear(A[2]);
        for i := 1 to 3 do
            for j := 1 to 2 do
                Observer.Observe('dec' + Format(i) + Format(j), Format(A[i, j], 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Row_RecordArray2D()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 2] of Record "ALT Universal";
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do
            for j := 1 to 2 do begin
                A[i, j]."Entry No." := i * 10 + j;
                A[i, j]."Text Field" := 'r' + Format(i) + Format(j);
                A[i, j].SetRange("Entry No.", i * 10 + j);
            end;
        Clear(A[2]);
        for i := 1 to 3 do
            for j := 1 to 2 do begin
                Observer.Observe('rec' + Format(i) + Format(j) + 'no', Format(A[i, j]."Entry No."));
                Observer.Observe('rec' + Format(i) + Format(j) + 'text', '[' + A[i, j]."Text Field" + ']');
                Observer.Observe('rec' + Format(i) + Format(j) + 'filters', '[' + A[i, j].GetFilters() + ']');
            end;
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Element_And_OneDimensional()
    var
        Observer: Codeunit "Probe Observer";
        A: array[3, 2] of Text;
        B: array[3] of Text;
        D: array[3] of Decimal;
        i: Integer;
        j: Integer;
    begin
        for i := 1 to 3 do begin
            B[i] := 'b' + Format(i);
            D[i] := i + 0.25;
            for j := 1 to 2 do
                A[i, j] := 't' + Format(i) + Format(j);
        end;
        Clear(A[2, 1]);
        Clear(B[2]);
        Clear(D[2]);
        DumpText(A, 'elem', Observer);
        for i := 1 to 3 do begin
            Observer.Observe('b' + Format(i), '[' + B[i] + ']');
            Observer.Observe('d' + Format(i), Format(D[i], 0, 9));
        end;
        Observer.Finish();
    end;
}

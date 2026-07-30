// Support codeunit for TestListOfCodeunitState.al — a plain stateful codeunit stored
// in a List of [Codeunit] by the tests.

codeunit 60379 "List Codeunit State Stateful"
{
    var
        StoredValue: Integer;

    procedure SetValue(V: Integer)
    begin
        StoredValue := V;
    end;

    procedure GetValue(): Integer
    begin
        exit(StoredValue);
    end;
}

// @expect AL0117 | Illegal statement. Only assignment and method invocation can be used as a statement.
// With a local variable named Continue in scope, the statement `continue;` is read as the bare variable, not as the continue statement
// (microsoft/AL issue 7930). Without the variable the loop compiles (tests/al-language/types/PUContinue.al).
codeunit 51393 "MNC BN C1393"
{
    procedure Run1(): Text
    var
        Continue: Boolean;
        i: Integer;
        S: Text;
    begin
        Continue := true;
        for i := 1 to 3 do begin
            if i = 2 then
                continue;
            S += Format(i);
        end;
        exit(S);
    end;
}

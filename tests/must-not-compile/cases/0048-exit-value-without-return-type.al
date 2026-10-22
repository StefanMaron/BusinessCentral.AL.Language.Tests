// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in a procedure without a return type.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC Codeunit"
{
    procedure DoIt()
    var
        I: Integer;
        T: Text;
        R: Record "MNC Table";
    begin
        exit(1);
    end;
}

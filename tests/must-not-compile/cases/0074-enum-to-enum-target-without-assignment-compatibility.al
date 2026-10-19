// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC Src"' to 'Enum "MNC Dst"'
// An enum assigned to an enum of another type; only a TARGET with AssignmentCompatibility = true takes it (a source with the property is not enough).
enum 50000 "MNC Src" { Extensible = true; AssignmentCompatibility = true; value(0; None) { } value(1; One) { } value(7; Seven) { } }
enum 50001 "MNC Dst" { Extensible = true; AssignmentCompatibility = false; value(0; None) { } value(1; One) { } value(2; Two) { } }
codeunit 50002 "MNC Assign"
{
    procedure Do(): Integer
    var
        S: Enum "MNC Src";
        D: Enum "MNC Dst";
    begin
        D := S;
        exit(D.AsInteger());
    end;
}

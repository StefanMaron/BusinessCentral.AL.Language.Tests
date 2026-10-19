// The User Group Member table (user groups) is removed from the Base Application (corpus issue 647 item 23, writer AV): naming it does not compile.
// @expect AL0433 | Table 'User Group Member' is removed.
codeunit 51172 "MNC AV User Group Member"
{
    procedure Probe()
    var
        Member: Record "User Group Member";
    begin
    end;
}

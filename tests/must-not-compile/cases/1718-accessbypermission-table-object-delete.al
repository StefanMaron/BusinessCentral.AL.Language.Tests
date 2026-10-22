// @expect AL0195 | Invalid permission kind. Expected: 'X'
// AccessByPermission on a page action names a table OBJECT (not its tabledata) with D: only X is allowed for the table object
// (corpus issue 669, writer CO). 'tabledata <x> = D' compiles (tests/al-language/permissions/lt-co-permission-leads/CoPermissionLeads.al).
table 50000 "MNC CO 1718 T"
{
    fields { field(1; Id; Integer) { } }
}

page 50001 "MNC CO 1718 P"
{
    PageType = Card;
    actions
    {
        area(Processing)
        {
            action(A) { AccessByPermission = table "MNC CO 1718 T" = D; trigger OnAction() begin end; }
        }
    }
}

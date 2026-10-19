// @expect AL0195 | Invalid permission kind. Expected: 'X'
// @expect AL0195 | Invalid permission kind. Expected: 'X'
// @expect AL0195 | Invalid permission kind. Expected: 'X'
// AccessByPermission on page actions names a report with M, a query with R and an xmlport with R: only X is allowed (corpus issue 669,
// writer CO). One diagnostic per action. 'tabledata <x> = D' on an action compiles (CoPermissionLeads.al, page 84949).
page 50001 "MNC CO 1717 P"
{
    PageType = Card;
    actions
    {
        area(Processing)
        {
            action(A) { AccessByPermission = report "Customer - List" = M; trigger OnAction() begin end; }
            action(B) { AccessByPermission = query "Customer Sales" = R; trigger OnAction() begin end; }
            action(C) { AccessByPermission = xmlport "Export Contact" = R; trigger OnAction() begin end; }
        }
    }
}

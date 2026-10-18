// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// @expect AL0169 | The option value 'Removed' is not valid. Check the enum definition for valid values.
// Removed is not a value of ObsoleteState for page controls and actions: group, repeater, grid, fixed group, system part, user control, action,
// action group, file upload action, custom action and view (11 elements, one AL0169 each).
controladdin "MNC X AddIn" { RequestedHeight = 100; }
table 59990 "MNC X Src" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 59991 "MNC X Page"
{
    PageType = List;
    SourceTable = "MNC X Src";
    layout
    {
        area(Content)
        {
            group(G) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F1; Rec.Id) { } }
            repeater(Rp) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F2; Rec.Id) { } }
            grid(Gr) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; group(Gg) { field(F3; Rec.Id) { } } }
            fixed(Fx) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; group(Fg) { field(F4; Rec.Id) { } } }
            usercontrol(Uc; "MNC X AddIn") { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
        }
        area(FactBoxes) { systempart(Sp; Links) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } }
    }
    actions
    {
        area(Processing)
        {
            action(A1) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
            group(Ag) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; action(A2) { } }
            fileuploadaction(Up) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
            customaction(Ca) { CustomActionType = Flow; FlowId = '11111111-1111-1111-1111-111111111111'; ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
        }
    }
    views { view(V) { Caption = 'v'; Filters = where(Id = const(1)); ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; } }
}

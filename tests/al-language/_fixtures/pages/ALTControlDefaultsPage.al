// Fixture for record/TestPageControlFieldDefaults.al — the two "Page Control Field"
// (2000000192) columns that "ALT Control Tree Page" (60427) and "ALT List Page" (60016)
// leave unmeasured.
//
// Both existing fixtures happen to make two different provider implementations agree:
//
//   * every one of their controls that a test reads either declares Editable explicitly
//     or is never asserted on, so what the table reports for an UNDECLARED Editable is
//     not pinned anywhere — and it need not match what Enabled and Visible report, since
//     those three properties are separate columns filled from separate control properties;
//
//   * the only control they bind to an option-like field is bound to "Option Field", which
//     is declared `Option` with inline OptionMembers. "ALT Universal" also declares
//     "Status Field" as `Enum "ALT Status"` — a different AL type — and no control on
//     either page binds to it, so an implementation that keys OptionString off the AL
//     type and one that keys it off "carries option metadata" cannot be told apart.
//
// This page supplies exactly the missing shapes. It is a plain Card with no page-level
// Editable property, so nothing about the page itself pushes the control defaults in
// either direction.
page 60425 "ALT Control Defaults Page"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    Caption = 'ALT Control Defaults';

    layout
    {
        area(Content)
        {
            group(Defaults)
            {
                field(BareControl; Rec."Entry No.")
                {
                    // Declares NEITHER Editable, Enabled NOR Visible, and is bound to a
                    // field that declares no Editable either. What the table reports for
                    // each of the three is the whole question, and the measured answer is
                    // that it does not answer alike: 'true' for Enabled and Visible,
                    // 'True' for Editable.
                    ApplicationArea = All;
                }
                field(EnumBoundControl; Rec."Status Field")
                {
                    // Bound to an Enum-typed field. "ALT Status" has five members, so the
                    // count alone distinguishes it from "Option Field"'s four and from an
                    // empty answer.
                    ApplicationArea = All;
                }
                field(DeclaredEditableFalse; Rec."Description Field")
                {
                    // Negative direction for the undeclared case: a control that DOES
                    // declare Editable must still report it, whatever the default is.
                    ApplicationArea = All;
                    Editable = false;
                }
                field(DeclaredEnabledFalse; Rec."Name Field")
                {
                    // Same, for Enabled.
                    ApplicationArea = All;
                    Enabled = false;
                }
            }
        }
    }
}

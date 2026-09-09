// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: MCV Row (60510)
//
// The base page's Name control declares its OWN OnValidate, so the tests can tell "the
// extension's triggers ran" apart from "the extension's triggers replaced the base one".
// A base control with no trigger of its own would leave that unanswerable.
//
// A second extension (60513) modifies a DIFFERENT control, which is what lets the suite pin
// that validating Name does not raise it — an implementation that raises every modify()
// trigger it can find on the page passes every single-extension arm without it.
//
// Deliberately NOT covered here: two extensions modifying the SAME control. That would pin
// a relative ORDER between extensions, and AL gives no way to state which extension wins,
// so the answer is a property of the platform's load order rather than of the source. It is
// left unasserted rather than pinned to whatever one run happens to produce.

page 60511 "MCV Card"
{
    PageType = Card;
    SourceTable = "MCV Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Rec.Trace := Rec.Trace + 'page;';
                end;
            }
            // A second control carrying its own OnValidate, so an implementation that raises
            // every modify() trigger it can find regardless of which control is being
            // validated is caught rather than passing by coincidence.
            field(Other; Rec.Other)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Rec.Trace := Rec.Trace + 'otherpage;';
                end;
            }
            // Carries no trigger of its own, so the extension's modify() block is the only
            // possible source of a drilldown or lookup effect on it.
            field(Extra; Rec.Extra)
            {
                ApplicationArea = All;
            }
            field(Trace; Rec.Trace)
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
}

pageextension 60512 "MCV Card Ext" extends "MCV Card"
{
    layout
    {
        modify(Name)
        {
            trigger OnBeforeValidate()
            begin
                Rec.Trace := Rec.Trace + 'before;';
                // Deliberately kept though no arm in this suite currently drives it: what an
                // Error() here leaves behind is a claim about BC's page-write buffer rather
                // than about modify() dispatch, and is tracked as its own follow-up. Real BC
                // discards the mutation above when this raises (measured: eight cloud legs
                // answered '' where a surviving mutation would read 'before;'). Keeping the
                // hook means that follow-up adds an arm rather than re-shaping the fixture.
                if Rec.Name = 'stop' then
                    Error('MCV stopped in OnBeforeValidate');
            end;

            trigger OnAfterValidate()
            begin
                Rec.Trace := Rec.Trace + 'after;';
            end;
        }
    }
}

// A modify() block accepts more than the before/after validate pair: OnLookup, OnDrillDown
// and OnAssistEdit are legal there too (the compiler rejects OnValidate and OnControlAddIn
// inside one). Those reach the control through the same identity rule, so the suite pins two
// of them on their own control -- a control separate from Name, so a drilldown or lookup arm
// cannot perturb the validate-order arms.
pageextension 60513 "MCV Other Ext" extends "MCV Card"
{
    layout
    {
        modify(Other)
        {
            trigger OnBeforeValidate()
            begin
                Rec.Trace := Rec.Trace + 'otherbefore;';
            end;

            trigger OnAfterValidate()
            begin
                Rec.Trace := Rec.Trace + 'otherafter;';
            end;
        }

        modify(Extra)
        {
            trigger OnDrillDown()
            begin
                Rec.Trace := Rec.Trace + 'extdrill;';
            end;

            trigger OnLookup(var Text: Text): Boolean
            begin
                Rec.Trace := Rec.Trace + 'extlookup;';
                exit(false);
            end;
        }
    }
}

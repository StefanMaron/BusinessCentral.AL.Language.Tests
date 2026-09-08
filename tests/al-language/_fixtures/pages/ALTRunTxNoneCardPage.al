// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-pages
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: fixture page used by "Test Write Tx Test Boundary" (60878)
// Fixture table: ALT Universal (60000)
//
// The page arm's target. The Text Field's OnValidate writes a marker row of its own into
// "ALT Universal" — a DIFFERENT row from the one the page is sitting on, so "did the write
// land" is answerable by a row count and cannot be confused with the page's own Modify.
//
// Driven through a TestPage.SetValue from a TransactionModel::None test body, this asks
// whether the page's field-validation path begins a transaction of its own the way
// Codeunit.Run does.
page 60414 "ALT Run Tx None Card"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    Caption = 'ALT Run Tx None Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Text Field"; Rec."Text Field")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Marker: Record "ALT Universal";
                    begin
                        Marker.Init();
                        Marker."Entry No." := 9414;
                        Marker."Text Field" := 'DIRTY-NONE-PAGE';
                        Marker.Insert();
                    end;
                }
            }
        }
    }
}

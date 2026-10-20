// @expect AL0271 | The action 'P&ost Shipment' is not found in the target 'MNC CL Act 1689'
// @expect AL0271 | The action 'Post Shipment' is not found in the target 'MNC CL Act 1689'
// @expect AL0271 | The action 'NoSuchAction' is not found in the target 'MNC CL Act 1689'
// An action subscriber names the action by its caption (with and without the ampersand) and by an unknown name: only the AL name binds
// (corpus issue 669, item 25; microsoft/AL issues 1554 and 2915 used captions of unnamed C/SIDE actions; an AL action always has a name).
page 51689 "MNC CL Act 1689"
{
    PageType = Card;
    SourceTable = Customer;

    actions
    {
        area(Processing)
        {
            action(PostShipment)
            {
                Caption = 'P&ost Shipment';
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 51689 "MNC CL Act Sub 1689"
{
    [EventSubscriber(ObjectType::Page, Page::"MNC CL Act 1689", 'OnBeforeActionEvent', 'P&ost Shipment', false, false)]
    local procedure ByCaption(var Rec: Record Customer)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC CL Act 1689", 'OnBeforeActionEvent', 'Post Shipment', false, false)]
    local procedure ByCaptionWithoutAmpersand(var Rec: Record Customer)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC CL Act 1689", 'OnAfterActionEvent', 'NoSuchAction', false, false)]
    local procedure Unknown(var Rec: Record Customer)
    begin
    end;
}

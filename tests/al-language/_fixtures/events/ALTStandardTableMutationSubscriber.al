codeunit 60032 "ALT Standard Table Mut"
{
    [EventSubscriber(ObjectType::Table, Database::"Payment Terms", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure PaymentTermsDescription_OnAfterValidate(var Rec: Record "Payment Terms")
    begin
        if Rec.Description = '' then
            exit;

        Rec."Calc. Pmt. Disc. on Cr. Memos" := true;
    end;
}

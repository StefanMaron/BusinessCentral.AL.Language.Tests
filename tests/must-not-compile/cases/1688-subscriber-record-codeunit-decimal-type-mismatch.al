// @expect AL0284 | The type of the parameter 'Cust' on the event subscriber 'VendorForCustomer' does not match the expected type 'Record Customer'.
// @expect AL0284 | The type of the parameter 'Cust' on the event subscriber 'CodeunitForRecord' does not match the expected type 'Record Customer'.
// @expect AL0284 | The type of the parameter 'N' on the event subscriber 'DecimalForInteger' does not match the expected type 'Integer'.
// Subscribers declare another Record type (Vendor for Customer), a Codeunit for a Record, and Decimal for Integer (corpus issue 669, item 18;
// microsoft/AL issue 5464 compiled Vendor for Customer in 2019). A subscriber that declares the Customer parameter temporary compiles (not a case).
codeunit 51688 "MNC CL Pub 1688"
{
    procedure Fire()
    var
        Cust: Record Customer;
        N: Integer;
    begin
        OnBeforeCode(Cust, N);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var Cust: Record Customer; var N: Integer)
    begin
    end;
}

codeunit 51689 "MNC CL Sub 1688"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CL Pub 1688", 'OnBeforeCode', '', false, false)]
    local procedure VendorForCustomer(var Cust: Record Vendor)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CL Pub 1688", 'OnBeforeCode', '', false, false)]
    local procedure CodeunitForRecord(var Cust: Codeunit "MNC CL Pub 1688")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CL Pub 1688", 'OnBeforeCode', '', false, false)]
    local procedure DecimalForInteger(var N: Decimal)
    begin
    end;
}

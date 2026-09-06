// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: none - Base Application's own Customer, Service Line, Stockkeeping Unit and
//   Prod. Order Line tables; shared Assert (60021)
// BC versions: 27.0+
//
// CLAIM: a FlowField a TABLEEXTENSION adds to a table calculates through CalcFields exactly
// like a FlowField declared on the base table itself. Nothing about the calculation depends on
// where the field was declared.
//
// Both fields measured here are contributed by a tableextension shipped INSIDE the Base
// Application package; neither is declared on the base table's own field list:
//
//   Customer 5912 "Outstanding Serv.Invoices(LCY)"
//       sum("Service Line"."Outstanding Amount (LCY)"
//           where("Document Type" = const(Invoice), "Bill-to Customer No." = field("No."), ...))
//   Stockkeeping Unit 99000777 "Qty. on Prod. Order"
//       sum("Prod. Order Line"."Remaining Qty. (Base)"
//           where(Status = filter(Planned .. Released), "Item No." = field("Item No."),
//                 "Location Code" = field("Location Code"), ...))
//
// Each test seeds rows that MUST be counted and rows that must NOT be, so "the whole sum" and
// "any non-zero number" are different answers:
//
//   Customer:          two Invoice lines (125 + 75 = 200) for the customer under test,
//                      one Order line (500) for the same customer   -> excluded by const(Invoice),
//                      one Invoice line (900) for a second customer -> excluded by the field link.
//   Stockkeeping Unit: a Released line (7) and a Planned line (3) on the SKU's item+location,
//                      one Finished line (99)             -> outside filter(Planned .. Released),
//                      one line on another location (55)  -> excluded by the Location Code link.
//
// Rows are inserted with Insert(false): every value under test is written directly, so no
// insert trigger, no number series and no master data beyond the customers is involved.
codeunit 60013 "CalcFields Ext FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CalcFields_TableExtensionFlowFieldOnCustomer_SumsOnlyTheMatchingLines()
    var
        Cust: Record Customer;
        Other: Record Customer;
    begin
        // [GIVEN] Two customers and four service lines across them.
        DeleteServiceLines();
        InsertCustomer(Cust, 'ALT-CFX-C1');
        InsertCustomer(Other, 'ALT-CFX-C2');

        InsertServiceLine('ALT-CFX-SI1', 10000, "Service Document Type"::Invoice, 'ALT-CFX-C1', 125);
        InsertServiceLine('ALT-CFX-SI1', 20000, "Service Document Type"::Invoice, 'ALT-CFX-C1', 75);
        InsertServiceLine('ALT-CFX-SO1', 10000, "Service Document Type"::Order, 'ALT-CFX-C1', 500);
        InsertServiceLine('ALT-CFX-SI2', 10000, "Service Document Type"::Invoice, 'ALT-CFX-C2', 900);

        // [WHEN] The tableextension-contributed FlowField is calculated.
        Cust.CalcFields("Outstanding Serv.Invoices(LCY)");
        Other.CalcFields("Outstanding Serv.Invoices(LCY)");

        // [THEN] It answers the sum of that customer's INVOICE lines only.
        Assert.AreEqual(
            200.0, Cust."Outstanding Serv.Invoices(LCY)",
            'Customer 5912 must sum the two invoice lines (125 + 75) and exclude the order line');
        Assert.AreEqual(
            900.0, Other."Outstanding Serv.Invoices(LCY)",
            'The second customer must see only its own invoice line');
    end;

    [Test]
    procedure CalcFields_TableExtensionFlowFieldOnCustomer_WithNoMatchingRows_IsZero()
    var
        Cust: Record Customer;
    begin
        // [GIVEN] A customer with no service lines at all.
        DeleteServiceLines();
        InsertCustomer(Cust, 'ALT-CFX-C3');

        // [WHEN/THEN] The field calculates, and calculates to zero rather than refusing.
        Cust.CalcFields("Outstanding Serv.Invoices(LCY)");
        Assert.AreEqual(
            0.0, Cust."Outstanding Serv.Invoices(LCY)",
            'With no service lines the tableextension FlowField must calculate to 0');
    end;

    [Test]
    procedure CalcFields_TableExtensionFlowFieldOnStockkeepingUnit_SumsOnlyTheMatchingLines()
    var
        SKU: Record "Stockkeeping Unit";
    begin
        // [GIVEN] Production order lines on two locations and three statuses.
        DeleteProdOrderLines();

        InsertProdOrderLine("Production Order Status"::Released, 'ALT-CFX-PO1', 10000,
            'ALT-CFX-ITEM', 'CFX-LOC', 7);
        InsertProdOrderLine("Production Order Status"::Planned, 'ALT-CFX-PO2', 10000,
            'ALT-CFX-ITEM', 'CFX-LOC', 3);
        InsertProdOrderLine("Production Order Status"::Finished, 'ALT-CFX-PO3', 10000,
            'ALT-CFX-ITEM', 'CFX-LOC', 99);
        InsertProdOrderLine("Production Order Status"::Released, 'ALT-CFX-PO4', 10000,
            'ALT-CFX-ITEM', 'CFX-OTH', 55);

        // [WHEN] The SKU's tableextension-contributed FlowField is calculated.
        SKU.Init();
        SKU."Item No." := 'ALT-CFX-ITEM';
        SKU."Location Code" := 'CFX-LOC';

        SKU.CalcFields("Qty. on Prod. Order");

        // [THEN] Only the Planned..Released lines on that item and location are summed.
        Assert.AreEqual(
            10.0, SKU."Qty. on Prod. Order",
            'Stockkeeping Unit 99000777 must sum 7 + 3, excluding the Finished line and the other location');
    end;

    [Test]
    procedure CalcFields_TableExtensionFlowFieldOnStockkeepingUnit_WithNoMatchingRows_IsZero()
    var
        SKU: Record "Stockkeeping Unit";
    begin
        // [GIVEN] No production order lines for this item at all.
        DeleteProdOrderLines();

        SKU.Init();
        SKU."Item No." := 'ALT-CFX-NOSUCH';
        SKU."Location Code" := 'CFX-LOC';

        // [WHEN/THEN] The field calculates, and calculates to zero rather than refusing.
        SKU.CalcFields("Qty. on Prod. Order");
        Assert.AreEqual(
            0.0, SKU."Qty. on Prod. Order",
            'With no production order lines the tableextension FlowField must calculate to 0');
    end;

    local procedure InsertCustomer(var Cust: Record Customer; No: Code[20])
    begin
        if Cust.Get(No) then
            Cust.Delete(false);
        Clear(Cust);
        Cust.Init();
        Cust."No." := No;
        Cust.Insert(false);
    end;

    local procedure InsertServiceLine(DocumentNo: Code[20]; LineNo: Integer; DocumentType: Enum "Service Document Type"; BillToCustomerNo: Code[20]; OutstandingAmountLCY: Decimal)
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Init();
        ServLine."Document Type" := DocumentType;
        ServLine."Document No." := DocumentNo;
        ServLine."Line No." := LineNo;
        ServLine."Bill-to Customer No." := BillToCustomerNo;
        ServLine."Outstanding Amount (LCY)" := OutstandingAmountLCY;
        ServLine.Insert(false);
    end;

    local procedure InsertProdOrderLine(NewStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; RemainingQtyBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Init();
        ProdOrderLine.Status := NewStatus;
        ProdOrderLine."Prod. Order No." := ProdOrderNo;
        ProdOrderLine."Line No." := LineNo;
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine."Location Code" := LocationCode;
        ProdOrderLine."Remaining Qty. (Base)" := RemainingQtyBase;
        ProdOrderLine.Insert(false);
    end;

    local procedure DeleteServiceLines()
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Reset();
        ServLine.SetFilter("Document No.", 'ALT-CFX-*');
        ServLine.DeleteAll(false);
    end;

    local procedure DeleteProdOrderLines()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetFilter("Prod. Order No.", 'ALT-CFX-*');
        ProdOrderLine.DeleteAll(false);
    end;
}

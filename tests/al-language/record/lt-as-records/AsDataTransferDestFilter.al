// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/methods-auto/datatransfer/datatransfer-adddestinationfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79900, 79901, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 15).
// Facts: DataTransfer.AddDestinationFilter from a test (outside upgrade and install code): a valid and an unknown destination field number,
//   then CopyFields and CopyRows (the error text and whether any destination row changed).
// BC versions: 28-29 (AddDestinationFilter needs runtime 17; the runtime 16 refusal is must-not-compile case 0365)

#if BC28PLUS
codeunit 79931 "LT AS DataTransfer DestFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure Seed()
    var
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        I.DeleteAll();
        B.DeleteAll();
        I.Id := 1;
        I.Name := 'src1';
        I.Insert();
        I.Id := 2;
        I.Name := 'src2';
        I.Insert();
        B.Id := 1;
        B.Name := 'dst1';
        B.Insert();
        B.Id := 2;
        B.Name := 'dst2';
        B.Insert();
    end;

    local procedure Targets(): Text
    var
        B: Record "LT AS Big Key";
        Result: Text;
    begin
        if B.FindSet() then
            repeat
                Result += Format(B.Id) + '=' + B.Name + ' ';
            until B.Next() = 0;
        exit(Result.TrimEnd());
    end;

    [TryFunction]
    local procedure TryAddFilter(var DT: DataTransfer; FieldNo: Integer)
    begin
        DT.AddDestinationFilter(FieldNo, '%1', 2);
    end;

    [TryFunction]
    local procedure TryCopyFields(var DT: DataTransfer)
    begin
        DT.CopyFields();
    end;

    [TryFunction]
    local procedure TryCopyRows(var DT: DataTransfer)
    begin
        DT.CopyRows();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(Helper.LastError());
    end;

    [Test]
    procedure ValidFilter_CopyFields()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        Seed();
        ClearLastError();
        DT.SetTables(Database::"LT AS Int Key", Database::"LT AS Big Key");
        DT.AddFieldValue(I.FieldNo(Name), B.FieldNo(Name));
        DT.AddJoin(I.FieldNo(Id), B.FieldNo(Id));
        Observer.Observe('add', Outcome(TryAddFilter(DT, B.FieldNo(Id))));
        Observer.Observe('copyfields', Outcome(TryCopyFields(DT)));
        Observer.Observe('targets', Targets());
        Observer.Finish();
    end;

    [Test]
    procedure ValidFilter_CopyRows()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        Seed();
        ClearLastError();
        DT.SetTables(Database::"LT AS Int Key", Database::"LT AS Big Key");
        DT.AddFieldValue(I.FieldNo(Name), B.FieldNo(Name));
        Observer.Observe('add', Outcome(TryAddFilter(DT, B.FieldNo(Id))));
        Observer.Observe('copyrows', Outcome(TryCopyRows(DT)));
        Observer.Observe('targets', Targets());
        Observer.Finish();
    end;

    [Test]
    procedure UnknownFieldNo()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        Seed();
        ClearLastError();
        DT.SetTables(Database::"LT AS Int Key", Database::"LT AS Big Key");
        DT.AddFieldValue(I.FieldNo(Name), B.FieldNo(Name));
        DT.AddJoin(I.FieldNo(Id), B.FieldNo(Id));
        Observer.Observe('add999', Outcome(TryAddFilter(DT, 999)));
        Observer.Observe('copyfields', Outcome(TryCopyFields(DT)));
        Observer.Finish();
    end;

    [Test]
    procedure FilterBeforeSetTables()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('add_no_tables', Outcome(TryAddFilter(DT, 1)));
        Observer.Finish();
    end;
}
#endif

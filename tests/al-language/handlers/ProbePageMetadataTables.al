// Probe: Page Metadata, Page Control Field and Page Action virtual tables, dumped column by column.
codeunit 69503 "Probe Page Metadata Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpPage(PageId: Integer): Text
    var
        Meta: Record "Page Metadata";
        RecRef: RecordRef;
        Dumper: Codeunit "Probe Row Dumper";
    begin
        if not Meta.Get(PageId) then
            exit('(no row)');
        RecRef.GetTable(Meta);
        exit(Dumper.Dump(RecRef));
    end;




















































}

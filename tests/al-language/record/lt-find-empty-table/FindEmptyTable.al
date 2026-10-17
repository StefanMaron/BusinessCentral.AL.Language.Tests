// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67072
// Probe: Record.Find on an empty table with no filter, the result not used, and with the result used, for the search strings '=', '-', '+', '>', '<' and
// '=><', and Find() with no argument. Does a call with an unused result raise an error, and what does it return. Object ids 67072 - 67073.

table 67072 "LT FE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67073 "LT FE Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFindUnused(Mode: Text)
    var
        Row: Record "LT FE Row";
    begin
        if Mode = '' then
            Row.Find()
        else
            Row.Find(Mode);
    end;

    local procedure Unused(Mode: Text): Text
    begin
        ClearLastError();
        if TryFindUnused(Mode) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Used(Mode: Text): Text
    var
        Row: Record "LT FE Row";
    begin
        if Mode = '' then
            exit(Format(Row.Find()));
        exit(Format(Row.Find(Mode)));
    end;

    [Test]
    procedure Find_EmptyTable()
    var
        Row: Record "LT FE Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Observer.Observe('unused_default', Unused(''));
        Observer.Observe('unused_equals', Unused('='));
        Observer.Observe('unused_first', Unused('-'));
        Observer.Observe('unused_last', Unused('+'));
        Observer.Observe('unused_next', Unused('>'));
        Observer.Observe('unused_previous', Unused('<'));
        Observer.Observe('unused_all_directions', Unused('=><'));
        Observer.Observe('used_default', Used(''));
        Observer.Observe('used_equals', Used('='));
        Observer.Observe('used_first', Used('-'));
        Observer.Observe('used_last', Used('+'));
        Observer.Observe('used_next', Used('>'));
        Observer.Observe('used_previous', Used('<'));
        Observer.Observe('used_all_directions', Used('=><'));
        Observer.Expect('unused_default', 'error:The LT FE Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_equals', 'error:The LT FE Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_first', 'error:The LT FE Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused_last', 'error:The LT FE Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused_next', 'error:The LT FE Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_previous', 'error:The LT FE Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused_all_directions', 'error:The LT FE Row does not exist. =><\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('used_default', 'No');
        Observer.Expect('used_equals', 'No');
        Observer.Expect('used_first', 'No');
        Observer.Expect('used_last', 'No');
        Observer.Expect('used_next', 'No');
        Observer.Expect('used_previous', 'No');
        Observer.Expect('used_all_directions', 'No');
        Observer.Verify();
    end;
}

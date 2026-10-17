// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 71880 to 71882 and test codeunit 71883
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the exact text of GetUrl(ClientType::Web, Company, ObjectType::Page, Id, Record/RecordRef, UseFilters) after the server address
//   (the address differs per host, so only the part from the '?' on is asserted): the bookmark= value for a Code key, an Integer key
//   and a two-field key; the filter= text and its encoding after SetRange and SetFilter; UseFilters with and without a filter;
//   a RecordRef instead of a Record. Already pinned elsewhere: company encoding, the query parameter order and the object-only forms
//   (session/lt-geturl-shape/GetUrlShape.al, GetUrlObjects.al, GetUrlCompany.al).
// BC versions: 27, 28, 29
table 71880 "LT GUB Code Row"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 71881 "LT GUB Int Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71882 "LT GUB Two Row"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Line; Integer) { }
        field(3; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Code, Line) { Clustered = true; }
    }
}

codeunit 71883 "LT GUB GetUrl Bookmark Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    local procedure PageUrl(var Row: Record "LT GUB Code Row"; UseFilters: Boolean): Text
    begin
        exit(Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, UseFilters)));
    end;

    local procedure CodeRow(No: Code[20]; var Row: Record "LT GUB Code Row")
    begin
        Row.Init();
        Row.Code := No;
        Row.Name := 'N-' + No;
        Row.Qty := 1;
        Row.Insert();
    end;

    [Test]
    procedure GetUrl_Bookmark_CodeKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GUB Code Row";
        First: Text;
    begin
        Row.DeleteAll();
        CodeRow('A1', Row);
        CodeRow('b 2', Row);
        CodeRow('X&Y', Row);
        CodeRow('A', Row);
        CodeRow('', Row);
        Row.Get('A1');
        First := PageUrl(Row, false);
        Observer.Observe('a1', First);
        Observer.Observe('a1_again_equal', Format(First = PageUrl(Row, false)));
        Row.Get('b 2');
        Observer.Observe('lower_space', PageUrl(Row, false));
        Row.Get('X&Y');
        Observer.Observe('ampersand', PageUrl(Row, false));
        Row.Get('A');
        Observer.Observe('single_char', PageUrl(Row, false));
        Row.Get('');
        Observer.Observe('empty_code', PageUrl(Row, false));
        Row.Init();
        Row.Code := 'NOTINSERTED';
        Observer.Observe('not_inserted', PageUrl(Row, false));
        Observer.Observe('report', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Report, 71890, Row, false)));
        Observer.Observe('table', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Table, 71880, Row, false)));
        Observer.Observe('query', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Query, 71890, Row, false)));
        Observer.Observe('no_company', Tail(GetUrl(ClientType::Web, '', ObjectType::Page, 71890, Row, false)));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Bookmark_IntegerKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GUB Int Row";
        Id: Integer;
        Ids: List of [Integer];
    begin
        Row.DeleteAll();
        Ids.Add(0);
        Ids.Add(1);
        Ids.Add(127);
        Ids.Add(128);
        Ids.Add(255);
        Ids.Add(256);
        Ids.Add(100000);
        Ids.Add(-1);
        Ids.Add(-5);
        Ids.Add(2147483647);
        Ids.Add(-2147483647);
        foreach Id in Ids do begin
            Row.Init();
            Row.Id := Id;
            Row.Insert();
            Observer.Observe('id_' + Format(Id), Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false)));
        end;
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Bookmark_TwoFieldKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GUB Two Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Code := 'A1';
        Row.Line := 10000;
        Row.Insert();
        Observer.Observe('a1_10000', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false)));
        Row.Line := 20000;
        Row.Insert();
        Observer.Observe('a1_20000', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false)));
        Row.Code := 'B2';
        Row.Line := 10000;
        Row.Insert();
        Observer.Observe('b2_10000', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false)));
        Row.Code := 'A1';
        Row.Line := 0;
        Row.Insert();
        Observer.Observe('a1_0', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false)));
        Row.Code := 'A1';
        Row.Line := -1;
        Observer.Observe('a1_minus1_not_inserted', Tail(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, true)));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_RecordRef_SameAsRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GUB Code Row";
        TwoRow: Record "LT GUB Two Row";
        RecRef: RecordRef;
        UrlRec: Text;
        UrlRef: Text;
    begin
        Row.DeleteAll();
        CodeRow('A1', Row);
        Row.Get('A1');
        UrlRec := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, false);
        RecRef.GetTable(Row);
        UrlRef := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, RecRef, false);
        Observer.Observe('code_row_equal', Format(UrlRec = UrlRef));
        Observer.Observe('code_row_ref', Tail(UrlRef));
        Row.SetRange(Code, 'A1', 'A9');
        RecRef.GetTable(Row);
        UrlRec := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, Row, true);
        UrlRef := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, RecRef, true);
        Observer.Observe('filtered_equal', Format(UrlRec = UrlRef));
        Observer.Observe('filtered_ref', Tail(UrlRef));
        RecRef.Close();
        TwoRow.DeleteAll();
        TwoRow.Init();
        TwoRow.Code := 'A1';
        TwoRow.Line := 10000;
        TwoRow.Insert();
        RecRef.GetTable(TwoRow);
        UrlRec := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, TwoRow, false);
        UrlRef := GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 71890, RecRef, false);
        Observer.Observe('two_row_equal', Format(UrlRec = UrlRef));
        Observer.Observe('two_row_ref', Tail(UrlRef));
        RecRef.Close();
        Row.Reset();
        Row.DeleteAll();
        TwoRow.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Filter_Text()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GUB Code Row";
    begin
        Row.DeleteAll();
        CodeRow('A1', Row);
        CodeRow('B2', Row);
        Row.SetRange(Code, 'A1');
        Observer.Observe('range_one', PageUrl(Row, true));
        Observer.Observe('range_one_nofilters', PageUrl(Row, false));
        Row.Reset();
        Row.SetRange(Code, 'A1', 'B9');
        Observer.Observe('range_two', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Code, '10..20');
        Observer.Observe('filter_range', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Code, 'A*|B*');
        Observer.Observe('filter_or_wildcard', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Code, '<>A1&<>B2');
        Observer.Observe('filter_not_and', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Code, '>=A1');
        Observer.Observe('filter_ge', PageUrl(Row, true));
        Row.Reset();
        Row.SetRange(Qty, 5);
        Observer.Observe('int_one', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Qty, '1..5|8|>20');
        Observer.Observe('int_filter', PageUrl(Row, true));
        Row.Reset();
        Row.SetFilter(Name, '%1', 'A&B c%d');
        Observer.Observe('special_chars', PageUrl(Row, true));
        Row.Reset();
        Row.SetRange(Name, '');
        Observer.Observe('empty_filter', PageUrl(Row, true));
        Row.Reset();
        Row.SetRange(Code, 'A1');
        Row.SetRange(Qty, 1, 3);
        Observer.Observe('two_fields', PageUrl(Row, true));
        Row.SetRange(Name, 'N-A1');
        Observer.Observe('three_fields', PageUrl(Row, true));
        Row.Reset();
        Observer.Observe('reset_usefilters', PageUrl(Row, true));
        Row.Reset();
        Row.SetRange(Code, 'A1');
        Row.FindFirst();
        Observer.Observe('found_filtered', PageUrl(Row, true));
        Observer.Observe('found_filtered_nofilters', PageUrl(Row, false));
        Row.Reset();
        Row.DeleteAll();
        Observer.Finish();
    end;
}

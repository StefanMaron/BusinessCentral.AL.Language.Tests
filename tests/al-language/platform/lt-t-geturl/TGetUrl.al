// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 69377-69380, query 69376, test codeunit 69381; report 69367 and codeunit 69366 of lt-t-validate-layout
// Facts: GetUrl text for every client type (Default, Web, Windows, Phone, Tablet, Desktop) with and without company, object and record; special characters in the company and in a filter; Report, Query and Codeunit
// with a record; the bookmark of Code[10], Code[50] and two-Code-field keys. The server address (the GetUrl(ClientType::Web) text up to the first ?) is replaced by <base>.
// BC versions: 27.0 and later

table 69377 "LT T Url Code10"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; K) { Clustered = true; } }
}

table 69378 "LT T Url Code50"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[50]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; K) { Clustered = true; } }
}

table 69379 "LT T Url Two"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Code[20]) { }
        field(2; K2; Code[20]) { }
        field(3; Name; Text[30]) { }
    }

    keys { key(PK; K1, K2) { Clustered = true; } }
}

table 69380 "LT T Url Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 69376 "LT T Url Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT T Url Row")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 69381 "LT T GetUrl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Base(): Text
    var
        Full: Text;
        At: Integer;
    begin
        Full := GetUrl(ClientType::Web);
        At := StrPos(Full, '?');
        if At > 0 then
            Full := CopyStr(Full, 1, At - 1);
        exit(Full);
    end;

    local procedure Shape(Value: Text): Text
    var
        B: Text;
    begin
        B := Base();
        if B <> '' then
            Value := Value.Replace(B, '<base>');
        exit(Host(Value));
    end;

    // A non-Web address (dynamicsnav://host:port/BC...) has the container's host and port: they become <host>.
    local procedure Host(Value: Text): Text
    var
        At: Integer;
        Rest: Text;
        Slash: Integer;
    begin
        At := StrPos(Value, '://');
        if At = 0 then
            exit(Value);
        Rest := CopyStr(Value, At + 3);
        Slash := StrPos(Rest, '/');
        if Slash = 0 then
            exit(CopyStr(Value, 1, At + 2) + '<host>');
        exit(CopyStr(Value, 1, At + 2) + '<host>' + CopyStr(Rest, Slash));
    end;

    [TryFunction]
    local procedure TryCompany(Client: ClientType; Company: Text; var Result: Text)
    begin
        Result := GetUrl(Client, Company);
    end;

    [TryFunction]
    local procedure TryObject(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId);
    end;

    [TryFunction]
    local procedure TryRecord(Client: ClientType; Company: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT T Url Row"; UseFilters: Boolean; var Result: Text)
    begin
        Result := GetUrl(Client, Company, ObjType, ObjId, Row, UseFilters);
    end;

    local procedure Company(Client: ClientType; Name: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryCompany(Client, Name, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Obj(Client: ClientType; Name: Text; ObjType: ObjectType; ObjId: Integer): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryObject(Client, Name, ObjType, ObjId, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Rec(Client: ClientType; Name: Text; ObjType: ObjectType; ObjId: Integer; var Row: Record "LT T Url Row"; UseFilters: Boolean): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryRecord(Client, Name, ObjType, ObjId, Row, UseFilters, R) then
            exit('ok|' + Shape(R));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    local procedure Seed(var Row: Record "LT T Url Row")
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'Alpha';
        Row.Insert();
    end;

    local procedure ClientTest(Client: ClientType; Tag: Text)
    var
        Row: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Observer.Observe(Tag + ' alone', Shape(GetUrl(Client)));
        Observer.Observe(Tag + ' company', Company(Client, 'My Company'));
        Observer.Observe(Tag + ' empty company', Company(Client, ''));
        Observer.Observe(Tag + ' page', Obj(Client, '', ObjectType::Page, 21));
        Observer.Observe(Tag + ' company page', Obj(Client, 'My Company', ObjectType::Page, 21));
        Observer.Observe(Tag + ' company report', Obj(Client, 'My Company', ObjectType::Report, 69367));
        Observer.Observe(Tag + ' company page record', Rec(Client, 'My Company', ObjectType::Page, 21, Row, false));
        Observer.Observe(Tag + ' page record no company', Rec(Client, '', ObjectType::Page, 21, Row, false));
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_ClientDefault()
    begin
        ClientTest(ClientType::Default, 'default');
    end;

    [Test]
    procedure GetUrl_ClientWeb()
    begin
        ClientTest(ClientType::Web, 'web');
    end;

    [Test]
    procedure GetUrl_ClientWindows()
    begin
        ClientTest(ClientType::Windows, 'windows');
    end;

    [Test]
    procedure GetUrl_ClientPhone()
    begin
        ClientTest(ClientType::Phone, 'phone');
    end;

    [Test]
    procedure GetUrl_ClientTablet()
    begin
        ClientTest(ClientType::Tablet, 'tablet');
    end;

    [Test]
    procedure GetUrl_ClientDesktop()
    begin
        ClientTest(ClientType::Desktop, 'desktop');
    end;

    [Test]
    procedure GetUrl_Web_CompanyCharacters()
    begin
        Observer.Observe('comma', Company(ClientType::Web, 'CRONUS USA, Inc.'));
        Observer.Observe('underscore', Company(ClientType::Web, 'A_B'));
        Observer.Observe('parentheses', Company(ClientType::Web, 'A(B)'));
        Observer.Observe('semicolon', Company(ClientType::Web, 'A;B'));
        Observer.Observe('colon', Company(ClientType::Web, 'A:B'));
        Observer.Observe('plus', Company(ClientType::Web, 'A+B'));
        Observer.Observe('at', Company(ClientType::Web, 'A@B'));
        Observer.Observe('exclamation', Company(ClientType::Web, 'A!B'));
        Observer.Observe('hash', Company(ClientType::Web, 'A#B'));
        Observer.Observe('percent', Company(ClientType::Web, 'A%B'));
        Observer.Observe('equals', Company(ClientType::Web, 'A=B'));
        Observer.Observe('question', Company(ClientType::Web, 'A?B'));
        Observer.Observe('dash dot tilde', Company(ClientType::Web, 'A-B.C~D'));
        Observer.Observe('star dollar', Company(ClientType::Web, 'A*B$C'));
        Observer.Observe('brackets', Company(ClientType::Web, 'A[B]{C}'));
        Observer.Observe('backslash', Company(ClientType::Web, 'A\B'));
        Observer.Observe('less greater', Company(ClientType::Web, 'A<B>C'));
        Observer.Observe('pipe caret', Company(ClientType::Web, 'A|B^C'));
        Observer.Observe('double quote', Company(ClientType::Web, 'A"B'));
        Observer.Observe('plus in object url', Obj(ClientType::Web, 'A+B,C', ObjectType::Page, 21));
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Web_FilterCharacters()
    var
        Row: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Row.SetFilter(Name, '%1', 'A,B');
        Observer.Observe('comma', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A_B');
        Observer.Observe('underscore', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A(B)');
        Observer.Observe('parentheses', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A;B');
        Observer.Observe('semicolon', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A:B');
        Observer.Observe('colon', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A+B');
        Observer.Observe('plus', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A@B');
        Observer.Observe('at', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, '%1', 'A!B');
        Observer.Observe('exclamation', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Row.SetFilter(Name, 'A*|B..C');
        Observer.Observe('filter expression', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Row, true));
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Web_ReportQueryCodeunitWithRecord()
    var
        Row: Record "LT T Url Row";
        Rep: Record "LT T Url Row";
    begin
        Seed(Row);
        Row.Get(5);
        Observer.Observe('report', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Row, false));
        Observer.Observe('query', Rec(ClientType::Web, 'My Company', ObjectType::Query, 69376, Row, false));
        Observer.Observe('codeunit', Rec(ClientType::Web, 'My Company', ObjectType::Codeunit, 69366, Row, false));
        Observer.Observe('table', Rec(ClientType::Web, 'My Company', ObjectType::Table, 69380, Row, false));
        Observer.Observe('report no company', Rec(ClientType::Web, '', ObjectType::Report, 69367, Row, false));
        Observer.Observe('query no company', Rec(ClientType::Web, '', ObjectType::Query, 69376, Row, false));
        Observer.Observe('codeunit no company', Rec(ClientType::Web, '', ObjectType::Codeunit, 69366, Row, false));
        Rep.SetRange(Name, 'Alpha');
        Observer.Observe('report with filter', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Rep, false));
        Observer.Observe('report with filter use filters', Rec(ClientType::Web, 'My Company', ObjectType::Report, 69367, Rep, true));
        Observer.Observe('page with filter use filters', Rec(ClientType::Web, 'My Company', ObjectType::Page, 21, Rep, true));
        Observer.Observe('report without record', Obj(ClientType::Web, 'My Company', ObjectType::Report, 69367));
        Observer.Observe('query without record', Obj(ClientType::Web, 'My Company', ObjectType::Query, 69376));
        Observer.Observe('codeunit without record', Obj(ClientType::Web, 'My Company', ObjectType::Codeunit, 69366));
        Observer.Finish();
    end;

    [Test]
    procedure GetUrl_Web_BookmarkOfCodeKeys()
    var
        C10: Record "LT T Url Code10";
        C50: Record "LT T Url Code50";
        Two: Record "LT T Url Two";
    begin
        C10.DeleteAll();
        C50.DeleteAll();
        Two.DeleteAll();
        C10.K := 'A1';
        C10.Insert();
        Observer.Observe('code10 short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C10, false)));
        C10.K := 'ABCDEFGHIJ';
        C10.Insert();
        Observer.Observe('code10 full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C10, false)));
        C50.K := 'A1';
        C50.Insert();
        Observer.Observe('code50 short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        C50.K := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMN';
        C50.Insert();
        Observer.Observe('code50 full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        C50.K := 'A-B_C.D';
        C50.Insert();
        Observer.Observe('code50 symbols', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, C50, false)));
        Two.K1 := 'A1';
        Two.K2 := 'B2';
        Two.Insert();
        Observer.Observe('two short', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := 'ABCDEFGHIJKLMNOPQRST';
        Two.K2 := 'UVWXYZ0123456789ABCD';
        Two.Insert();
        Observer.Observe('two full', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := 'A';
        Two.K2 := '';
        Two.Insert();
        Observer.Observe('two second empty', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Two.K1 := '';
        Two.K2 := 'B';
        Two.Insert();
        Observer.Observe('two first empty', Shape(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, 21, Two, false)));
        Observer.Finish();
    end;
}

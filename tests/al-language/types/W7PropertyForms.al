// Batch 7 probes: Mark, MarkedOnly, Ascending, FilterGroup, WorkDate, UseRequestPage and ErrorInfo members as assignments and as calls. Observe only.
table 68555 "W7 PF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure AssignUnqualified(): Text
    begin
        Mark := true;
        MarkedOnly := false;
        Ascending := false;
        FilterGroup := 3;
        exit('mark=' + Format(Mark()) + ' marked only=' + Format(MarkedOnly()) + ' ascending=' + Format(Ascending()) + ' filter group=' + Format(FilterGroup()));
    end;

    procedure CallUnqualified(): Text
    begin
        Mark(true);
        MarkedOnly(false);
        Ascending(false);
        FilterGroup(3);
        exit('mark=' + Format(Mark) + ' marked only=' + Format(MarkedOnly) + ' ascending=' + Format(Ascending) + ' filter group=' + Format(FilterGroup));
    end;
}

report 68557 "W7 PF Report"
{
    ProcessingOnly = true;
    UseRequestPage = true;
}

codeunit 68556 "W7 Property Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W7 PF Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
    end;

    [Test]
    procedure Mark_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 PF Row";
    begin
        Seed();
        Row.Get(2);
        Observer.Observe('before', Format(Row.Mark()));
        Row.Mark := true;
        Observer.Observe('after assignment, read as call', Format(Row.Mark()));
        Observer.Observe('after assignment, read as property', Format(Row.Mark));
        Row.Mark(false);
        Observer.Observe('after call with false, read as property', Format(Row.Mark));
        Row.Mark(true);
        Observer.Observe('after call with true, read as call', Format(Row.Mark()));
        Row.Mark := false;
        Observer.Observe('after assignment of false', Format(Row.Mark()));
        Row.Mark := not Row.Mark;
        Observer.Observe('after assignment of not Mark', Format(Row.Mark()));
        Row.Get(1);
        Observer.Observe('other record, not marked', Format(Row.Mark()));
        Row.Mark := true;
        Row.Get(3);
        Row.Mark(true);
        Row.MarkedOnly(true);
        Observer.Observe('marked only count', Format(Row.Count()));
        Row.MarkedOnly := false;
        Observer.Observe('count after MarkedOnly := false', Format(Row.Count()));
        Observer.Expect('before', 'No');
        Observer.Expect('after assignment, read as call', 'Yes');
        Observer.Expect('after assignment, read as property', 'Yes');
        Observer.Expect('after call with false, read as property', 'No');
        Observer.Expect('after call with true, read as call', 'Yes');
        Observer.Expect('after assignment of false', 'No');
        Observer.Expect('after assignment of not Mark', 'Yes');
        Observer.Expect('other record, not marked', 'No');
        Observer.Expect('marked only count', '3');
        Observer.Expect('count after MarkedOnly := false', '3');
        Observer.Verify();
    end;

    [Test]
    procedure MarkedOnly_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 PF Row";
    begin
        Seed();
        Row.Get(1);
        Row.Mark(true);
        Row.Get(3);
        Row.Mark(true);
        Observer.Observe('start', Format(Row.MarkedOnly()));
        Row.MarkedOnly := true;
        Observer.Observe('after assignment, read as call', Format(Row.MarkedOnly()));
        Observer.Observe('after assignment, read as property', Format(Row.MarkedOnly));
        Observer.Observe('count', Format(Row.Count()));
        Row.MarkedOnly(false);
        Observer.Observe('after call, read as property', Format(Row.MarkedOnly));
        Observer.Observe('count after call', Format(Row.Count()));
        Row.MarkedOnly := true;
        Row.FindFirst();
        Observer.Observe('first marked', Format(Row.Id));
        Row.MarkedOnly := false;
        Row.Reset();
        Observer.Observe('after Reset', Format(Row.MarkedOnly()));
        Observer.Expect('start', 'No');
        Observer.Expect('after assignment, read as call', 'Yes');
        Observer.Expect('after assignment, read as property', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('after call, read as property', 'No');
        Observer.Expect('count after call', '3');
        Observer.Expect('first marked', '1');
        Observer.Expect('after Reset', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Ascending_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 PF Row";
    begin
        Seed();
        Observer.Observe('start', Format(Row.Ascending()));
        Row.Ascending := false;
        Observer.Observe('after assignment, read as call', Format(Row.Ascending()));
        Observer.Observe('after assignment, read as property', Format(Row.Ascending));
        Row.FindFirst();
        Observer.Observe('first row, descending', Format(Row.Id));
        Row.Ascending(true);
        Observer.Observe('after call, read as property', Format(Row.Ascending));
        Row.FindFirst();
        Observer.Observe('first row, ascending', Format(Row.Id));
        Row.Ascending := false;
        Row.Reset();
        Observer.Observe('after Reset', Format(Row.Ascending()));
        Observer.Expect('start', 'Yes');
        Observer.Expect('after assignment, read as call', 'No');
        Observer.Expect('after assignment, read as property', 'No');
        Observer.Expect('first row, descending', '3');
        Observer.Expect('after call, read as property', 'Yes');
        Observer.Expect('first row, ascending', '1');
        Observer.Expect('after Reset', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FilterGroup_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 PF Row";
    begin
        Seed();
        Observer.Observe('start', Format(Row.FilterGroup()));
        Row.FilterGroup := 2;
        Observer.Observe('after assignment, read as call', Format(Row.FilterGroup()));
        Observer.Observe('after assignment, read as property', Format(Row.FilterGroup));
        Row.SetRange(Id, 2);
        Row.FilterGroup := 0;
        Observer.Observe('count in group 0', Format(Row.Count()));
        Row.FilterGroup(2);
        Observer.Observe('count in group 2', Format(Row.Count()));
        Observer.Observe('group 2 filter', Row.GetFilter(Id));
        Row.FilterGroup := 0;
        Observer.Observe('group 0 filter', Row.GetFilter(Id));
        Row.FilterGroup(5);
        Observer.Observe('group 5 as property', Format(Row.FilterGroup));
        Row.FilterGroup := -1;
        Observer.Observe('group -1', Format(Row.FilterGroup));
        Observer.Expect('start', '0');
        Observer.Expect('after assignment, read as call', '2');
        Observer.Expect('after assignment, read as property', '2');
        Observer.Expect('count in group 0', '1');
        Observer.Expect('count in group 2', '1');
        Observer.Expect('group 2 filter', '2');
        Observer.Expect('group 0 filter', '');
        Observer.Expect('group 5 as property', '5');
        Observer.Expect('group -1', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure Record_UnqualifiedMembersInATableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 PF Row";
        Other: Record "W7 PF Row";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('assignment forms', Row.AssignUnqualified());
        Observer.Observe('record after: mark', Format(Row.Mark()));
        Observer.Observe('record after: filter group', Format(Row.FilterGroup()));
        Other.Get(2);
        Observer.Observe('call forms', Other.CallUnqualified());
        Observer.Observe('other record after: mark', Format(Other.Mark()));
        Observer.Expect('assignment forms', 'mark=Yes marked only=No ascending=No filter group=3');
        Observer.Expect('record after: mark', 'Yes');
        Observer.Expect('record after: filter group', '3');
        Observer.Expect('call forms', 'mark=Yes marked only=No ascending=No filter group=3');
        Observer.Expect('other record after: mark', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WorkDate_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate := DMY2Date(5, 3, 2024);
        Observer.Observe('after assignment, read as call', Format(WorkDate(), 0, 9));
        Observer.Observe('after assignment, read as property', Format(WorkDate, 0, 9));
        WorkDate(DMY2Date(6, 3, 2024));
        Observer.Observe('after call, read as property', Format(WorkDate, 0, 9));
        WorkDate := WorkDate + 1;
        Observer.Observe('after WorkDate := WorkDate + 1', Format(WorkDate(), 0, 9));
        WorkDate(Saved);
        Observer.Expect('after assignment, read as call', '2024-03-05');
        Observer.Expect('after assignment, read as property', '2024-03-05');
        Observer.Expect('after call, read as property', '2024-03-06');
        Observer.Expect('after WorkDate := WorkDate + 1', '2024-03-07');
        Observer.Verify();
    end;

    [Test]
    procedure Report_UseRequestPage_AssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "W7 PF Report";
    begin
        Observer.Observe('start', Format(Rep.UseRequestPage()));
        Rep.UseRequestPage := false;
        Observer.Observe('after assignment, read as call', Format(Rep.UseRequestPage()));
        Observer.Observe('after assignment, read as property', Format(Rep.UseRequestPage));
        Rep.UseRequestPage(true);
        Observer.Observe('after call, read as property', Format(Rep.UseRequestPage));
        Observer.Expect('start', 'Yes');
        Observer.Expect('after assignment, read as call', 'No');
        Observer.Expect('after assignment, read as property', 'No');
        Observer.Expect('after call, read as property', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_MembersAsAssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
    begin
        Info.Message := 'assigned message';
        Observer.Observe('Message as call', Info.Message());
        Info.Message('called message');
        Observer.Observe('Message as property', Info.Message);
        Info.DetailedMessage := 'assigned detail';
        Observer.Observe('DetailedMessage as call', Info.DetailedMessage());
        Info.DetailedMessage('called detail');
        Observer.Observe('DetailedMessage as property', Info.DetailedMessage);
        Info.Title := 'assigned title';
        Observer.Observe('Title as call', Info.Title());
        Info.ControlName := 'assigned control';
        Observer.Observe('ControlName as call', Info.ControlName());
        Info.FieldNo := 7;
        Observer.Observe('FieldNo as call', Format(Info.FieldNo()));
        Info.PageNo := 42;
        Observer.Observe('PageNo as call', Format(Info.PageNo()));
        Info.TableId := 18;
        Observer.Observe('TableId as call', Format(Info.TableId()));
        Info.Verbosity := Verbosity::Warning;
        Observer.Observe('Verbosity as call', Format(Info.Verbosity()));
        Info.DataClassification := DataClassification::CustomerContent;
        Observer.Observe('DataClassification as call', Format(Info.DataClassification()));
        Info.Collectible := true;
        Observer.Observe('Collectible as call', Format(Info.Collectible()));
        Info.ErrorType := ErrorType::Client;
        Observer.Observe('ErrorType as call', Format(Info.ErrorType()));
        Observer.Expect('Message as call', 'assigned message');
        Observer.Expect('Message as property', 'called message');
        Observer.Expect('DetailedMessage as call', 'assigned detail');
        Observer.Expect('DetailedMessage as property', 'called detail');
        Observer.Expect('Title as call', 'assigned title');
        Observer.Expect('ControlName as call', 'assigned control');
        Observer.Expect('FieldNo as call', '7');
        Observer.Expect('PageNo as call', '42');
        Observer.Expect('TableId as call', '18');
        Observer.Expect('Verbosity as call', 'Warning');
        Observer.Expect('DataClassification as call', 'CustomerContent');
        Observer.Expect('Collectible as call', 'Yes');
        Observer.Expect('ErrorType as call', 'Client');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_CustomDimensionsAssignmentAndCall()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Dimensions: Dictionary of [Text, Text];
        Back: Dictionary of [Text, Text];
    begin
        Dimensions.Add('k', 'v');
        Info.CustomDimensions := Dimensions;
        Back := Info.CustomDimensions();
        Observer.Observe('count as call', Format(Back.Count()));
        Observer.Observe('value as call', Back.Get('k'));
        Info.CustomDimensions(Back);
        Observer.Observe('count as property', Format(Info.CustomDimensions.Count()));
        Observer.Expect('count as call', '1');
        Observer.Expect('value as call', 'v');
        Observer.Expect('count as property', '1');
        Observer.Verify();
    end;
}

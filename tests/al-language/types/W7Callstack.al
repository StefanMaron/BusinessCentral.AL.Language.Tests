// Batch 7 probes: GetLastErrorCallStack through queries, xmlports and table events; ErrorInfo.Callstack. Observe only.
table 68546 "W7 CS Row"
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
}

codeunit 68547 "W7 CS Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"W7 CS Row", 'OnAfterValidateEvent', 'Txt', false, false)]
    local procedure AfterValidateTxt(var Rec: Record "W7 CS Row")
    begin
        if Rec.Txt = 'FAIL' then
            Error('validate subscriber fails');
    end;

    [EventSubscriber(ObjectType::Table, Database::"W7 CS Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "W7 CS Row")
    begin
        if Rec.Txt = 'FAIL' then
            Error('delete subscriber fails');
    end;

    [EventSubscriber(ObjectType::Table, Database::"W7 CS Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "W7 CS Row")
    begin
        if Rec.Txt = 'FAIL' then
            Error('modify subscriber fails');
    end;

    [EventSubscriber(ObjectType::Table, Database::"W7 CS Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRename(var Rec: Record "W7 CS Row")
    begin
        if Rec.Txt = 'FAIL' then
            Error('rename subscriber fails');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"W7 CS Publisher", 'OnSomething', '', false, false)]
    local procedure OnSomething(Fail: Boolean)
    begin
        if Fail then
            Error('integration event subscriber fails');
    end;
}

codeunit 68548 "W7 CS Publisher"
{
    procedure Raise(Fail: Boolean)
    begin
        OnSomething(Fail);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSomething(Fail: Boolean)
    begin
    end;
}

query 68549 "W7 CS Query"
{
    elements
    {
        dataitem(Row; "W7 CS Row")
        {
            column(Id; Id) { }
        }
    }

    var
        FailOnOpen: Boolean;

    trigger OnBeforeOpen()
    begin
        if FailOnOpen then
            Error('query OnBeforeOpen fails');
    end;

    procedure SetFailOnOpen(NewValue: Boolean)
    begin
        FailOnOpen := NewValue;
    end;

    procedure Fail()
    begin
        Error('query procedure fails');
    end;
}

xmlport 68550 "W7 CS XmlPort"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Item)
            {
                trigger OnBeforePassVariable()
                begin
                    if FailAt = 2 then
                        Error('xmlport element trigger fails');
                    Item := 'x';
                end;
            }
            tableelement(T; "W7 CS Row")
            {
                fieldelement(Id; T.Id) { }

                trigger OnAfterGetRecord()
                begin
                    if T.Txt = 'FAIL' then
                        Error('xmlport OnAfterGetRecord fails');
                end;
            }
        }
    }

    var
        FailAt: Integer;

    trigger OnPreXmlPort()
    begin
        if FailAt = 1 then
            Error('xmlport OnPreXmlPort fails');
    end;

    trigger OnPostXmlPort()
    begin
        if FailAt = 3 then
            Error('xmlport OnPostXmlPort fails');
    end;

    procedure SetFailAt(NewValue: Integer)
    begin
        FailAt := NewValue;
    end;

    procedure Fail()
    begin
        Error('xmlport procedure fails');
    end;
}

codeunit 68551 "W7 Callstack Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveStack(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + '|stack', GetLastErrorCallStack());
        Observer.ObserveError(Name);
    end;

}

codeunit 68552 "W7 ErrorInfo Callstack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RaiseWithInfo()
    var
        Info: ErrorInfo;
    begin
        Info.Message := 'raised with ErrorInfo';
        Error(Info);
    end;

    local procedure Inner()
    begin
        RaiseWithInfo();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RaiseCollectible(var Errors: List of [ErrorInfo])
    var
        Info: ErrorInfo;
    begin
        Info.Message := 'collectible';
        Info.Collectible := true;
        Error(Info);
        Errors := GetCollectedErrors();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNested(var Errors: List of [ErrorInfo])
    begin
        NestedCollectible();
        Errors := GetCollectedErrors();
    end;

    local procedure NestedCollectible()
    var
        Info: ErrorInfo;
    begin
        Info.Message := 'nested collectible';
        Info.Collectible := true;
        Error(Info);
    end;

    [Test]
    procedure ErrorInfoCallstack_OfAnErrorCreatedAndNotRaised()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
    begin
        Info := ErrorInfo.Create('created, never raised');
        Observer.Observe('created ErrorInfo callstack', Info.Callstack);
        Observer.Expect('created ErrorInfo callstack', '');
        Observer.Verify();
    end;
}

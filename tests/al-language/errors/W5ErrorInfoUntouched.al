// Batch 5, md:470 / ErrorInfo row (md:314 of probes-needed.md now says the Create() defaults and RecordId assignment are PINNED): what is still open is an
// ErrorInfo that was declared and never created, read for Collectible, Verbosity, ErrorType and the other properties.

codeunit 67048 "W5 ErrorInfo Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ErrorInfo_DeclaredNeverCreated_Properties()
    var
        Observer: Codeunit "Probe Observer";
        Untouched: ErrorInfo;
        Created: ErrorInfo;
        UntouchedText: Text;
        CreatedText: Text;
        Differing: Text;
        What: Integer;
    begin
        Created := ErrorInfo.Create();
        for What := 1 to 14 do begin
            UntouchedText := Read(What, Untouched);
            CreatedText := Read(What, Created);
            Observer.Observe('untouched_' + Format(What), UntouchedText);
            if UntouchedText <> CreatedText then
                Differing += Format(What) + ',';
        end;
        Observer.Observe('property_numbers_that_differ_from_a_created_one', '[' + Differing + ']');
        Observer.Expect('untouched_1', '[collectible=No]');
        Observer.Expect('untouched_2', '[verbosity=Error]');
        Observer.Expect('untouched_3', '[errortype=Client]');
        Observer.Expect('untouched_4', '[dataclassification=CustomerContent]');
        Observer.Expect('untouched_5', '[message=]');
        Observer.Expect('untouched_6', '[detailedmessage=]');
        Observer.Expect('untouched_7', '[title=]');
        Observer.Expect('untouched_8', '[recordid=]');
        Observer.Expect('untouched_9', '[tableid=0]');
        Observer.Expect('untouched_10', '[pageno=0]');
        Observer.Expect('untouched_11', '[fieldno=0]');
        Observer.Expect('untouched_12', '[controlname=]');
        Observer.Expect('untouched_13', '[customdimensions=0]');
        Observer.Expect('untouched_14', '[systemid_null=Yes]');
        Observer.Expect('property_numbers_that_differ_from_a_created_one', '[1,]');
        Observer.Verify();
    end;

    // The property named by What, read inside a Try so that a refused read shows as text.
    local procedure Read(What: Integer; var Info: ErrorInfo): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryRead(What, Info, Res) then
            exit('[' + Res + ']');
        Res := 'ERR:' + GetLastErrorText();
        ClearLastError();
        exit(Res);
    end;

    [TryFunction]
    local procedure TryRead(What: Integer; var Info: ErrorInfo; var Res: Text)
    begin
        case What of
            1:
                Res := 'collectible=' + Format(Info.Collectible());
            2:
                Res := 'verbosity=' + Format(Info.Verbosity());
            3:
                Res := 'errortype=' + Format(Info.ErrorType());
            4:
                Res := 'dataclassification=' + Format(Info.DataClassification());
            5:
                Res := 'message=' + Info.Message();
            6:
                Res := 'detailedmessage=' + Info.DetailedMessage();
            7:
                Res := 'title=' + Info.Title();
            8:
                Res := 'recordid=' + Format(Info.RecordId());
            9:
                Res := 'tableid=' + Format(Info.TableId());
            10:
                Res := 'pageno=' + Format(Info.PageNo());
            11:
                Res := 'fieldno=' + Format(Info.FieldNo());
            12:
                Res := 'controlname=' + Info.ControlName();
            13:
                Res := 'customdimensions=' + Format(Info.CustomDimensions().Count());
            14:
                Res := 'systemid_null=' + Format(IsNullGuid(Info.SystemId()));
        end;
    end;
}

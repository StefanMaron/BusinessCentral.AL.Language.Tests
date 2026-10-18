// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-fields
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 78308, subscriber codeunit 78309, test codeunit 78310
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: SystemId assigned inside an OnBeforeInsert subscriber: is the value kept by Insert(), Insert(true) and InsertWithSystemId, what the stored row holds,
// and what the subscriber sees in SystemId before it assigns.
// BC versions: 27, 28, 29

table 78308 "LT AF Sys"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 78309 "LT AF Sys Subscriber"
{
    SingleInstance = true;

    var
        Wanted: Guid;
        Enabled: Boolean;
        Log: Text;

    procedure Arm(NewWanted: Guid)
    begin
        Wanted := NewWanted;
        Enabled := true;
        Log := '';
    end;

    procedure Disarm()
    begin
        Enabled := false;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT AF Sys", OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeInsert(var Rec: Record "LT AF Sys"; RunTrigger: Boolean)
    var
        NullId: Guid;
    begin
        if not Enabled then
            exit;
        Log += 'null before=' + Format(Rec.SystemId = NullId) + '; ';
        Rec.SystemId := Wanted;
        Log += 'set=' + Format(Rec.SystemId = Wanted) + '; ';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT AF Sys", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "LT AF Sys"; RunTrigger: Boolean)
    begin
        if not Enabled then
            exit;
        Log += 'after insert event=' + Format(Rec.SystemId = Wanted) + '; ';
    end;
}

codeunit 78310 "LT AF SystemId BeforeInsert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Subscriber: Codeunit "LT AF Sys Subscriber";

    local procedure Run(Name: Text; Mode: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AF Sys";
        Stored: Record "LT AF Sys";
        Wanted: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Wanted := CreateGuid();
        Subscriber.Arm(Wanted);
        Row.Id := 1;
        Row.Note := 'n';
        ClearLastError();
        case Mode of
            0:
                Ok := Row.Insert();
            1:
                Ok := Row.Insert(true);
            2:
                Ok := Row.Insert(false, true);
        end;
        Subscriber.Disarm();
        Observer.Observe(Name + '|insert', Format(Ok));
        Observer.Observe(Name + '|subscriber', Subscriber.Take());
        Observer.Observe(Name + '|caller keeps', Format(Row.SystemId = Wanted));
        Observer.Observe(Name + '|stored', Format(Stored.Get(1)));
        Observer.Observe(Name + '|stored keeps', Format(Stored.SystemId = Wanted));
        Observer.Finish();
    end;

    [Test]
    procedure AF_SystemId_In_OnBeforeInsert_Insert()
    begin
        Run('insert()', 0);
    end;

    [Test]
    procedure AF_SystemId_In_OnBeforeInsert_InsertTrue()
    begin
        Run('insert(true)', 1);
    end;

    [Test]
    procedure AF_SystemId_In_OnBeforeInsert_InsertWithSystemId()
    begin
        Run('insert(false, true)', 2);
    end;
}

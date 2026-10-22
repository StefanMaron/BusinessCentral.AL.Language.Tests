// Objects of cross-app fixture B for writer QY's probes. See tests/al-language-xapp-a/QyXaObjects.al.
//   61117 / 61147: subscribers of "LT QY XA Order Publisher"; 61117 is lower than A's only subscriber 61138, 61147 higher.
//   61114 "LT QY XB Base Third Ext": a third table extension of "LT BW XA Base" (besides 61110 and 61113 of this app) that calls BwSame() and
//         BwCaseName(), which both table 61101 of app A and table extension 61113 of this app declare. It compiles in this app; in another
//         app the same calls are AL0196 (must-not-compile 2071).
//   61115 "LT QY XB Rename Blobs Ext": adds a Blob field to app A's table 61104.

codeunit 61117 "LT QY XB A Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyOrder', '', false, false)]
    local procedure OnQyOrder(var Log: Text)
    begin
        Log += 'B1;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'B1;';
    end;
}

codeunit 61147 "LT QY XB Z Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyOrder', '', false, false)]
    local procedure OnQyOrder(var Log: Text)
    begin
        Log += 'B2;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'B2;';
    end;
}

tableextension 61114 "LT QY XB Base Third Ext" extends "LT BW XA Base"
{
    procedure QyCallSameBare(): Text
    begin
        exit(BwSame());
    end;

    procedure QyCallSameRec(): Text
    begin
        exit(Rec.BwSame());
    end;

    procedure QyCallCaseNameBare(): Text
    begin
        exit(BwCaseName());
    end;
}

tableextension 61115 "LT QY XB Rename Blobs Ext" extends "LT QY XA Rename Blobs"
{
    fields
    {
        field(61114; "QY XB Blob"; Blob)
        {
            DataClassification = SystemMetadata;
        }
    }
}

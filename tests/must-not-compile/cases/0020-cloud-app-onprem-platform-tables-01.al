// @expect AL0296 | The application object or method 'API Webhook Entity' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'API Webhook Notification Aggr' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'API Webhook Notification' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'API Webhook Subscription' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Database' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Debugger Breakpoint' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Debugger Call Stack' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Debugger Variable' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Debugger Watch Value' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Debugger Watch' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Document Service' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Drive' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'File' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Isolated Storage' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Object Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Object' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Permission Range' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Profile Configuration Symbols' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Profile Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Profile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'SID - Account ID' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Send-To Program' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Server Instance' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Style Sheet' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'System Object' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Table Information' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Profile Extension' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Profile Setting' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Upgrade Blob Storage' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Web Service' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0433 | Table 'Debugger Breakpoint' is removed. Reason: Support for the classic debugger engine has been removed..
// @expect AL0433 | Table 'Debugger Call Stack' is removed. Reason: Support for the classic debugger engine has been removed..
// @expect AL0433 | Table 'Debugger Variable' is removed. Reason: Support for the classic debugger engine has been removed..
// @expect AL0433 | Table 'Debugger Watch' is removed. Reason: Support for the classic debugger engine has been removed..
// @expect AL0433 | Table 'Profile Metadata' is removed. Reason: Support for System Profiles has been removed. Profiles should now be defined in AL extensions and should be accessed through the All Profile virtual table.. Tag: 22.0.
// @expect AL0433 | Table 'Profile' is removed. Reason: Support for System Profiles has been removed. Profiles should now be defined in AL extensions and should be accessed through the All Profile virtual table.. Tag: 22.0.
// @until 27
// @from 27
// group
codeunit 50000 "MNC OnPrem Tables"
{
    procedure P0(): Integer
    var
        R: Record "Object";
    begin
        exit(R.Count());
    end;

    procedure P1(): Integer
    var
        R: Record "Drive";
    begin
        exit(R.Count());
    end;

    procedure P2(): Integer
    var
        R: Record "File";
    begin
        exit(R.Count());
    end;

    procedure P3(): Integer
    var
        R: Record "Table Information";
    begin
        exit(R.Count());
    end;

    procedure P4(): Integer
    var
        R: Record "System Object";
    begin
        exit(R.Count());
    end;

    procedure P5(): Integer
    var
        R: Record "Permission Range";
    begin
        exit(R.Count());
    end;

    procedure P6(): Integer
    var
        R: Record "Database";
    begin
        exit(R.Count());
    end;

    procedure P7(): Integer
    var
        R: Record "SID - Account ID";
    begin
        exit(R.Count());
    end;

    procedure P8(): Integer
    var
        R: Record "Send-To Program";
    begin
        exit(R.Count());
    end;

    procedure P9(): Integer
    var
        R: Record "Style Sheet";
    begin
        exit(R.Count());
    end;

    procedure P10(): Integer
    var
        R: Record "Object Metadata";
    begin
        exit(R.Count());
    end;

    procedure P11(): Integer
    var
        R: Record "Profile";
    begin
        exit(R.Count());
    end;

    procedure P12(): Integer
    var
        R: Record "Profile Metadata";
    begin
        exit(R.Count());
    end;

    procedure P13(): Integer
    var
        R: Record "Web Service";
    begin
        exit(R.Count());
    end;

    procedure P14(): Integer
    var
        R: Record "Upgrade Blob Storage";
    begin
        exit(R.Count());
    end;

    procedure P15(): Integer
    var
        R: Record "Tenant Profile Setting";
    begin
        exit(R.Count());
    end;

    procedure P16(): Integer
    var
        R: Record "Tenant Profile Extension";
    begin
        exit(R.Count());
    end;

    procedure P17(): Integer
    var
        R: Record "Profile Configuration Symbols";
    begin
        exit(R.Count());
    end;

    procedure P18(): Integer
    var
        R: Record "API Webhook Subscription";
    begin
        exit(R.Count());
    end;

    procedure P19(): Integer
    var
        R: Record "API Webhook Notification";
    begin
        exit(R.Count());
    end;

    procedure P20(): Integer
    var
        R: Record "API Webhook Entity";
    begin
        exit(R.Count());
    end;

    procedure P21(): Integer
    var
        R: Record "API Webhook Notification Aggr";
    begin
        exit(R.Count());
    end;

    procedure P22(): Integer
    var
        R: Record "Debugger Breakpoint";
    begin
        exit(R.Count());
    end;

    procedure P23(): Integer
    var
        R: Record "Debugger Call Stack";
    begin
        exit(R.Count());
    end;

    procedure P24(): Integer
    var
        R: Record "Debugger Variable";
    begin
        exit(R.Count());
    end;

    procedure P25(): Integer
    var
        R: Record "Debugger Watch Value";
    begin
        exit(R.Count());
    end;

    procedure P26(): Integer
    var
        R: Record "Debugger Watch";
    begin
        exit(R.Count());
    end;

    procedure P27(): Integer
    var
        R: Record "Isolated Storage";
    begin
        exit(R.Count());
    end;

    procedure P28(): Integer
    var
        R: Record "Server Instance";
    begin
        exit(R.Count());
    end;

    procedure P29(): Integer
    var
        R: Record "Document Service";
    begin
        exit(R.Count());
    end;

}

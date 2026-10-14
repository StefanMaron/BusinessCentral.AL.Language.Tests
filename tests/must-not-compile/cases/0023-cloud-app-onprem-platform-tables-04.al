// @expect AL0161 | 'Table System.Agents.Internal."Agent Access Control Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task File Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Log Entry Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Memory Entry Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Message Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Msg Attach Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task Timeline Step Data"' is inaccessible due to its protection level
// @expect AL0161 | 'Table System.Agents.Internal."Agent Task User Int. Data"' is inaccessible due to its protection level
// @expect AL0296 | The application object or method 'Agent Access Control Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task File Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Log Entry Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Log Entry' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Memory Entry Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Memory Entry' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Message Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Msg Attach Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Page Script' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Timeline Step Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Timeline Step Det.' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Timeline Step' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task Timeline' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent Task User Int. Data' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Agent' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Ext. Business Event Definition' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Extension Database Snapshot' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'External Event Activity Log' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'External Event Log Entry' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'External Event Notification' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'External Event Subscription' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'MCP Configuration Tool' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'MCP Configuration' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Page Usage State' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Performance Profile Scheduler' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Performance Profiles' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Application Storage' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'User Consumption Log Entry' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @until 27
// @from 27
// group
codeunit 50000 "MNC OnPrem Tables"
{
    procedure P0(): Integer
    var
        R: Record "Page Usage State";
    begin
        exit(R.Count());
    end;

    procedure P1(): Integer
    var
        R: Record "Tenant Application Storage";
    begin
        exit(R.Count());
    end;

    procedure P2(): Integer
    var
        R: Record "External Event Subscription";
    begin
        exit(R.Count());
    end;

    procedure P3(): Integer
    var
        R: Record "External Event Log Entry";
    begin
        exit(R.Count());
    end;

    procedure P4(): Integer
    var
        R: Record "External Event Notification";
    begin
        exit(R.Count());
    end;

    procedure P5(): Integer
    var
        R: Record "Ext. Business Event Definition";
    begin
        exit(R.Count());
    end;

    procedure P6(): Integer
    var
        R: Record "Extension Database Snapshot";
    begin
        exit(R.Count());
    end;

    procedure P7(): Integer
    var
        R: Record "External Event Activity Log";
    begin
        exit(R.Count());
    end;

    procedure P8(): Integer
    var
        R: Record "Agent Data";
    begin
        exit(R.Count());
    end;

    procedure P9(): Integer
    var
        R: Record "Agent Access Control Data";
    begin
        exit(R.Count());
    end;

    procedure P10(): Integer
    var
        R: Record "Agent";
    begin
        exit(R.Count());
    end;

    procedure P11(): Integer
    var
        R: Record "Agent Task Memory Entry";
    begin
        exit(R.Count());
    end;

    procedure P12(): Integer
    var
        R: Record "Performance Profile Scheduler";
    begin
        exit(R.Count());
    end;

    procedure P13(): Integer
    var
        R: Record "Performance Profiles";
    begin
        exit(R.Count());
    end;

    procedure P14(): Integer
    var
        R: Record "Agent Task Data";
    begin
        exit(R.Count());
    end;

    procedure P15(): Integer
    var
        R: Record "Agent Task Message Data";
    begin
        exit(R.Count());
    end;

    procedure P16(): Integer
    var
        R: Record "Agent Task Memory Entry Data";
    begin
        exit(R.Count());
    end;

    procedure P17(): Integer
    var
        R: Record "Agent Task User Int. Data";
    begin
        exit(R.Count());
    end;

    procedure P18(): Integer
    var
        R: Record "Agent Task Timeline Step Data";
    begin
        exit(R.Count());
    end;

    procedure P19(): Integer
    var
        R: Record "Agent Task File Data";
    begin
        exit(R.Count());
    end;

    procedure P20(): Integer
    var
        R: Record "Agent Task Msg Attach Data";
    begin
        exit(R.Count());
    end;

    procedure P21(): Integer
    var
        R: Record "Agent Task Timeline Step";
    begin
        exit(R.Count());
    end;

    procedure P22(): Integer
    var
        R: Record "Agent Task Timeline Step Det.";
    begin
        exit(R.Count());
    end;

    procedure P23(): Integer
    var
        R: Record "Agent Task Timeline";
    begin
        exit(R.Count());
    end;

    procedure P24(): Integer
    var
        R: Record "Agent Task Log Entry Data";
    begin
        exit(R.Count());
    end;

    procedure P25(): Integer
    var
        R: Record "Agent Task Log Entry";
    begin
        exit(R.Count());
    end;

    procedure P26(): Integer
    var
        R: Record "User Consumption Log Entry";
    begin
        exit(R.Count());
    end;

    procedure P27(): Integer
    var
        R: Record "Agent Task Page Script";
    begin
        exit(R.Count());
    end;

    procedure P28(): Integer
    var
        R: Record "MCP Configuration";
    begin
        exit(R.Count());
    end;

    procedure P29(): Integer
    var
        R: Record "MCP Configuration Tool";
    begin
        exit(R.Count());
    end;

}

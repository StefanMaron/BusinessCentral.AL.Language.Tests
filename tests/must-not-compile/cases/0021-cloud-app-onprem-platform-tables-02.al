// @expect AL0296 | The application object or method 'Configuration Package File' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Data Sensitivity' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Device' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Document Service Scenario' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Entitlement Set' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Intelligent Cloud Status' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Intelligent Cloud' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Media Set' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Media' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Capabilities' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Data Archive' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Dependencies' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Extra' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Object Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Object Prerequisites' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Publish Reference' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Published App' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Resource' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Tenant App' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Page Table Field' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Power BI Blob' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Power BI Default Selection' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Profile Page Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Table Field Types' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Table Synch. Setup' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Profile Page Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Profile' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'User Page Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'User Property' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0433 | Table 'NAV App Dependencies' is removed. Reason: This table is deprecated in favour of the "Application Dependency" table..
// @expect AL0433 | Table 'NAV App Object Metadata' is removed. Reason: This table is deprecated in favour of the "Application Object Metadata" table..
// @expect AL0433 | Table 'NAV App Publish Reference' is removed. Reason: This table has been deprecated with the support for per tenant extensions..
// @expect AL0433 | Table 'NAV App Published App' is removed. Reason: This table has been deprecated with the support for per tenant extensions..
// @expect AL0433 | Table 'NAV App Resource' is removed. Reason: This table is deprecated in favour of the "Application Resource" table..
// @expect AL0433 | Table 'NAV App Tenant App' is removed. Reason: This table is deprecated in favour of the "Installed Application" table..
// @expect AL0433 | Table 'NAV App' is removed. Reason: This table is deprecated in favour of the "Published Application" table..
// @expect AL0433 | Table 'Profile Page Metadata' is removed. Reason: Support for System Profiles has been removed. Profiles should now be defined in AL extensions and should be accessed through the All Profile virtual table.. Tag: 22.0.
// @until 27
// @from 27
// group
codeunit 50000 "MNC OnPrem Tables"
{
    procedure P0(): Integer
    var
        R: Record "Document Service Scenario";
    begin
        exit(R.Count());
    end;

    procedure P1(): Integer
    var
        R: Record "User Property";
    begin
        exit(R.Count());
    end;

    procedure P2(): Integer
    var
        R: Record "Device";
    begin
        exit(R.Count());
    end;

    procedure P3(): Integer
    var
        R: Record "Table Synch. Setup";
    begin
        exit(R.Count());
    end;

    procedure P4(): Integer
    var
        R: Record "Power BI Blob";
    begin
        exit(R.Count());
    end;

    procedure P5(): Integer
    var
        R: Record "Power BI Default Selection";
    begin
        exit(R.Count());
    end;

    procedure P6(): Integer
    var
        R: Record "Intelligent Cloud";
    begin
        exit(R.Count());
    end;

    procedure P7(): Integer
    var
        R: Record "NAV App Object Metadata";
    begin
        exit(R.Count());
    end;

    procedure P8(): Integer
    var
        R: Record "NAV App Tenant App";
    begin
        exit(R.Count());
    end;

    procedure P9(): Integer
    var
        R: Record "NAV App Data Archive";
    begin
        exit(R.Count());
    end;

    procedure P10(): Integer
    var
        R: Record "NAV App Publish Reference";
    begin
        exit(R.Count());
    end;

    procedure P11(): Integer
    var
        R: Record "NAV App Published App";
    begin
        exit(R.Count());
    end;

    procedure P12(): Integer
    var
        R: Record "NAV App Extra";
    begin
        exit(R.Count());
    end;

    procedure P13(): Integer
    var
        R: Record "Data Sensitivity";
    begin
        exit(R.Count());
    end;

    procedure P14(): Integer
    var
        R: Record "NAV App";
    begin
        exit(R.Count());
    end;

    procedure P15(): Integer
    var
        R: Record "NAV App Dependencies";
    begin
        exit(R.Count());
    end;

    procedure P16(): Integer
    var
        R: Record "NAV App Capabilities";
    begin
        exit(R.Count());
    end;

    procedure P17(): Integer
    var
        R: Record "NAV App Object Prerequisites";
    begin
        exit(R.Count());
    end;

    procedure P18(): Integer
    var
        R: Record "Configuration Package File";
    begin
        exit(R.Count());
    end;

    procedure P19(): Integer
    var
        R: Record "Page Table Field";
    begin
        exit(R.Count());
    end;

    procedure P20(): Integer
    var
        R: Record "Table Field Types";
    begin
        exit(R.Count());
    end;

    procedure P21(): Integer
    var
        R: Record "Intelligent Cloud Status";
    begin
        exit(R.Count());
    end;

    procedure P22(): Integer
    var
        R: Record "NAV App Resource";
    begin
        exit(R.Count());
    end;

    procedure P23(): Integer
    var
        R: Record "Tenant Profile";
    begin
        exit(R.Count());
    end;

    procedure P24(): Integer
    var
        R: Record "Media Set";
    begin
        exit(R.Count());
    end;

    procedure P25(): Integer
    var
        R: Record "Media";
    begin
        exit(R.Count());
    end;

    procedure P26(): Integer
    var
        R: Record "Profile Page Metadata";
    begin
        exit(R.Count());
    end;

    procedure P27(): Integer
    var
        R: Record "Tenant Profile Page Metadata";
    begin
        exit(R.Count());
    end;

    procedure P28(): Integer
    var
        R: Record "User Page Metadata";
    begin
        exit(R.Count());
    end;

    procedure P29(): Integer
    var
        R: Record "Entitlement Set";
    begin
        exit(R.Count());
    end;

}

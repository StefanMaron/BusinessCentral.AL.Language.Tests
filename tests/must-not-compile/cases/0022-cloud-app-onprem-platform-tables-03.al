// @expect AL0296 | The application object or method 'Application Dependency' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Application Object Metadata' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Application Resource' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Caption' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Category' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Column Filter' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Column' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Data Item' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Filter' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Group' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Join' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Management' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Obj' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query Order By' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Designed Query' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Entitlement' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Extension Execution Info' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Installed Application' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Membership Entitlement' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'NAV App Tenant Operation' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Page Documentation' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Page Info And Fields' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Published Application' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Query Navigation' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Report Printer' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Report Settings Override' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Tenant Feature Key' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Token Cache' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Webhook Notification' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'Webhook Subscription' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @until 27
// @from 27
// group
codeunit 50000 "MNC OnPrem Tables"
{
    procedure P0(): Integer
    var
        R: Record "Entitlement";
    begin
        exit(R.Count());
    end;

    procedure P1(): Integer
    var
        R: Record "Webhook Notification";
    begin
        exit(R.Count());
    end;

    procedure P2(): Integer
    var
        R: Record "Membership Entitlement";
    begin
        exit(R.Count());
    end;

    procedure P3(): Integer
    var
        R: Record "Token Cache";
    begin
        exit(R.Count());
    end;

    procedure P4(): Integer
    var
        R: Record "Page Documentation";
    begin
        exit(R.Count());
    end;

    procedure P5(): Integer
    var
        R: Record "Webhook Subscription";
    begin
        exit(R.Count());
    end;

    procedure P6(): Integer
    var
        R: Record "NAV App Tenant Operation";
    begin
        exit(R.Count());
    end;

    procedure P7(): Integer
    var
        R: Record "Page Info And Fields";
    begin
        exit(R.Count());
    end;

    procedure P8(): Integer
    var
        R: Record "Published Application";
    begin
        exit(R.Count());
    end;

    procedure P9(): Integer
    var
        R: Record "Application Object Metadata";
    begin
        exit(R.Count());
    end;

    procedure P10(): Integer
    var
        R: Record "Application Resource";
    begin
        exit(R.Count());
    end;

    procedure P11(): Integer
    var
        R: Record "Application Dependency";
    begin
        exit(R.Count());
    end;

    procedure P12(): Integer
    var
        R: Record "Tenant Feature Key";
    begin
        exit(R.Count());
    end;

    procedure P13(): Integer
    var
        R: Record "Installed Application";
    begin
        exit(R.Count());
    end;

    procedure P14(): Integer
    var
        R: Record "Designed Query";
    begin
        exit(R.Count());
    end;

    procedure P15(): Integer
    var
        R: Record "Designed Query Caption";
    begin
        exit(R.Count());
    end;

    procedure P16(): Integer
    var
        R: Record "Designed Query Category";
    begin
        exit(R.Count());
    end;

    procedure P17(): Integer
    var
        R: Record "Designed Query Column";
    begin
        exit(R.Count());
    end;

    procedure P18(): Integer
    var
        R: Record "Designed Query Column Filter";
    begin
        exit(R.Count());
    end;

    procedure P19(): Integer
    var
        R: Record "Designed Query Data Item";
    begin
        exit(R.Count());
    end;

    procedure P20(): Integer
    var
        R: Record "Designed Query Filter";
    begin
        exit(R.Count());
    end;

    procedure P21(): Integer
    var
        R: Record "Designed Query Join";
    begin
        exit(R.Count());
    end;

    procedure P22(): Integer
    var
        R: Record "Designed Query Order By";
    begin
        exit(R.Count());
    end;

    procedure P23(): Integer
    var
        R: Record "Designed Query Obj";
    begin
        exit(R.Count());
    end;

    procedure P24(): Integer
    var
        R: Record "Designed Query Group";
    begin
        exit(R.Count());
    end;

    procedure P25(): Integer
    var
        R: Record "Designed Query Management";
    begin
        exit(R.Count());
    end;

    procedure P26(): Integer
    var
        R: Record "Query Navigation";
    begin
        exit(R.Count());
    end;

    procedure P27(): Integer
    var
        R: Record "Extension Execution Info";
    begin
        exit(R.Count());
    end;

    procedure P28(): Integer
    var
        R: Record "Report Settings Override";
    begin
        exit(R.Count());
    end;

    procedure P29(): Integer
    var
        R: Record "Report Printer";
    begin
        exit(R.Count());
    end;

}

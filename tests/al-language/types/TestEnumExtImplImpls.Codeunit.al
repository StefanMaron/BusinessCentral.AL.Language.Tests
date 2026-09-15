// Support codeunits for TestEnumExtImplTests.Codeunit.al: one implementation per enum
// value, each returning a DISTINCT marker, so an assertion names the implementation that
// actually ran rather than merely that the cast produced something.
codeunit 60890 "EEI Base Impl" implements "EEI Marker"
{
    procedure Marker(): Text
    begin
        exit('BASE');
    end;
}

codeunit 60891 "EEI Ext Impl" implements "EEI Marker"
{
    procedure Marker(): Text
    begin
        exit('EXTENSION');
    end;
}

codeunit 60892 "EEI Default Impl" implements "EEI Marker"
{
    procedure Marker(): Text
    begin
        exit('DEFAULT');
    end;
}

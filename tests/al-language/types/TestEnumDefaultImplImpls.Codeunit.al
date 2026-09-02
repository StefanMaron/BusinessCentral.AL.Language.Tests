// Support codeunits for TestEnumDefaultImplTests.Codeunit.al.
//
// Three implementations of "EDI Greeter" that each return a distinct string, so the
// tests can name which of the enum's three implementation slots actually answered
// rather than only proving that some implementation did.
codeunit 60310 "EDI Default Impl" implements "EDI Greeter"
{
    procedure Greet(): Text
    begin
        exit('DEFAULT');
    end;
}

codeunit 60311 "EDI Own Impl" implements "EDI Greeter"
{
    procedure Greet(): Text
    begin
        exit('OWN');
    end;
}

codeunit 60312 "EDI Unknown Impl" implements "EDI Greeter"
{
    procedure Greet(): Text
    begin
        exit('UNKNOWN');
    end;
}

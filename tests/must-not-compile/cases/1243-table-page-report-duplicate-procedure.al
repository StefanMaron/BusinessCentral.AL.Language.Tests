// @expect AL0440 | The Table 'MNC BB Dup Table' already defines a method called 'Foo' with the same parameter types
// @expect AL0440 | The Page 'MNC BB Dup Page' already defines a method called 'Foo' with the same parameter types
// @expect AL0440 | The Report 'MNC BB Dup Report' already defines a method called 'Foo' with the same parameter types
// Two procedures with the same name and parameter types in a table, a page and a report (the codeunit form is case 0043). (3 diagnostics)
table 50001 "MNC BB Dup Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Foo(A: Integer)
    begin
    end;

    procedure Foo(B: Integer)
    begin
    end;
}

page 50002 "MNC BB Dup Page"
{

    procedure Foo(A: Integer)
    begin
    end;

    procedure Foo(B: Integer)
    begin
    end;
}

report 50003 "MNC BB Dup Report"
{
    ProcessingOnly = true;

    procedure Foo(A: Integer)
    begin
    end;

    procedure Foo(B: Integer)
    begin
    end;
}

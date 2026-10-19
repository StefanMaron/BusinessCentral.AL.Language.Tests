// @expect AL0440 | The Table 'MNC BS Proc' already defines a method called 'Foo' with the same parameter types
// @expect AL0440 | The Table 'MNC BS Proc' already defines a method called 'BAZ' with the same parameter types
// Corpus issue #668 item 87: a table extension declares a procedure with the name and parameter types of a procedure of its table (Foo), and
// one whose name differs only in case (BAZ for Baz). An overload with other parameter types (Bar(X: Integer) for Bar()) compiles.
table 51497 "MNC BS Proc"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Foo()
    begin
    end;

    procedure Bar()
    begin
    end;

    procedure Baz()
    begin
    end;
}

tableextension 51497 "MNC BS Proc Ext" extends "MNC BS Proc"
{
    procedure Foo()
    begin
    end;

    procedure Bar(X: Integer)
    begin
    end;

    procedure BAZ()
    begin
    end;
}

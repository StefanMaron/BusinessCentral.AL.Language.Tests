// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0111 | Semicolon expected. Add a semicolon (;) to terminate the statement.
// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// @expect AL0104 | Syntax error, ',' expected
// Corpus #664 item 28. The D, T and DT suffix of a date, time or datetime literal must be upper case: 0d, 0t, 0dt, 20200101d and
// 120000t are syntax errors (AL0111 at the suffix); 0D, 0T, 0DT and 20200101D compile.
// Corpus #664 item 34. An argument cannot be left out in the middle: DMY2Date(1, , 2020) gives AL0224 and AL0104. DMY2Date(1)
// compiles (its value is pinned in tests/al-language/errors/lt-ms-refusals-133/P133DateEvaluateFormat.al).
codeunit 51382 "MNC BM C1382"
{
    procedure P1()
    var
        D: Date;
    begin
        D := 0d;
    end;

    procedure P2()
    var
        T: Time;
    begin
        T := 0t;
    end;

    procedure P3()
    var
        DT: DateTime;
    begin
        DT := 0dt;
    end;

    procedure P4()
    var
        D: Date;
    begin
        D := 20200101d;
    end;

    procedure P5()
    var
        T: Time;
    begin
        T := 120000t;
    end;

    procedure P6()
    var
        D: Date;
        T: Time;
        DT: DateTime;
    begin
        D := 0D;
        T := 0T;
        DT := 0DT;
        D := 20200101D;
    end;

    procedure P7()
    var
        D: Date;
    begin
        D := DMY2Date(1, , 2020);
        D := DMY2Date(1);
    end;
}

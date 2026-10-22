// Corpus #668 item 87 (cross-app half), writer BW: a table extension in another app declares a procedure with the name and signature of a
// procedure of the base table (cross-app fixture A), and one whose name differs from a base table procedure only in case. This app compiles
// with warning AL0523 ("The Table 'LT BW XA Base' already defines a method called 'BwSame' with the same parameter types in 'AL Language
// XApp A by AL Language (1.0.0.0)'. This warning will become an error in a future release."). A call from a third app is AL0196
// (must-not-compile 1581). Test: tests/al-language/tableextension/lt-bw-cross-app/BwCrossAppTests.al.
tableextension 61113 "LT BW XB Base Same Ext" extends "LT BW XA Base"
{
    procedure BwSame(): Text
    begin
        exit('extension of app B');
    end;

    procedure BwCallSameFromB(): Text
    begin
        exit(BwSame());
    end;

    procedure bwcasename(): Text
    begin
        exit('extension of app B, bwcasename');
    end;
}

// @expect AL0165 | Triggers cannot be called directly. Triggers are automatically invoked by the system in response to events.
// @expect AL0165 | Triggers cannot be called directly. Triggers are automatically invoked by the system in response to events.
// @expect AL0165 | Triggers cannot be called directly. Triggers are automatically invoked by the system in response to events.
// @expect AL0750 | Enum values can't be nested. Use '"MNC BM E1387"::"First Value"' instead.
// @expect AL0118 | The name '"17"' does not exist in the current context.
// @expect AL0118 | The name 'Customer' does not exist in the current context.
// Corpus #664 item 33. Rec.OnInsert(), OnRun() in the same codeunit and C.OnRun() on a codeunit variable are all AL0165.
// Corpus #664 item 30. A chain "Enum"::"First"::"Second" is refused with AL0750.
// Corpus #664 item 32. A table cannot be used as a record without a variable: "17".DeleteAll and Customer.Count are AL0118.
enum 51387 "MNC BM E1387" { value(0; "First Value") { } value(1; "Another Value") { } }
table 51387 "MNC BM T1387"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    trigger OnInsert()
    begin
    end;
}
codeunit 51387 "MNC BM C1387"
{
    trigger OnRun()
    begin
    end;

    procedure P()
    var
        R: Record "MNC BM T1387";
        C: Codeunit "MNC BM C1387";
    begin
        R.OnInsert();
        OnRun();
        C.OnRun();
    end;

    procedure E()
    var
        En: Enum "MNC BM E1387";
    begin
        En := "MNC BM E1387"::"First Value"::"Another Value";
    end;

    procedure T1()
    begin
        "17".DeleteAll();
    end;

    procedure T2(): Integer
    begin
        exit(Customer.Count());
    end;
}

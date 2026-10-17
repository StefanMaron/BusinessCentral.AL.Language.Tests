// Diagnostic: why does the insert of LT PT Arg fail with the generic error? Variants of the same shape.

table 67193 "LT PT Diag 1"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Table No."; Integer) { }
        field(3; Op; Text[20]) { }
        field(4; Request; Text[250]) { }
        field(5; "Run Triggers"; Boolean) { }
        field(6; Result; Text[2000]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
table 67194 "LT PT Diag 2"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) {  }
        field(2; "Table No."; Integer) { }
        field(3; Op; Text[20]) { }
        field(4; Request; Text[250]) { }
        field(5; "Run Triggers"; Boolean) { }
        field(6; Result; Text[2000]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
table 67195 "LT PT Diag 3"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Table No."; Integer) { }
        field(3; Op; Text[20]) { }
        field(4; Request; Text[250]) { }
        field(5; "Run Triggers"; Boolean) { }
        field(6; Result; Text[250]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
table 67196 "LT PT Diag 4"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Op; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 67197 "LT PT Diag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try1()
    var
        R: Record "LT PT Diag 1";
    begin
        R.Init();
        R."Table No." := 5;
        R.Insert();
    end;

    [TryFunction]
    local procedure Try2()
    var
        R: Record "LT PT Diag 2";
    begin
        R.Init();
        R.Id := 1;
        R.Insert();
    end;

    [TryFunction]
    local procedure Try3()
    var
        R: Record "LT PT Diag 3";
    begin
        R.Init();
        R.Insert();
    end;

    [TryFunction]
    local procedure Try4()
    var
        R: Record "LT PT Diag 4";
    begin
        R.Init();
        R.Insert();
    end;

    [Test]
    procedure InsertVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('autoincrement_text2000', Format(Try1()) + '|' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('plain_key', Format(Try2()) + '|' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('autoincrement_text250', Format(Try3()) + '|' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('autoincrement_tiny', Format(Try4()) + '|' + GetLastErrorText());
        Observer.Finish();
    end;
}

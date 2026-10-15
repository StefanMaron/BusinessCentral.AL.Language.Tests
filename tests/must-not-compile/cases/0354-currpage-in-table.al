// @expect AL0118 | The name 'CurrPage' does not exist in the current context.
// CurrPage in a table trigger.
table 50172 "MNC T354"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    trigger OnInsert()
    begin
        CurrPage.Update();
    end;
}

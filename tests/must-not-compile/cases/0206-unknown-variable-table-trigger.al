// @expect AL0118 | The name 'Undeclared' does not exist in the current context.
// A table trigger uses an undeclared variable.
table 50009 "MNC T206"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    trigger OnInsert()
    begin
        Undeclared := 5;
    end;
}

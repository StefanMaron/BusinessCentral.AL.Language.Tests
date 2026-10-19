// @expect AL0118 | The name 'NoSuchProcedure' does not exist in the current context.
// A bare call of an unknown procedure inside a table procedure.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Run()
    begin
        NoSuchProcedure();
    end;
}

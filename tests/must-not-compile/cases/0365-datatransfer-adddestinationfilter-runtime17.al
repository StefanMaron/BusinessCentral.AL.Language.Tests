// @expect AL0666 | 'AddDestinationFilter' is not available in runtime version '16.
// Runtime of the corpus apps since the runtime move: 16.1 on BC 27 (this error), 17.1 on BC 28 and 18.0 on BC 29 (the member exists there: the file compiles, so the case holds for BC 27 only).
// @until 27
// DataTransfer.AddDestinationFilter needs a later runtime than 16.
table 50188 "MNC T365"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50189 "MNC C365"
{
    procedure Run1()
    var
        DT: DataTransfer;
    begin
        DT.AddDestinationFilter(1, '1');
    end;
}

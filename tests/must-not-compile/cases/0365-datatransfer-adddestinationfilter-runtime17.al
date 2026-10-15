// @expect AL0666 | 'AddDestinationFilter' is not available in runtime version '16.0'. The supported runtime versions are: '17.0' or greater.
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

// @expect AL0433 | Table 'MNC Removed Row 0970' is removed. Reason: gone. Tag: 1.0.
// A table with ObsoleteState = Removed is used as a record variable. A codeunit cannot be Removed (AL0169), a table can.
table 59010 "MNC Removed Row 0970"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'gone';
    ObsoleteTag = '1.0';

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { } }
}

codeunit 59011 "MNC Removed User 0970"
{
    procedure Run1()
    var
        Row: Record "MNC Removed Row 0970";
    begin
        Row.Init();
    end;
}

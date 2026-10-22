// @expect AL0185 | Page 'MNC Y Missing Page' is missing
table 50815 "MNC Y Tab"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
report 50816 "MNC Y RP Card"
{
    ProcessingOnly = true;
    requestpage
    {
        SourceTable = "MNC Y Tab";
        CardPageId = "MNC Y Missing Page";
        layout { area(Content) { field(F; Fv) { ApplicationArea = All; } } }
    }
    var
        Fv: Integer;
}

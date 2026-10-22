// A chartpart control in a page layout. The AL 30 compiler rejects it on every leg (runtime 16.1, 17.1, 18.0) with error AL0865 (not the
// AL0864 warning the BC 26 docs mention). Corpus issue 667 (item 33-48 batch of writer CC), item "chartpart control: AL0864 warning then error".
// @expect AL0865 | The control type 'ChartPart' is not supported.
table 50000 "MNC CC Chart Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50000 "MNC CC Chart Page"
{
    PageType = Card;
    SourceTable = "MNC CC Chart Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            chartpart(MyChart; MNCChart)
            {
                ApplicationArea = All;
            }
        }
    }
}

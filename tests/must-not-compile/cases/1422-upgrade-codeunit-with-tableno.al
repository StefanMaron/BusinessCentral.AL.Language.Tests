// @expect AL0365 | The property 'TableNo' cannot be set if the property 'Subtype' is set to 'Upgrade'
// A codeunit with Subtype = Upgrade and TableNo = Item. Corpus issue 664 item 103 (microsoft/AL#7467). Writer BO.
codeunit 51429 "MNC BO 1422"
{
    Subtype = Upgrade;
    TableNo = Item;

    trigger OnRun() begin end;
}

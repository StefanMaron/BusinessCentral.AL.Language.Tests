// @expect AL0171 | The property value 'Id = field(Id)' on property 'SubPageLink' is not valid.
// @expect AL0171 | The property value 'where(Id = const(1))' on property 'SubPageView' is not valid.
// Corpus issue 663 item 13: a system part takes no SubPageLink and no SubPageView value (AL0171). EntityName and EntitySetName on a system part
// compile (misc/lt-dh-obsolete-props/DhOtherProps.al).
table 51868 "MNC DH T 1865" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 51869 "MNC DH Page 1865"
{
    PageType = Card;
    SourceTable = "MNC DH T 1865";
    layout
    {
        area(FactBoxes)
        {
            systempart(Notes; MyNotes) { SubPageLink = Id = field(Id); }
            systempart(Outlook; Outlook) { SubPageView = where(Id = const(1)); }
        }
    }
}

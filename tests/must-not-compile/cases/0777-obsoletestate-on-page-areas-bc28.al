// @from 28
// @until 28
// @expect AL0666 | 'ObsoleteState' is not available in runtime version '17.1'. The supported runtime versions are: '4.0' until, but not including '13.0'.
// @expect AL0666 | 'ObsoleteReason' is not available in runtime version '17.1'. The supported runtime versions are: '4.0' until, but not including '13.0'.
// @expect AL0666 | 'ObsoleteTag' is not available in runtime version '17.1'. The supported runtime versions are: '4.3' until, but not including '13.0'.
// @expect AL0666 | 'ObsoleteState' is not available in runtime version '17.1'. The supported runtime versions are: '4.0' until, but not including '13.0'.
// @expect AL0666 | 'ObsoleteReason' is not available in runtime version '17.1'. The supported runtime versions are: '4.0' until, but not including '13.0'.
// @expect AL0666 | 'ObsoleteTag' is not available in runtime version '17.1'. The supported runtime versions are: '4.3' until, but not including '13.0'.
// A page content area and an action area take none of ObsoleteState, ObsoleteReason and ObsoleteTag (AL0666: not available in runtime 17.1), whatever the state.
table 59990 "MNC X Src" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
page 59991 "MNC X Page"
{
    PageType = Card;
    SourceTable = "MNC X Src";
    layout { area(Content) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; field(F; Rec.Id) { } } }
    actions { area(Processing) { ObsoleteState = Pending; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; action(A) { } } }
}

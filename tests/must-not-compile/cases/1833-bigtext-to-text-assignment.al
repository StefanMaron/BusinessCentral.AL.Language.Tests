// @expect AL0122 | Cannot implicitly convert type 'BigText' to 'Text'
// A BigText assigned to a Text variable: there is no implicit conversion (corpus issue 671, item 73).
// Format(BigText) and BigText.GetSubText give the text: tests/al-language/streams/lt-dd-stream-leads/DdStreamLeads.al Item73.
codeunit 51833 "MNC DD C1833"
{
    procedure Convert(): Text
    var
        BT: BigText;
        T: Text;
    begin
        BT.AddText('YWJj');
        T := BT;
        exit(T);
    end;
}

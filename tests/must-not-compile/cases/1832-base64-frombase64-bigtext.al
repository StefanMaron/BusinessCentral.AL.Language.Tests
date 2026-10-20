// @expect AL0133 | Argument 1: cannot convert from 'BigText' to 'Text'
// A BigText passed to "Base64 Convert".FromBase64: no overload takes a BigText (Text, SecretText, and Text with a TextEncoding or an
// OutStream), and a BigText does not convert to Text. A BigText goes in through GetSubText or Format first:
// tests/al-language/streams/lt-dd-stream-leads/DdStreamLeads.al Item73 (corpus issue 671, item 73).
codeunit 51832 "MNC DD C1832"
{
    procedure Decode(): Text
    var
        Base64: Codeunit "Base64 Convert";
        BT: BigText;
    begin
        BT.AddText('YWJj');
        exit(Base64.FromBase64(BT));
    end;
}

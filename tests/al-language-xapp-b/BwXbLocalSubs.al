// Corpus #664 item 144, writer BW: a subscriber to a local integration event of a dependency app (cross-app fixture A); microsoft/AL
// issue 5047 reported AL0999 for it. It compiles with no diagnostic. Test: tests/al-language/tableextension/lt-bw-cross-app/BwCrossAppTests.al.
codeunit 61116 "LT BW XB Local Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Local Publisher", 'OnBwLocal', '', false, false)]
    local procedure OnBwLocal(var Log: Text)
    begin
        Log += 'B local;';
    end;
}

// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'var InStream'
// @expect AL0133 | Argument 3: cannot convert from 'InStream' to 'TextEncoding'
// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'TextEncoding'
// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'TextEncoding'
// @until 28
// NavApp.GetResource, GetResourceAsText and GetResourceAsJson with an AppId exist from BC 29. On BC 29 the call needs runtime 18.0, which the corpus app does not use (case 0998).
codeunit 58985 "MNC NavAppRes 0965"
{
    procedure Run1()
    var
        Stream: InStream;
        Json: JsonObject;
        Text1: Text;
        AppId: Guid;
    begin
        NavApp.GetResource('a.txt', AppId, Stream);
        Text1 := NavApp.GetResourceAsText('a.txt', AppId);
        Json := NavApp.GetResourceAsJson('a.json', AppId);
    end;
}

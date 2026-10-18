// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'var InStream'
// @expect AL0133 | Argument 3: cannot convert from 'InStream' to 'TextEncoding'
// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'TextEncoding'
// @expect AL0133 | Argument 2: cannot convert from 'Guid' to 'TextEncoding'
// @until 28
// @max-al 17
// NavApp.GetResource, GetResourceAsText and GetResourceAsJson with an AppId exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac.
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

// NavApp.GetCallerCallstackModuleInfos asked from INSIDE the fixture (dependency) app, so a
// test in the main app can see which apps the list names when a second app is on the stack.
// Inner is reached through Outer to put a fixture frame between the asking method and the
// main-app caller.
codeunit 61011 "ALT Callstack Module Infos"
{
    procedure CallerInfos(): List of [ModuleInfo]
    begin
        exit(NavApp.GetCallerCallstackModuleInfos());
    end;

    procedure CallerInfosThroughOwnFrame(): List of [ModuleInfo]
    begin
        exit(CallerInfosInner());
    end;

    local procedure CallerInfosInner(): List of [ModuleInfo]
    begin
        exit(NavApp.GetCallerCallstackModuleInfos());
    end;

    procedure OwnAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id);
    end;
}

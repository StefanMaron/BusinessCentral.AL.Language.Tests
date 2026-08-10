// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607)
//
// Deliberately shaped like Base App codeunit 347 "Auto Format": SingleInstance, with a
// global record it reads once and caches behind a boolean. That global is a record HANDLE,
// and the handle is what goes null when the tree it hangs off is disposed.

codeunit 60608 "SIS Cache"
{
    SingleInstance = true;

    var
        Setup: Record "SIS Setup";
        SetupRead: Boolean;
        ReadCount: Integer;

    procedure GetCurrencyCode(): Code[10]
    begin
        if not SetupRead then begin
            Setup.Get('MAIN');
            ReadCount += 1;
        end;
        SetupRead := true;
        exit(Setup."Currency Code");
    end;

    procedure GetReadCount(): Integer
    begin
        exit(ReadCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SIS Publisher", 'OnResolveCurrency', '', false, false)]
    local procedure OnResolveCurrency(var CurrencyCode: Code[10])
    begin
        CurrencyCode := GetCurrencyCode();
    end;
}

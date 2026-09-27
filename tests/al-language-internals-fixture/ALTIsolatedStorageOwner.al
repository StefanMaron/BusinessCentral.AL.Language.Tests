// Module-scoped IsolatedStorage, written and read from INSIDE the fixture (dependency) app.
// Purpose: give a test in the main app a second app whose module storage it can compare its
// own against -- IsolatedStorage's default DataScope is Module, and a module is an app.
// OnStoreRequested lets a subscriber in another app write storage while this app raised the
// event. The Company-scope procedures exist to show the app boundary holds for that scope too.
codeunit 61010 "ALT Isolated Storage Owner"
{
    procedure SetValue(StorageKey: Text; Value: Text): Boolean
    begin
        exit(IsolatedStorage.Set(StorageKey, Value));
    end;

    procedure Contains(StorageKey: Text): Boolean
    begin
        exit(IsolatedStorage.Contains(StorageKey));
    end;

    procedure GetValue(StorageKey: Text; var Value: Text): Boolean
    begin
        exit(IsolatedStorage.Get(StorageKey, Value));
    end;

    procedure DeleteIfPresent(StorageKey: Text)
    begin
        if IsolatedStorage.Contains(StorageKey) then
            IsolatedStorage.Delete(StorageKey);
    end;

    procedure RaiseStoreRequested(StorageKey: Text; Value: Text)
    begin
        OnStoreRequested(StorageKey, Value);
    end;

    [IntegrationEvent(false, false)]
    procedure OnStoreRequested(StorageKey: Text; Value: Text)
    begin
    end;

    procedure SetCompanyValue(StorageKey: Text; Value: Text): Boolean
    begin
        exit(IsolatedStorage.Set(StorageKey, Value, DataScope::Company));
    end;

    procedure ContainsCompany(StorageKey: Text): Boolean
    begin
        exit(IsolatedStorage.Contains(StorageKey, DataScope::Company));
    end;

    procedure DeleteCompanyIfPresent(StorageKey: Text)
    begin
        if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
            IsolatedStorage.Delete(StorageKey, DataScope::Company);
    end;
}

codeunit 67581 "ALT IS Store Subscriber"
{
    // Subscribes, from the MAIN app, to an event the fixture (dependency) app raises, and
    // writes IsolatedStorage from inside the handler. Manual so it is inert for every other
    // test; only codeunit 67580 binds it.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Isolated Storage Owner", 'OnStoreRequested', '', false, false)]
    local procedure StoreHere(StorageKey: Text; Value: Text)
    begin
        IsolatedStorage.Set(StorageKey, Value);
    end;
}

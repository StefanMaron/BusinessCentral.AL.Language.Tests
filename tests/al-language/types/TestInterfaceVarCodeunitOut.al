// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/interface/interface-data-type
// Scope: in-scope
// Fixtures used: "Ivc Backend Type" (60373), "Ivc Native Impl" (60374), "Ivc Clearing Impl" (60375), "Ivc Reader" (60376)
//
/// <summary>
/// Pins that a `var Result: Codeunit "Temp Blob"` out-parameter filled by an interface
/// implementation is visible in the CALLER's variable.
///
/// The direct-call test is the control: if it passes and the interface one fails, the
/// defect is in interface dispatch specifically, not in by-var codeunit parameters
/// generally.
/// </summary>
codeunit 60377 "Test Interface Var CU Out"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DirectCall_FillsTheCallersTempBlob()
    var
        Impl: Codeunit "Ivc Native Impl";
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // Control: same by-var codeunit contract, no interface in the way.
        Impl.Produce(Blob, 'PRODUCED-DIRECT');

        Assert.AreEqual('PRODUCED-DIRECT', Reader.ReadAll(Blob),
            'Direct call: a by-var Codeunit out-parameter must travel back to the caller.');
    end;

    [Test]
    procedure InterfaceDispatch_FillsTheCallersTempBlob()
    var
        Backend: Interface "IIvc Backend";
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // The renderer shape: enum value assigned to an interface, result returned
        // only through the by-var codeunit.
        Backend := Enum::"Ivc Backend Type"::NativeProduce;
        Backend.Produce(Blob, 'PRODUCED-VIA-INTERFACE');

        Assert.AreEqual('PRODUCED-VIA-INTERFACE', Reader.ReadAll(Blob),
            'Interface dispatch: the implementation must fill the CALLER''s Temp Blob, not a copy.');
    end;

    [Test]
    procedure SecondCreateInStream_StillSeesTheContent()
    var
        Impl: Codeunit "Ivc Native Impl";
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // A caller may read its result blob TWICE: once to inspect, then again to copy
        // it out. If the Temp Blob is exhausted by the first full read, the second
        // CreateInStream yields nothing and the content is silently lost on the way out.
        Impl.Produce(Blob, 'PRODUCED-TWICE');

        Assert.AreEqual('PRODUCED-TWICE', Reader.ReadAll(Blob), 'First read');
        Assert.AreEqual('PRODUCED-TWICE', Reader.ReadAll(Blob),
            'Second CreateInStream must still see the content — the Temp Blob must not be consumed by the first read.');
    end;

    [Test]
    procedure ClearOnAVarCodeunitParameter_DoesNotDetachTheCallersInstance()
    var
        Impl: Codeunit "Ivc Clearing Impl";
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // Real BC: Clear(Result) resets the instance IN PLACE, so the caller keeps
        // observing the same object and sees everything written afterwards. If Clear
        // instead rebinds the local to a FRESH instance, every subsequent write lands
        // somewhere the caller cannot see.
        Impl.ProduceAfterClear(Blob, 'PRODUCED-AFTER-CLEAR');

        Assert.AreEqual('PRODUCED-AFTER-CLEAR', Reader.ReadAll(Blob),
            'After Clear() on a var Codeunit parameter the caller must still see the produced bytes.');
    end;

    [Test]
    procedure CreateOutStreamWithTextEncoding_StillReachesTheCaller()
    var
        Impl: Codeunit "Ivc Clearing Impl";
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // Pinned separately so an unimplemented encoding overload cannot hide behind
        // the plain one.
        Impl.ProduceWithEncoding(Blob, 'PRODUCED-WINDOWS-ENCODED');

        Assert.AreEqual('PRODUCED-WINDOWS-ENCODED', Reader.ReadAll(Blob),
            'CreateOutStream(.., TextEncoding::Windows) on a var Codeunit parameter must reach the caller.');
    end;

    [Test]
    procedure UntouchedTempBlob_IsEmpty()
    var
        Blob: Codeunit "Temp Blob";
        Reader: Codeunit "Ivc Reader";
    begin
        Initialize();

        // Negative control: proves ReadAll reports emptiness rather than always finding
        // the expected text, so the assertions above mean something.
        Assert.AreEqual('', Reader.ReadAll(Blob), 'A Temp Blob nobody wrote to must report no content.');
    end;

    local procedure Initialize()
    begin
        // No persistent tables used — every value under test lives in a Temp Blob.
    end;
}

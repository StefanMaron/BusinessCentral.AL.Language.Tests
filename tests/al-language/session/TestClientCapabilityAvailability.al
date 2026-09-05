// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-client-device-capabilities
// Scope: in-scope
// Fixtures used: none (System Application codeunits Camera 1907 and Geolocation 7568)
//
// CLAIM: `IsAvailable()` on a client-device capability ANSWERS in a BC test session -- it
// returns a Boolean, it does not raise. In a session whose client provides no camera and no
// geolocation, the answer is `false`, and the block the platform guards with it is skipped.
//
// This is the contract the shipped application depends on. Every call site in the Base
// Application and the System Application uses `IsAvailable()` as the condition of an `if`,
// never inside a `if not ... then Error`, e.g. page 9042 "Team Member Activities".OnOpenPage:
//
//     if PageNotifier.IsAvailable() then begin
//         PageNotifier := PageNotifier.Create();
//         PageNotifier.NotifyPageReady();
//     end;
//
// so a platform that RAISED from the probe instead of answering would turn "this session has
// no camera" into an error on every page that asks, rather than into a skipped block. The
// probe is the question; only the calls PAST the guard are the use.
//
// The two facades below are deliberately BOTH here, because they reach the answer by
// DIFFERENT routes and only one of them is a client round trip:
//   Camera (1907)      -> Camera Impl. (1922) -> page 1908 -> Camera Page Impl. (1908), whose
//                         CameraProvider is a [RunOnClient] DotNet variable, so the probe is
//                         resolved by the session's client.
//   Geolocation (7568) -> Geolocation Impl. (7569), whose LocationProvider is a SERVER-side
//                         DotNet variable, so the probe is resolved in the service tier.
// A platform change that broke one route and not the other would otherwise pass.
//
// Both directions are covered, and the negative one is what makes the positives mean
// something: GuiAllowed() must be TRUE in the same session. That pins "false" to the absence
// of the CAPABILITY rather than to the session being non-interactive, so an implementation
// that answered false to every Boolean platform question would fail here instead of passing
// three tests in a row.
codeunit 60293 "Test Client Capability Avail"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;

    // POSITIVE (client-resolved route). The probe must answer, and the answer in a session
    // with no camera is false -- not an error, and not true.
    [Test]
    procedure Camera_IsAvailable_AnswersFalse_WithoutRaising()
    var
        Camera: Codeunit Camera;
    begin
        Assert.IsFalse(
            Camera.IsAvailable(),
            'Camera.IsAvailable() must ANSWER false in a session whose client has no camera, not raise.');
    end;

    // POSITIVE (server-resolved route). Same claim through the other mechanism.
    [Test]
    procedure Geolocation_IsAvailable_AnswersFalse_WithoutRaising()
    var
        Geolocation: Codeunit Geolocation;
    begin
        Assert.IsFalse(
            Geolocation.IsAvailable(),
            'Geolocation.IsAvailable() must ANSWER false in a session with no geolocation provider, not raise.');
    end;

    // The shape the shipped application actually relies on: the guarded block is SKIPPED,
    // reached by evaluating the probe as an `if` condition rather than by reading its return
    // value into a variable first. Asserting the value alone would not prove that the
    // platform lets the `if` complete.
    [Test]
    procedure Camera_IsAvailableGuard_SkipsTheGuardedBlock_InsteadOfRaising()
    var
        Camera: Codeunit Camera;
        EnteredGuardedBlock: Boolean;
        CompletedTheIf: Boolean;
    begin
        if Camera.IsAvailable() then
            EnteredGuardedBlock := true;
        CompletedTheIf := true;

        Assert.IsTrue(
            CompletedTheIf,
            'Execution must continue past an `if <capability>.IsAvailable() then` guard.');
        Assert.IsFalse(
            EnteredGuardedBlock,
            'The block guarded by Camera.IsAvailable() must be skipped when no camera is available.');
    end;

    // NEGATIVE. The session IS interactive -- GuiAllowed() is true here. Without this,
    // "IsAvailable() is false" is equally consistent with a platform that answers false to
    // every Boolean it is asked, and the two tests above would prove nothing.
    [Test]
    procedure Session_IsInteractive_WhileTheDeviceCapabilitiesAreNot()
    var
        Camera: Codeunit Camera;
    begin
        Assert.IsTrue(
            GuiAllowed(),
            'GuiAllowed() must be true in a BC test session -- the capability probes below answer false because the CAPABILITY is absent, not because the session is headless.');
        Assert.IsFalse(
            Camera.IsAvailable(),
            'Camera.IsAvailable() must be false in that same interactive session.');
    end;
}

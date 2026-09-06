// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessionsettings/sessionsettings-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none; shared Assert (60021)
// BC versions: 27.0+ (SessionSettings is runtime 1.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: SessionSettings is a mutable value object describing a session's personalization --
/// company, language, locale, time zone and profile. Its accessors are get/set pairs on an
/// in-memory instance, so all of them are observable from a test WITHOUT a client attached.
/// Nothing in this repository measured any part of SessionSettings before this file --
/// docs/al-language-coverage-gaps.md lists it first under gap #4, "partial or thin coverage",
/// and a search of the suite finds no other reference to the type.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. ROUND-TRIPPING. Each accessor is a get/set pair: the value written is the value read
///      back. Every such test writes a DISTINCTIVE value and asserts that exact value, so an
///      implementation returning a constant, or returning the live session's value instead of
///      the assigned one, fails.
///   2. THE ACCESSORS ARE INDEPENDENT. Setting one property must not disturb another. Tests
///      set several properties to different values and assert all of them afterwards, so an
///      implementation backing two properties with one field fails.
///   3. ProfileSystemScope IGNORES ITS ARGUMENT. This is the surprising one, and it is the
///      reason this file is worth having. System profiles are deprecated -- all profiles are
///      tenant-scoped -- so the setter accepts `true` and stores `false` regardless. An
///      implementation that treated it as an ordinary Boolean get/set pair would pass every
///      other test in this file and fail this one.
///   4. ASSIGNMENT COPIES BY VALUE. `A := B` deep-copies the settings. Mutating the copy
///      afterwards must not change the original. An implementation sharing one underlying
///      object between both variables fails.
///   5. Init() POPULATES THE INSTANCE. Init() fills the instance from the current user's
///      personalization, falling back to live session values when there is no stored row.
///      Both paths populate the object, so an initialized instance cannot equal a pristine
///      one and must carry a non-empty company -- an Init() that did nothing fails both.
///      These assertions are deliberately relative rather than pinned to CompanyName(): which
///      of the two sources answers is a property of the tenant's data, not of AL.
///   6. RequestSessionUpdate() IS CALLABLE FROM A TEST, and is a request to the CLIENT for a
///      future session -- it neither disturbs the settings instance nor retroactively changes
///      the language of the session currently running. Under a test runner the platform
///      intercepts the client round-trip, so the call completes rather than failing for want
///      of a client callback.
///
/// NEGATIVE CASES ARE COMPILE-TIME, NOT RUNTIME, AND THERE ARE FEWER THAN EXPECTED. There is
/// no documented runtime error on this type that a Cloud test can provoke with `asserterror`:
/// the setters are plain assignments on an in-memory object, and the documented failures --
/// Company() naming a company that does not exist, ProfileId() naming a profile absent from
/// table 2000000072 -- are raised by the client round-trip on session update, not by the
/// setter. So this file deliberately contains NO `asserterror` test rather than inventing one
/// that cannot fail. Setting a nonexistent company is instead asserted below to be accepted by
/// the SETTER, which is the observable half of that contract.
///
/// The compile-time surface was MEASURED with the AL compiler (v17.0.34.45391) against this
/// app's Cloud target, and it refuses less than a SecretText-style type would -- worth writing
/// down, because the intuition carried over from SecretText is wrong here:
///
///     if S1 = S2 then              error AL0175: operator '=' cannot be applied to operands
///                                  of type 'SessionSettings' and 'SessionSettings'
///     V := Settings;               COMPILES -- unlike SecretText, SessionSettings converts to
///                                  Variant
///     Assert.AreEqual(S1, S2, '')  COMPILES, and is therefore a real runtime assertion. Assert
///                                  falls through to Format(_, 0, 2) for non-primitive
///                                  variants, so comparing two settings objects compares their
///                                  formatted values. Pinned below.
///     T := Format(Settings);       COMPILES -- a settings object has a text representation
///     Clear(Settings);             COMPILES
///
/// DELIBERATELY NOT TESTED: RequestSessionUpdate(true). The `true` argument makes the platform
/// WRITE the settings to table 2000000073 "User Personalization" for the running user before
/// sending the client request. That is a durable side effect on the tenant the suite runs
/// against, outside this codeunit's own fixtures, and it would change the values a later
/// Init() reads -- so exercising it could make the Init() tests above order-dependent. Only
/// the non-persisting direction is exercised here; the persisting one needs a fixture that can
/// restore the user's personalization afterwards.
///
/// The AL compiler also independently confirms the ProfileSystemScope claim above. Referencing
/// it raises AL0667 with Microsoft's own wording: "System profiles have been deprecated. All
/// profiles are now in the Tenant. Setting this value to true has no effect." That warning is
/// expected on every build of this file and is not a defect; the suite carries comparable
/// deprecation warnings for IsServiceTier and OptionString elsewhere.
/// </summary>
codeunit 60277 "Test SessionSettings"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    // ---------------------------------------------------------------------------------------
    // 1 + 2. Round-tripping, and independence of the accessors.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_LanguageId_RoundTripsAssignedValue()
    var
        Settings: SessionSettings;
    begin
        // 1030 is Danish -- deliberately NOT 1033/en-US, which is what a session would
        // default to, so reading back the session's own value instead of the assigned one
        // is a detectable failure rather than a coincidental pass.
        Settings.LanguageId(1030);

        Assert.AreEqual(1030, Settings.LanguageId(), 'LanguageId() must read back the language ID that was assigned');
    end;

    [Test]
    procedure SessionSettings_LocaleId_RoundTripsAssignedValue()
    var
        Settings: SessionSettings;
    begin
        Settings.LocaleId(2057);

        Assert.AreEqual(2057, Settings.LocaleId(), 'LocaleId() must read back the locale ID that was assigned');
    end;

    [Test]
    procedure SessionSettings_LanguageIdAndLocaleId_AreIndependentProperties()
    var
        Settings: SessionSettings;
    begin
        // Two different values in two properties of the same type. Backing both with a single
        // field -- an easy implementation mistake, since they are adjacent and both Integer --
        // makes exactly one of these two assertions fail.
        Settings.LanguageId(1030);
        Settings.LocaleId(2057);

        Assert.AreEqual(1030, Settings.LanguageId(), 'LanguageId must keep its own value after LocaleId is set');
        Assert.AreEqual(2057, Settings.LocaleId(), 'LocaleId must keep its own value after LanguageId is set');
    end;

    [Test]
    procedure SessionSettings_TimeZone_RoundTripsAssignedValue()
    var
        Settings: SessionSettings;
    begin
        Settings.TimeZone('Pacific Standard Time');

        Assert.AreEqual(
            'Pacific Standard Time', Settings.TimeZone(), 'TimeZone() must read back the time zone that was assigned');
    end;

    [Test]
    procedure SessionSettings_TimeZone_LastAssignmentWins()
    var
        Settings: SessionSettings;
    begin
        // Reassignment in sequence: the second write must replace the first, not be ignored
        // and not be appended. An accessor that only accepts its first value passes the test
        // above and fails this one.
        Settings.TimeZone('UTC');
        Settings.TimeZone('Pacific Standard Time');

        Assert.AreEqual(
            'Pacific Standard Time', Settings.TimeZone(), 'A second TimeZone() assignment must replace the first');
    end;

    [Test]
    procedure SessionSettings_ProfileId_RoundTripsAssignedValue()
    var
        Settings: SessionSettings;
    begin
        Settings.ProfileId('ALT PROFILE');

        Assert.AreEqual('ALT PROFILE', Settings.ProfileId(), 'ProfileId() must read back the profile ID that was assigned');
    end;

    [Test]
    procedure SessionSettings_ProfileAppId_RoundTripsAssignedGuid()
    var
        Settings: SessionSettings;
        AppId: Guid;
    begin
        AppId := CreateGuid();

        Settings.ProfileAppId(AppId);

        Assert.AreEqual(AppId, Settings.ProfileAppId(), 'ProfileAppId() must read back the GUID that was assigned');
    end;

    [Test]
    procedure SessionSettings_ProfileAppId_DistinguishesTwoDifferentGuids()
    var
        Settings: SessionSettings;
        FirstAppId: Guid;
        SecondAppId: Guid;
    begin
        // The discriminating pair for a GUID accessor: storing the first GUID and then the
        // second must yield the second. An implementation that latched the first value, or
        // that returned a fresh GUID on every read, fails here while passing the test above.
        FirstAppId := CreateGuid();
        SecondAppId := CreateGuid();
        Assert.AreNotEqual(FirstAppId, SecondAppId, 'CreateGuid must produce two distinct GUIDs for this test to mean anything');

        Settings.ProfileAppId(FirstAppId);
        Settings.ProfileAppId(SecondAppId);

        Assert.AreEqual(SecondAppId, Settings.ProfileAppId(), 'ProfileAppId() must hold the most recently assigned GUID');
    end;

    [Test]
    procedure SessionSettings_Company_RoundTripsAssignedValue()
    var
        Settings: SessionSettings;
    begin
        Settings.Company('ALT Coverage Company');

        Assert.AreEqual(
            'ALT Coverage Company', Settings.Company(), 'Company() must read back the company name that was assigned');
    end;

    [Test]
    procedure SessionSettings_Company_SetterAcceptsCompanyThatDoesNotExist()
    var
        Settings: SessionSettings;
        Missing: Text;
    begin
        // Microsoft documents that the company "must already exist in the database, otherwise
        // you will get an error at runtime". This pins WHERE that error is raised: not in the
        // setter. The setter is a plain assignment on an in-memory object, and validation
        // happens on the session-update round-trip. If the setter ever started validating,
        // this test fails -- which is the signal that the error moved.
        Missing := 'ALT No Such Company ' + Format(CreateGuid());

        Settings.Company(Missing);

        Assert.AreEqual(Missing, Settings.Company(), 'Company() must accept and read back a name with no company behind it');
    end;

    [Test]
    procedure SessionSettings_AllTextProperties_AreIndependentOfEachOther()
    var
        Settings: SessionSettings;
    begin
        // Three Text-typed properties set to three distinct values at once. This is the
        // strongest independence assertion in the file: any implementation that shares
        // storage between two of the three fails at least one assertion.
        Settings.Company('ALT Company');
        Settings.ProfileId('ALT PROFILE');
        Settings.TimeZone('UTC');

        Assert.AreEqual('ALT Company', Settings.Company(), 'Company must be unaffected by ProfileId and TimeZone');
        Assert.AreEqual('ALT PROFILE', Settings.ProfileId(), 'ProfileId must be unaffected by Company and TimeZone');
        Assert.AreEqual('UTC', Settings.TimeZone(), 'TimeZone must be unaffected by Company and ProfileId');
    end;

    // ---------------------------------------------------------------------------------------
    // 3. ProfileSystemScope ignores its argument -- system profiles are deprecated.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_ProfileSystemScope_DefaultsToFalse()
    var
        Settings: SessionSettings;
    begin
        Assert.IsFalse(
            Settings.ProfileSystemScope(), 'A fresh SessionSettings must report tenant scope (false), not system scope');
    end;

    [Test]
    procedure SessionSettings_ProfileSystemScope_StaysFalseWhenSetToTrue()
    var
        Settings: SessionSettings;
    begin
        // THE POINT OF THIS FILE. System profiles are deprecated -- all profiles are in the
        // Tenant scope -- so this setter discards its argument and the property is false no
        // matter what is written to it. An implementation treating it as an ordinary Boolean
        // get/set pair passes every other test here and fails this one.
        Settings.ProfileSystemScope(true);

        Assert.IsFalse(
            Settings.ProfileSystemScope(),
            'ProfileSystemScope must remain false after being set to true -- system profiles are deprecated');
    end;

    [Test]
    procedure SessionSettings_ProfileSystemScope_StaysFalseWhenSetToFalse()
    var
        Settings: SessionSettings;
    begin
        // The other direction, so the pair rules out an implementation that simply always
        // returns the NEGATION of what it was given: that would pass the true-case above and
        // fail here by returning true.
        Settings.ProfileSystemScope(false);

        Assert.IsFalse(Settings.ProfileSystemScope(), 'ProfileSystemScope must be false after being set to false');
    end;

    [Test]
    procedure SessionSettings_ProfileSystemScope_DoesNotDisturbProfileId()
    var
        Settings: SessionSettings;
    begin
        // The discarded write must be discarded quietly: it must not clear the neighbouring
        // profile properties it is grouped with.
        Settings.ProfileId('ALT PROFILE');
        Settings.ProfileSystemScope(true);

        Assert.AreEqual('ALT PROFILE', Settings.ProfileId(), 'A discarded ProfileSystemScope write must not clear ProfileId');
        Assert.IsFalse(Settings.ProfileSystemScope(), 'ProfileSystemScope must still be false');
    end;

    // ---------------------------------------------------------------------------------------
    // 4. Assignment copies by value.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_Assignment_CopiesValuesToTheTarget()
    var
        Source: SessionSettings;
        Target: SessionSettings;
    begin
        Source.Company('ALT Source Company');
        Source.LanguageId(1030);
        Source.TimeZone('UTC');

        Target := Source;

        Assert.AreEqual('ALT Source Company', Target.Company(), 'Assignment must carry Company to the target');
        Assert.AreEqual(1030, Target.LanguageId(), 'Assignment must carry LanguageId to the target');
        Assert.AreEqual('UTC', Target.TimeZone(), 'Assignment must carry TimeZone to the target');
    end;

    [Test]
    procedure SessionSettings_Assignment_IsByValueSoMutatingTheCopyLeavesTheOriginal()
    var
        Source: SessionSettings;
        Target: SessionSettings;
    begin
        // The discriminating half of the pair above. Assignment deep-copies, so writing to
        // the copy must not be visible through the original. An implementation that shared
        // one underlying settings object between the two variables passes the copy test
        // above and fails this one.
        Source.Company('ALT Source Company');
        Source.LanguageId(1030);

        Target := Source;
        Target.Company('ALT Target Company');
        Target.LanguageId(2057);

        Assert.AreEqual('ALT Source Company', Source.Company(), 'Mutating the copy must not change the original Company');
        Assert.AreEqual(1030, Source.LanguageId(), 'Mutating the copy must not change the original LanguageId');
        Assert.AreEqual('ALT Target Company', Target.Company(), 'The copy must hold its own new Company');
        Assert.AreEqual(2057, Target.LanguageId(), 'The copy must hold its own new LanguageId');
    end;

    // ---------------------------------------------------------------------------------------
    // 5. Init() populates the instance from the session.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_Init_ChangesAPristineInstance()
    var
        Settings: SessionSettings;
        Pristine: SessionSettings;
    begin
        // The load-bearing claim about Init(): it DOES something. Init() reads the current
        // user's personalization, falling back to live session values when the user has no
        // stored personalization row. Both documented paths populate language, locale and
        // time zone, so a pristine instance and an initialized one cannot be equal.
        //
        // An Init() implemented as a no-op -- the most likely way for this surface to be got
        // wrong -- leaves the instance pristine and fails here.
        Settings.Init();

        Assert.AreNotEqual(Pristine, Settings, 'Init() must populate the instance, leaving it different from a pristine one');
    end;

    [Test]
    procedure SessionSettings_Init_PopulatesANonEmptyCompany()
    var
        Settings: SessionSettings;
    begin
        // Init() resolves a company from one of its two documented sources -- the stored
        // User Personalization row, or the running session. This asserts only that a company
        // is resolved at all, deliberately NOT that it equals CompanyName(): a stored
        // personalization row may legitimately name a different company than the one the
        // test session happens to be running in, and pinning that equality would assert
        // something about the CI tenant's data rather than about AL.
        Settings.Init();

        Assert.AreNotEqual('', Settings.Company(), 'Init() must populate Company from personalization or from the session');
    end;

    [Test]
    procedure SessionSettings_Init_PopulatesAPositiveLanguageId()
    var
        Settings: SessionSettings;
    begin
        Settings.Init();

        // A valid Windows language ID is a positive number (1033 en-US, 1030 da-DK, ...).
        // Zero is what an uninitialized Integer field reads as, so this distinguishes
        // "Init populated it" from "Init left it alone".
        Assert.IsTrue(Settings.LanguageId() > 0, 'Init() must populate LanguageId with a valid, non-zero Windows language ID');
    end;

    [Test]
    procedure SessionSettings_Init_PopulatesANonEmptyTimeZone()
    var
        Settings: SessionSettings;
    begin
        Settings.Init();

        Assert.AreNotEqual('', Settings.TimeZone(), 'Init() must populate TimeZone with a real Windows time zone name');
    end;

    [Test]
    procedure SessionSettings_Init_OverwritesValuesAssignedBeforehand()
    var
        Settings: SessionSettings;
        Sentinel: Text;
    begin
        // Init() loads settings into the instance, so it must replace what was already there
        // rather than merging into it or skipping fields that are already non-empty. The
        // sentinel is a company name no tenant can have, so its disappearance is proof that
        // Init() wrote over the field.
        Sentinel := 'ALT Sentinel Company ' + Format(CreateGuid());
        Settings.Company(Sentinel);
        Settings.Init();

        Assert.AreNotEqual(Sentinel, Settings.Company(), 'A value assigned before Init() must not survive the call');
        Assert.AreNotEqual('', Settings.Company(), 'Init() must replace the sentinel with a real company, not with nothing');
    end;

    // ---------------------------------------------------------------------------------------
    // 6. RequestSessionUpdate() is callable from inside a test.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_RequestSessionUpdate_WithoutSaving_IsCallableFromATest()
    var
        Settings: SessionSettings;
    begin
        // Under a test runner the platform intercepts the client round-trip, so the call
        // completes instead of failing for want of a client callback. saveSettings=false
        // means nothing is written to User Personalization.
        //
        // The assertions after the call are what make this more than a bare no-throw test:
        // the settings object must still hold its values afterwards, so a RequestSessionUpdate
        // that cleared or reset the instance would be caught.
        Settings.Init();
        Settings.LanguageId(1030);
        Settings.Company('ALT Company');

        Settings.RequestSessionUpdate(false);

        Assert.AreEqual(1030, Settings.LanguageId(), 'RequestSessionUpdate(false) must leave the settings instance intact');
        Assert.AreEqual('ALT Company', Settings.Company(), 'RequestSessionUpdate(false) must not clear Company');
    end;

    [Test]
    procedure SessionSettings_RequestSessionUpdate_DoesNotChangeTheRunningSessionLanguage()
    var
        Settings: SessionSettings;
        LanguageBefore: Integer;
    begin
        // A session update is a request to the CLIENT to start a new session with these
        // settings -- it does not retroactively change the language of the session that is
        // running now. This pins that the currently executing test session is unaffected,
        // which is what makes the whole surface safe to exercise in a test suite.
        LanguageBefore := GlobalLanguage();

        Settings.Init();
        Settings.LanguageId(1030);
        Settings.RequestSessionUpdate(false);

        Assert.AreEqual(
            LanguageBefore, GlobalLanguage(), 'RequestSessionUpdate must not change the running session''s global language');
    end;

    // ---------------------------------------------------------------------------------------
    // 7. A settings object has a formatted value, and equality is by value.
    //    (Only testable because Format/Variant conversion compile -- see the header.)
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure SessionSettings_Format_ReflectsTheAssignedValues()
    var
        Settings: SessionSettings;
        Formatted: Text;
    begin
        // Format() of a settings object renders its contents, so a distinctive time zone
        // must be visible in the result. This is what Assert.AreEqual falls through to for
        // this type, so pinning it explains the behavior of every comparison below.
        Settings.TimeZone('Pacific Standard Time');

        Formatted := Format(Settings);

        Assert.IsSubstring(Formatted, 'Pacific Standard Time');
    end;

    [Test]
    procedure SessionSettings_Format_DiffersWhenAPropertyDiffers()
    var
        First: SessionSettings;
        Second: SessionSettings;
    begin
        // The discriminating pair for Format(): two objects differing in exactly one
        // property must not format identically. An implementation returning a constant
        // string -- or the type name -- passes the substring test above only by accident and
        // fails here.
        First.TimeZone('UTC');
        Second.TimeZone('Pacific Standard Time');

        Assert.AreNotEqual(
            Format(First), Format(Second), 'Two settings objects differing in TimeZone must not format identically');
    end;

    [Test]
    procedure SessionSettings_TwoObjectsWithTheSameValues_CompareEqual()
    var
        First: SessionSettings;
        Second: SessionSettings;
    begin
        // Equality on this type is by value, not by identity: two independently built
        // objects carrying the same settings compare equal. Paired with the test below,
        // this rules out both "always equal" and "always unequal" implementations.
        First.Company('ALT Company');
        First.LanguageId(1030);
        Second.Company('ALT Company');
        Second.LanguageId(1030);

        Assert.AreEqual(First, Second, 'Two separately built settings objects with identical values must compare equal');
    end;

    [Test]
    procedure SessionSettings_TwoObjectsWithDifferentValues_CompareUnequal()
    var
        First: SessionSettings;
        Second: SessionSettings;
    begin
        First.Company('ALT Company');
        First.LanguageId(1030);
        Second.Company('ALT Company');
        Second.LanguageId(2057);

        Assert.AreNotEqual(First, Second, 'Settings objects differing only in LanguageId must not compare equal');
    end;

    [Test]
    procedure SessionSettings_Clear_DiscardsAssignedValues()
    var
        Settings: SessionSettings;
        Populated: SessionSettings;
        Pristine: SessionSettings;
    begin
        // Clear() returns a settings object to the state a freshly declared one is in.
        //
        // This is asserted RELATIVELY, against an untouched instance, rather than against
        // guessed constants: Microsoft documents LanguageId's "default value" as 1033 while
        // an unset integer field would read 0, and this file does not claim to know which of
        // those a pristine instance reports. What it does claim -- and what a broken Clear()
        // would violate -- is that after Clear() the object is indistinguishable from a
        // pristine one and distinguishable from the populated one it was a moment earlier.
        Settings.Company('ALT Company');
        Settings.LanguageId(1030);
        Populated.Company('ALT Company');
        Populated.LanguageId(1030);
        Assert.AreEqual(Populated, Settings, 'The two populated objects must match before Clear for this test to mean anything');

        Clear(Settings);

        Assert.AreEqual(Pristine, Settings, 'After Clear() a settings object must match a freshly declared one');
        Assert.AreNotEqual(Populated, Settings, 'After Clear() a settings object must no longer match its populated self');
        Assert.AreEqual('', Settings.Company(), 'Clear() must reset Company to empty');
    end;
}

// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Probe (writer BW): the order in which BC runs the subscribers of one event, inside one app and across apps (corpus #664 item 152;
//   al-runtime-rs ADR-046 amendment 1, probes Q1, Q2 and Q3). Pinned before: inside one app, ordinary events run their subscriber
//   codeunits in ascending codeunit id (record/TestTableEventSequenceContracts.al, handlers/ProbeEventSubscriberOrder.al).
//
// Q2, across apps. One event of cross-app fixture A ("LT BW XA Order Publisher".OnBwOrder) has subscribers in four apps:
//   app                          | app id                               | publisher             | subscriber codeunits (tag)
//   A  AL Language XApp A        | cd6a4292-f27b-4af9-89bc-15a5956f5c71 | AL Language           | 61105 (A1), 61135 (A2)
//   B  AL Language XApp B        | c87ced6d-11a6-4ad2-87c7-ac10083d0a2f | Zulu Probe Publisher  | 61115 (B1), 61145 (B2)
//   C  AL Language XApp C        | 0df0fadc-d339-4b0f-a1d5-51dc51f10900 | Bravo Probe Publisher | 61125 (C1), 61155 (C2)
//   M  AL Language Coverage Tests| a1b2c3d4-e5f6-7890-abcd-ef1234567890 | AL Language           | 83960..83964 (P Q R S T)
//   Dependencies: B on A, C on A and B, M on A, B and C; CI publishes A, B, C, then M. Order of the apps each candidate rule predicts:
//     dependency/publish ABCM (reverse MCBA) | app id as text CMBA (ABMC) | app id as Guid.ToByteArray bytes BAMC (CMAB)
//     app id as SQL Server uniqueidentifier ACBM (MBCA) | app name MABC (CBAM) | publisher, then name MACB (BCAM)
//     codeunit id ignoring the app: A1 B1 C1 A2 B2 C2 P Q R S T (the only rule that splits one app's subscribers).
// Q1, inside one app. The five subscriber codeunits P..T of this app (folders a-order, b-order, c-order) subscribe to the event above,
//   to an event of this app ("LT BW Order Publisher".OnBwLocalOrder) and to the two install events of "Extension Triggers":
//   P 83960 "LT BW M Subs" (b-order, 2nd in its file) | Q 83961 "LT BW b Subs" (a-order, 1st file) | R 83962 "LT BW C Subs" (b-order, 1st)
//   S 83963 "LT BW A Subs" (namespace Zzz.Probe, a-order, 2nd file) | T 83964 "LT BW Y Subs" (c-order)
//   Predictions: ascending id PQRST; descending id TSRQP; descending name, ordinal QTPRS; descending name ignoring case TPRQS;
//   descending name with namespace S first; ascending name ignoring case SQRPT; file order QSRPT.
// Q3: a subscriber of cross-app fixture A to Company Triggers counts its calls per session; A's and this app's install routines log the count.
// Install rows are written when the apps are installed (CI publish), so Initialize deletes nothing here.
// Fixtures: BwOrderFixtures.al, a-order/, b-order/, c-order/, tests/al-language-xapp-a|b|c. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 83950 "LT BW Subscriber Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure SubscriberOrder_OneEventOfADependencyApp_AcrossFourApps()
    var
        Publisher: Codeunit "LT BW XA Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.Raise());
        Observer.Observe('order again', Publisher.Raise());
        Observer.Finish();
    end;

    [Test]
    procedure SubscriberOrder_OneEventOfThisApp_FiveSubscriberCodeunits()
    var
        Publisher: Codeunit "LT BW Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.Raise());
        Observer.Observe('order again', Publisher.Raise());
        Observer.Finish();
    end;

    [Test]
    procedure InstallOrder_ThisApp_FiveSubscribersPerCompanyAndPerDatabase()
    var
        Row: Record "LT BW Install Log";
        Rows: Text;
        Counts: Text;
        Contexts: Text;
        FirstSession: Integer;
        OneSession: Boolean;
    begin
        Initialize();
        OneSession := true;
        Row.SetCurrentKey(Id);
        if Row.FindSet() then begin
            FirstSession := Row."Session Id";
            repeat
                Rows += Row.Routine + '@' + Row.Part + '|' + Row.Company + ';';
                Counts += Row.Routine + '=' + Format(Row."XA Company Open Calls") + ';';
                Contexts += Row.Context + ';';
                if Row."Session Id" <> FirstSession then
                    OneSession := false;
            until Row.Next() = 0;
        end;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('order', Rows);
        Observer.Observe('A company open calls', Counts);
        Observer.Observe('contexts', Contexts);
        Observer.Observe('one session', Format(OneSession));
        Observer.Observe('session is the test session', Format(FirstSession = SessionId()));
        Observer.Finish();
    end;

    [Test]
    procedure InstallOrder_DependencyAppA_TwoSubscribersAndCompanyOpenCalls()
    var
        Row: Record "LT BW XA Install Log";
        MainRow: Record "LT BW Install Log";
        Rows: Text;
        FirstSession: Integer;
        OneSession: Boolean;
    begin
        Initialize();
        OneSession := true;
        Row.SetCurrentKey(Id);
        if Row.FindSet() then begin
            FirstSession := Row."Session Id";
            repeat
                Rows += Row.Routine + '|' + Row.Company + '|calls=' + Format(Row."Company Open Calls") + '|' + Row.Context + ';';
                if Row."Session Id" <> FirstSession then
                    OneSession := false;
            until Row.Next() = 0;
        end;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('order', Rows);
        Observer.Observe('one session', Format(OneSession));
        if MainRow.FindFirst() then
            Observer.Observe('same session as the install of this app', Format(MainRow."Session Id" = FirstSession));
        Observer.Finish();
    end;

    local procedure Initialize()
    begin
        // The install logs hold rows written at install time; nothing to delete.
    end;
}

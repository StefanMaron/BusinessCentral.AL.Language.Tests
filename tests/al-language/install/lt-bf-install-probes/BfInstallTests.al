// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); read only: LT BF Install Log (81250, BfInstallFixtures.al), LT BF Fixture Install Log (61052, internals fixture app),
//   LT V Event Log (69840, PeVFixtures.al), Install Seed (60617), Install Seed Database (60621), Install StartSession Obs, BEI Setup: all written by install code
//   when the apps were installed.
// Probe: corpus issue 661 (writer BF): P1 companies, P3 what each company holds, P4 subscribers of a dependency app, P5 order across apps, P6 order inside one app,
//   P7 the per-database part, P8 sessions and SingleInstance state of the install run.
// Order across tables: SystemRowVersion is one counter for the whole database (install/lt-av-install-order/AvInstallOrder.al uses it the same way), so sorting
//   the rows the install code inserted by SystemRowVersion gives the order in which the install code ran.
// BC versions: 27 - 29
codeunit 81257 "LT BF Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    local procedure Plain(Value: Text): Text
    begin
        // The Probe Observer replaces the session company name by <Company>; underscores keep the name visible.
        exit(Value.Replace(' ', '_'));
    end;

    [Test]
    procedure Companies_OfTheDatabase_NamesInKeyOrder()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        N: Integer;
    begin
        if Company.FindSet() then
            repeat
                N += 1;
                Observer.Observe('company #' + Format(N), Plain(Company.Name) + '|' + Plain(Company."Display Name") + '|evaluation=' + Format(Company."Evaluation Company") + '|' + Tag(Company.Name));
            until Company.Next() = 0;
        Observer.Observe('companies', Format(N));
        Observer.Finish();
    end;

    local procedure CountIn(TableNo: Integer; Company: Text): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo, false, Company);
        exit(Format(RecRef.Count()));
    end;

    [Test]
    procedure Companies_BaseTableRows_ReadFromATest()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
    begin
        if Company.FindSet() then
            repeat
                Observer.Observe(Tag(Company.Name) + ' rows', '79=' + CountIn(79, Company.Name) + ';98=' + CountIn(98, Company.Name) + ';242=' + CountIn(242, Company.Name) + ';77=' + CountIn(77, Company.Name) + ';308=' + CountIn(308, Company.Name));
            until Company.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure InstallLog_RowsOfThisApp_InIdOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BF Install Log";
        FixtureRow: Record "LT BF Fixture Install Log";
        Sessions: List of [Integer];
        FixtureSessions: List of [Integer];
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Observer.Observe('row #' + Format(Row.Id), Row."Source" + '|' + Row."Event Name" + '|' + Tag(Row."Company") + '|context=' + Row."Context" + '|counter=' + Format(Row."Counter")
                    + '|fixture counter=' + Format(Row."Fixture Counter") + '|company open calls=' + Format(Row."Company Open Calls") + '|' + Row.Info);
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('sessions of this app''s install', Format(Sessions.Count()));
        Observer.Observe('install session is the test session', Format(Sessions.Contains(SessionId())));
        if FixtureRow.FindSet() then
            repeat
                if not FixtureSessions.Contains(FixtureRow."Session Id") then
                    FixtureSessions.Add(FixtureRow."Session Id");
            until FixtureRow.Next() = 0;
        if (Sessions.Count() = 1) and (FixtureSessions.Count() = 1) then
            Observer.Observe('fixture install ran in the same session', Format(Sessions.Get(1) = FixtureSessions.Get(1)));
        Observer.Finish();
    end;

    [Test]
    procedure FixtureLog_RowsOfTheDependencyApp_InIdOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BF Fixture Install Log";
        Sessions: List of [Integer];
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Observer.Observe('row #' + Format(Row.Id), Row."Event Name" + '|' + Tag(Row."Company") + '|context=' + Row."Context" + '|counter=' + Format(Row."Counter"));
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Finish();
    end;

    local procedure AddPoint(var Versions: List of [BigInteger]; var Labels: List of [Text]; Version: BigInteger; PointLabel: Text)
    begin
        Versions.Add(Version);
        Labels.Add(PointLabel);
    end;

    local procedure InVersionOrder(var Versions: List of [BigInteger]; var Labels: List of [Text]): Text
    var
        Result: Text;
        Best: Integer;
        i: Integer;
    begin
        while Versions.Count() > 0 do begin
            Best := 1;
            for i := 2 to Versions.Count() do
                if Versions.Get(i) < Versions.Get(Best) then
                    Best := i;
            Result += Labels.Get(Best) + ';';
            Versions.RemoveAt(Best);
            Labels.RemoveAt(Best);
        end;
        exit(Result);
    end;

    [Test]
    procedure InstallOrder_AllInstallRows_InSystemRowVersionOrder()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Row: Record "LT BF Install Log";
        FixtureRow: Record "LT BF Fixture Install Log";
        PevRow: Record "LT V Event Log";
        Seed: Record "Install Seed";
        SeedDatabase: Record "Install Seed Database";
        StartSessionObs: Record "Install StartSession Obs";
        BeiSetup: Record "BEI Setup";
        Versions: List of [BigInteger];
        Labels: List of [Text];
    begin
        if FixtureRow.FindSet() then
            repeat
                AddPoint(Versions, Labels, FixtureRow.SystemRowVersion, 'fixture subs ' + FixtureRow."Event Name" + ' (' + Tag(FixtureRow."Company") + ')');
            until FixtureRow.Next() = 0;
        if Row.FindSet() then
            repeat
                AddPoint(Versions, Labels, Row.SystemRowVersion, Row."Source" + ' ' + Row."Event Name" + ' (' + Tag(Row."Company") + ')');
            until Row.Next() = 0;
        PevRow.SetFilter("Event Name", '%1|%2', 'OnInstallAppPerCompany', 'OnInstallAppPerDatabase');
        if PevRow.FindSet() then
            repeat
                AddPoint(Versions, Labels, PevRow.SystemRowVersion, 'PeV subs ' + PevRow."Event Name" + ' (' + Tag(PevRow.Info) + ')');
            until PevRow.Next() = 0;
        if SeedDatabase.Get('DATABASE') then
            AddPoint(Versions, Labels, SeedDatabase.SystemRowVersion, 'Install Seeder OnInstallAppPerDatabase');
        if Company.FindSet() then
            repeat
                Seed.ChangeCompany(Company.Name);
                if Seed.Get('COMPANY1') then
                    AddPoint(Versions, Labels, Seed.SystemRowVersion, 'Install Seeder OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
                StartSessionObs.ChangeCompany(Company.Name);
                if StartSessionObs.Get('STARTSESSION') then
                    AddPoint(Versions, Labels, StartSessionObs.SystemRowVersion, 'Install StartSession Probe OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
                BeiSetup.ChangeCompany(Company.Name);
                if BeiSetup.FindFirst() then
                    AddPoint(Versions, Labels, BeiSetup.SystemRowVersion, 'BEI Installer OnInstallAppPerCompany (' + Tag(Company.Name) + ')');
            until Company.Next() = 0;
        Observer.Observe('order', InVersionOrder(Versions, Labels));
        Observer.Finish();
    end;
}

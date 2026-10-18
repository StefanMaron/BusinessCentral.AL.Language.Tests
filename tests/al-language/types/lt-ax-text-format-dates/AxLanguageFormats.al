// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Format(DMY2Date(1, m, 2024), 0, 4) and format 7 for all 12 months with GlobalLanguage 1033, 1031, 1036 and 3082;
//   Format of a Duration of 1 day, 2 days, 2 hours, 1 minute, 1 second and 1 millisecond with GlobalLanguage 1033, 1031 and 1036.
//   Each test sets GlobalLanguage back before it checks its values.
// BC versions: 27.5+

codeunit 80425 "LT AX Language Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Months(Language: Integer; FormatNo: Integer): Text
    var
        Saved: Integer;
        S: Text;
        m: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        for m := 1 to 12 do
            S += Format(DMY2Date(1, m, 2024), 0, FormatNo) + ';';
        GlobalLanguage(Saved);
        exit(S);
    end;

    local procedure Durations(Language: Integer): Text
    var
        Saved: Integer;
        S: Text;
        D: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        D := 86400000;
        S := Format(D) + ';';
        D := 172800000;
        S += Format(D) + ';';
        D := 7200000;
        S += Format(D) + ';';
        D := 60000;
        S += Format(D) + ';';
        D := 1000;
        S += Format(D) + ';';
        D := 1;
        S += Format(D);
        GlobalLanguage(Saved);
        exit(S);
    end;

    [Test]
    procedure Months_Format4_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033 f4', Months(1033, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format7_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033 f7', Months(1033, 7));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format4_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031 f4', Months(1031, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format7_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031 f7', Months(1031, 7));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format4_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036 f4', Months(1036, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format7_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036 f7', Months(1036, 7));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format4_Spanish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('3082 f4', Months(3082, 4));
        Observer.Finish();
    end;

    [Test]
    procedure Months_Format7_Spanish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('3082 f7', Months(3082, 7));
        Observer.Finish();
    end;

    [Test]
    procedure Durations_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033', Durations(1033));
        Observer.Finish();
    end;

    [Test]
    procedure Durations_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031', Durations(1031));
        Observer.Finish();
    end;

    [Test]
    procedure Durations_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036', Durations(1036));
        Observer.Finish();
    end;
}

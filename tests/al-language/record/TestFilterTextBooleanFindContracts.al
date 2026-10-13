// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins how SetFilter treats case (a Text filter without @ is case sensitive; a Code filter is not),
// wildcards inside quotes, the leading @ inside quotes, which words a Boolean filter accepts (and the
// error for one it does not), and that every form of Find honours the active filters.
// BC versions: 27.5

codeunit 68210 "Probe Filter Text Bool Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Code Field" := 'APPLE';
        ALTUniversal."Text Field" := 'Apple';
        ALTUniversal."Boolean Field" := true;
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal."Code Field" := 'BANANA';
        ALTUniversal."Text Field" := 'apple';
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 3;
        ALTUniversal."Code Field" := 'AP-2';
        ALTUniversal."Text Field" := 'A*B';
        ALTUniversal."Boolean Field" := true;
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 4;
        ALTUniversal."Code Field" := 'X?Y';
        ALTUniversal."Text Field" := '@home';
        ALTUniversal.Insert();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 5;
        ALTUniversal."Boolean Field" := true;
        ALTUniversal.Insert();
        Commit();
    end;


    [Test]
    procedure SetFilter_CodeField_IsCaseInsensitive()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        ALTUniversal.SetFilter("Code Field", 'ap*');
        Assert.AreEqual(2, ALTUniversal.Count(), 'ap* matches APPLE and AP-2');
        ALTUniversal.SetFilter("Code Field", '@ap*');
        Assert.AreEqual(2, ALTUniversal.Count(), '@ap*');
        ALTUniversal.SetFilter("Code Field", 'apple');
        Assert.AreEqual(1, ALTUniversal.Count(), 'apple');
    end;

    [Test]
    procedure SetFilter_TextField_IsCaseSensitive_UnlessItStartsWithAt()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        ALTUniversal.SetFilter("Text Field", 'apple');
        Assert.AreEqual(1, ALTUniversal.Count(), 'apple matches only the lower case row');
        ALTUniversal.SetFilter("Text Field", '@apple');
        Assert.AreEqual(2, ALTUniversal.Count(), '@apple matches both');
        ALTUniversal.SetFilter("Text Field", 'ap*');
        Assert.AreEqual(1, ALTUniversal.Count(), 'ap*');
        ALTUniversal.SetFilter("Text Field", '@ap*');
        Assert.AreEqual(2, ALTUniversal.Count(), '@ap*');
    end;

    [Test]
    procedure SetFilter_QuotedValue_AtSignInsideQuotesStillMeansCaseInsensitive()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        ALTUniversal.SetFilter("Text Field", '''A*B''');
        Assert.AreEqual(1, ALTUniversal.Count(), 'quoted A*B finds the row with a literal asterisk');
        ALTUniversal.SetFilter("Text Field", '''@home''');
        Assert.AreEqual(0, ALTUniversal.Count(), 'a quoted @home does not find the row whose text is "@home"');
    end;

    [Test]
    procedure SetFilter_BooleanField_AcceptedWords()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        ALTUniversal.SetFilter("Boolean Field", 'Yes');
        Assert.AreEqual(3, ALTUniversal.Count(), 'Yes');
        ALTUniversal.SetFilter("Boolean Field", 'yes');
        Assert.AreEqual(3, ALTUniversal.Count(), 'yes');
        ALTUniversal.SetFilter("Boolean Field", 'true');
        Assert.AreEqual(3, ALTUniversal.Count(), 'true');
        ALTUniversal.SetFilter("Boolean Field", '1');
        Assert.AreEqual(3, ALTUniversal.Count(), '1');
        ALTUniversal.SetFilter("Boolean Field", '%1', true);
        Assert.AreEqual(3, ALTUniversal.Count(), '%1 with true');
        ALTUniversal.SetFilter("Boolean Field", 'No');
        Assert.AreEqual(2, ALTUniversal.Count(), 'No');
        ALTUniversal.SetFilter("Boolean Field", 'false');
        Assert.AreEqual(2, ALTUniversal.Count(), 'false');
        ALTUniversal.SetFilter("Boolean Field", '0');
        Assert.AreEqual(2, ALTUniversal.Count(), '0');
        ALTUniversal.SetFilter("Boolean Field", '%1', false);
        Assert.AreEqual(2, ALTUniversal.Count(), '%1 with false');
    end;

    [Test]
    procedure SetFilter_BooleanField_UnknownWord_Throws()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();

        asserterror ALTUniversal.SetFilter("Boolean Field", 'Ja');

        Assert.AreEqual('The filter "Ja" is not valid for the Boolean Field field on the ALT Universal table. The value "Ja" can''t be evaluated into type Boolean.', GetLastErrorText(), 'text');
        Assert.AreEqual('Filter:CSide', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Find_AllForms_HonourTheActiveFilters()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Code Field", 'APPLE');

        ALTUniversal."Entry No." := 2;
        Assert.IsFalse(ALTUniversal.Find(), 'Find() of a key outside the filter');
        ALTUniversal."Entry No." := 2;
        Assert.IsFalse(ALTUniversal.Find('='), 'Find(=)');
        ALTUniversal."Entry No." := 2;
        Assert.IsFalse(ALTUniversal.Find('>='), 'Find(>=) from a key past the only row inside the filter');
        ALTUniversal."Entry No." := 0;
        Assert.IsTrue(ALTUniversal.Find('>'), 'Find(>) from 0');
        Assert.AreEqual(1, ALTUniversal."Entry No.", 'lands on the first row inside the filter');
        ALTUniversal."Entry No." := 1;
        Assert.IsTrue(ALTUniversal.Find(), 'Find() of a key inside the filter');
    end;
}

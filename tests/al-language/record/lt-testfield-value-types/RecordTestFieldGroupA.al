// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: table 67900 and codeunit 67901 (TestFieldValueFixture.al), Probe Observer
// Probe: Record.TestField(Field, Value) for BigInteger, Boolean, Code, Decimal and Enum values (plain, ErrorInfo, collected)
// BC versions: 27 and later (values by CI matrix)

codeunit 67904 "LT R RTF A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BigInteger_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: BigInteger;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := 5000000000L;
        Rec.TestField("Big Int", Val);
        Observer.Observe('equal', 'no error');
        Val := 5000000001L;
        asserterror Rec.TestField("Big Int", Val);
        Observer.ObserveError('different');
        Observer.Finish();
    end;

    [Test]
    procedure BigInteger_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: BigInteger;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5000000000L;
        Rec.TestField("Big Int", Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 5000000001L;
        asserterror Rec.TestField("Big Int", Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField("Big Int", Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField("Big Int", Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure BigInteger_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: BigInteger;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 5000000001L;
        Rec.TestField("Big Int", Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Boolean;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := true;
        Rec.TestField(Bool, Val);
        Observer.Observe('equal', 'no error');
        Val := false;
        asserterror Rec.TestField(Bool, Val);
        Observer.ObserveError('different');
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Boolean;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := true;
        Rec.TestField(Bool, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := false;
        asserterror Rec.TestField(Bool, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Bool, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Bool, Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Boolean_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Boolean;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := false;
        Rec.TestField(Bool, Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Code_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Code[10];
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := 'ABC';
        Rec.TestField(Cd, Val);
        Observer.Observe('equal', 'no error');
        Val := 'ABD';
        asserterror Rec.TestField(Cd, Val);
        Observer.ObserveError('different');
        Observer.Finish();
    end;

    [Test]
    procedure Code_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Code[10];
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 'ABC';
        Rec.TestField(Cd, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 'ABD';
        asserterror Rec.TestField(Cd, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Cd, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Cd, Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Code_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Code[10];
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 'ABD';
        Rec.TestField(Cd, Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Decimal;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := 12.5;
        Rec.TestField(Dec, Val);
        Observer.Observe('equal', 'no error');
        Val := 12.6;
        asserterror Rec.TestField(Dec, Val);
        Observer.ObserveError('different');
        Observer.Finish();
    end;

    [Test]
    procedure Decimal_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Decimal;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 12.5;
        Rec.TestField(Dec, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 12.6;
        asserterror Rec.TestField(Dec, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(Dec, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(Dec, Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Decimal_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Decimal;
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := 12.6;
        Rec.TestField(Dec, Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Enum_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        Rec.FindFirst();
        Val := Val::Green;
        Rec.TestField(En, Val);
        Observer.Observe('equal', 'no error');
        Val := Val::Blue;
        asserterror Rec.TestField(En, Val);
        Observer.ObserveError('different');
        Observer.Finish();
    end;

    [Test]
    procedure Enum_ErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := Val::Green;
        Rec.TestField(En, Val, Info);
        Observer.Observe('equal', 'no error');
        Val := Val::Blue;
        asserterror Rec.TestField(En, Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Info.Collectible := true;
        asserterror Rec.TestField(En, Val, Info);
        Observer.ObserveError('different_collectible_outside');
        Clear(Info);
        asserterror Rec.TestField(En, Val, Info);
        Observer.ObserveError('different_empty_info');
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure Enum_Collect()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT R Helper";
        Rec: Record "LT R Row";
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        Val: Enum "LT R Color";
    begin
        Helper.Seed();
        Rec.FindFirst();
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.Collectible := true;
        Val := Val::Blue;
        Rec.TestField(En, Val, Info);
        Observer.Observe('after_call', 'reached');
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Errs := GetCollectedErrors(true);
        Observer.Observe('collected_count', Format(Errs.Count()));
        if Errs.Count() > 0 then begin
            Info := Errs.Get(1);
            Observer.Observe('collected_message', Info.Message);
            Observer.Observe('collected_title', Info.Title);
            Observer.Observe('collected_collectible', Format(Info.Collectible));
        end;
        Observer.Finish();
    end;
}

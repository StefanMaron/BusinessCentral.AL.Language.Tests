codeunit 67371 "ALT Manual Sub Passer"
{
    // Hands an "ALT Manual Event Sub" instance across a procedure boundary several ways, so a
    // test can observe whether the callee's exit releases the instance's manual binding.

    procedure ReadFireCountByValue(ManualSub: Codeunit "ALT Manual Event Sub"): Integer
    begin
        exit(ManualSub.GetFireCount());
    end;

    procedure BindLocalAndReturn(): Boolean
    var
        LocalSub: Codeunit "ALT Manual Event Sub";
    begin
        exit(BindSubscription(LocalSub));
    end;

    procedure BindTwoSharingLocalsAndReturn(): Boolean
    var
        FirstSub: Codeunit "ALT Manual Event Sub";
        SecondSub: Codeunit "ALT Manual Event Sub";
    begin
        SecondSub := FirstSub;
        exit(BindSubscription(FirstSub));
    end;

    procedure BindPassByValueAndReturn(): Integer
    var
        LocalSub: Codeunit "ALT Manual Event Sub";
    begin
        BindSubscription(LocalSub);
        exit(ReadFireCountByValue(LocalSub));
    end;

    procedure BindCopyToSiblingViaCalleeAndReturn(): Boolean
    var
        LocalSub: Codeunit "ALT Manual Event Sub";
        SiblingSub: Codeunit "ALT Manual Event Sub";
        Bound: Boolean;
    begin
        Bound := BindSubscription(LocalSub);
        CopyInto(LocalSub, SiblingSub);
        exit(Bound);
    end;

    procedure BindSingleInstanceLocalAndReturn(): Boolean
    var
        LocalSub: Codeunit "ALT SI Manual Event Sub";
    begin
        exit(BindSubscription(LocalSub));
    end;

    local procedure CopyInto(Source: Codeunit "ALT Manual Event Sub"; var Target: Codeunit "ALT Manual Event Sub")
    begin
        Target := Source;
    end;

    procedure BindLocalIntoCallerVariable(var CallerSub: Codeunit "ALT Manual Event Sub"): Boolean
    var
        LocalSub: Codeunit "ALT Manual Event Sub";
        Bound: Boolean;
    begin
        Bound := BindSubscription(LocalSub);
        CallerSub := LocalSub;
        exit(Bound);
    end;
}

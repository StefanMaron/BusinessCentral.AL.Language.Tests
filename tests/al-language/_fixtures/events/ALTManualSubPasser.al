codeunit 67371 "ALT Manual Sub Passer"
{
    // Hands an "ALT Manual Event Sub" instance across a procedure boundary four ways, so a
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

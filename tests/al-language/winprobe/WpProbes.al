// Windows-check scratch probes (branch al-runtime-rs-staging-winprobe only). Observe form: each test fails with OBSERVE:<values>.
codeunit 85065 "WP Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WP_CL_OneLetterFieldSubscriberRows()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", 84786);
        Observer.Observe('count', Format(Sub.Count()));
        if Sub.FindSet() then
            repeat
                Observer.Observe(Sub."Subscriber Function", Sub."Published Function" + ' | active=' + Format(Sub.Active) + ' | err=' + Sub."Error Information");
            until Sub.Next() = 0;
        Observer.Finish();
    end;

#if BC28PLUS
    [Test]
    procedure WP_CU_RunByQualifiedName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Observer.Observe('plain ok', Format(TryRunByName('LTCU.Probe.LT CU Named Run', Row)));
        Observer.ObserveError('plain');
        Observer.Observe('plain name', Row.Name);
        Clear(Row);
        Observer.Observe('quoted ok', Format(TryRunByName('LTCU.Probe."LT CU Named Run"', Row)));
        Observer.ObserveError('quoted');
        Observer.Observe('quoted name', Row.Name);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRunByName(Name: Text; var Row: Record "LT CU Row")
    begin
        Codeunit.Run(Name, Row);
    end;
#endif
}

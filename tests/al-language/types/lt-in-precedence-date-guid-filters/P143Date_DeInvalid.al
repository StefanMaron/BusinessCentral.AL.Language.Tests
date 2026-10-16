// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: table 74647 and codeunit 74648 (P143Fixtures.al), codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74655 "LT P143 DeInvalid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // every statement that can raise sits inside the helper's TryFunctions, so Run cannot leave the language changed
    local procedure Run(var Observer: Codeunit "Probe Observer"; var Helper: Codeunit "LT P143 Helper")
    begin
        Helper.ProbeDate(Observer, 'i_iso', '2027-01-17');
        Helper.ProbeDate(Observer, 'i_abc', 'abc');
        Helper.ProbeDate(Observer, 'i_month13', '45.13.27');
        Helper.ProbeDate(Observer, 'i_us_2027', '01/17/2027');
        Helper.ProbeDate(Observer, 'i_wild', '01.*');
    end;
}

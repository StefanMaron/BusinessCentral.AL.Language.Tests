// @expect AL0477 | The trigger 'OnValidateUpgradePerCompany' can only be used if the property 'Subtype' of 'MNC AB Plain' is set to 'Upgrade'
// @expect AL0477 | The trigger 'OnValidateUpgradePerDatabase' can only be used if the property 'Subtype' of 'MNC AB Plain' is set to 'Upgrade'
// OnValidateUpgradePerCompany and OnValidateUpgradePerDatabase are valid only in a codeunit with Subtype = Upgrade (such a codeunit runs at publish, so the corpus holds none: .github/scripts/check-install-triggers.py).
codeunit 50900 "MNC AB Plain"
{
    trigger OnValidateUpgradePerCompany()
    begin
    end;

    trigger OnValidateUpgradePerDatabase()
    begin
    end;
}

// @expect AL0296 | The application object or method 'LogSecurityAudit' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Session.LogSecurityAudit named from a Cloud app (the method has scope OnPrem).
codeunit 50575 "MNC O 0575"
{
    procedure Probe()
    
    begin
        Session.LogSecurityAudit('a', SecurityOperationResult::Success, 'x', AuditCategory::ApplicationManagement);
    end;
}

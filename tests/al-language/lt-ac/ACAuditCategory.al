// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/auditcategory/auditcategory-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the AuditCategory option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, Evaluate by name and by number, and the error text of Evaluate for an invalid name and ordinal. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for AuditCategory.
// BC versions: 27, 28, 29

codeunit 77512 "LT AC Audit Category Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_AuditCategory_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Other', Format(AuditCategory::Other));
        Observer.Observe('text_UserManagement', Format(AuditCategory::UserManagement));
        Observer.Observe('text_GroupManagement', Format(AuditCategory::GroupManagement));
        Observer.Observe('text_Authentication', Format(AuditCategory::Authentication));
        Observer.Observe('text_Authorization', Format(AuditCategory::Authorization));
        Observer.Observe('text_RoleManagement', Format(AuditCategory::RoleManagement));
        Observer.Observe('text_ApplicationManagement', Format(AuditCategory::ApplicationManagement));
        Observer.Observe('text_KeyManagement', Format(AuditCategory::KeyManagement));
        Observer.Observe('text_DirectoryManagement', Format(AuditCategory::DirectoryManagement));
        Observer.Observe('text_ResourceManagement', Format(AuditCategory::ResourceManagement));
        Observer.Observe('text_PolicyManagement', Format(AuditCategory::PolicyManagement));
        Observer.Observe('text_DeviceManagement', Format(AuditCategory::DeviceManagement));
        Observer.Observe('text_EntitlementManagement', Format(AuditCategory::EntitlementManagement));
        Observer.Observe('text_PasswordManagement', Format(AuditCategory::PasswordManagement));
        Observer.Observe('text_IdentityProtection', Format(AuditCategory::IdentityProtection));
        Observer.Observe('text_ObjectManagement', Format(AuditCategory::ObjectManagement));
        Observer.Observe('text_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement));
        Observer.Observe('text_CustomerFacing', Format(AuditCategory::CustomerFacing));
        Observer.Observe('text_Euii', Format(AuditCategory::Euii));
        Observer.Observe('ordinal_Other', Format(AuditCategory::Other, 0, 2));
        Observer.Observe('ordinal_UserManagement', Format(AuditCategory::UserManagement, 0, 2));
        Observer.Observe('ordinal_GroupManagement', Format(AuditCategory::GroupManagement, 0, 2));
        Observer.Observe('ordinal_Authentication', Format(AuditCategory::Authentication, 0, 2));
        Observer.Observe('ordinal_Authorization', Format(AuditCategory::Authorization, 0, 2));
        Observer.Observe('ordinal_RoleManagement', Format(AuditCategory::RoleManagement, 0, 2));
        Observer.Observe('ordinal_ApplicationManagement', Format(AuditCategory::ApplicationManagement, 0, 2));
        Observer.Observe('ordinal_KeyManagement', Format(AuditCategory::KeyManagement, 0, 2));
        Observer.Observe('ordinal_DirectoryManagement', Format(AuditCategory::DirectoryManagement, 0, 2));
        Observer.Observe('ordinal_ResourceManagement', Format(AuditCategory::ResourceManagement, 0, 2));
        Observer.Observe('ordinal_PolicyManagement', Format(AuditCategory::PolicyManagement, 0, 2));
        Observer.Observe('ordinal_DeviceManagement', Format(AuditCategory::DeviceManagement, 0, 2));
        Observer.Observe('ordinal_EntitlementManagement', Format(AuditCategory::EntitlementManagement, 0, 2));
        Observer.Observe('ordinal_PasswordManagement', Format(AuditCategory::PasswordManagement, 0, 2));
        Observer.Observe('ordinal_IdentityProtection', Format(AuditCategory::IdentityProtection, 0, 2));
        Observer.Observe('ordinal_ObjectManagement', Format(AuditCategory::ObjectManagement, 0, 2));
        Observer.Observe('ordinal_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement, 0, 2));
        Observer.Observe('ordinal_CustomerFacing', Format(AuditCategory::CustomerFacing, 0, 2));
        Observer.Observe('ordinal_Euii', Format(AuditCategory::Euii, 0, 2));
        Observer.Observe('number_Other', Format(AuditCategory::Other, 0, 1));
        Observer.Observe('number_UserManagement', Format(AuditCategory::UserManagement, 0, 1));
        Observer.Observe('number_GroupManagement', Format(AuditCategory::GroupManagement, 0, 1));
        Observer.Observe('number_Authentication', Format(AuditCategory::Authentication, 0, 1));
        Observer.Observe('number_Authorization', Format(AuditCategory::Authorization, 0, 1));
        Observer.Observe('number_RoleManagement', Format(AuditCategory::RoleManagement, 0, 1));
        Observer.Observe('number_ApplicationManagement', Format(AuditCategory::ApplicationManagement, 0, 1));
        Observer.Observe('number_KeyManagement', Format(AuditCategory::KeyManagement, 0, 1));
        Observer.Observe('number_DirectoryManagement', Format(AuditCategory::DirectoryManagement, 0, 1));
        Observer.Observe('number_ResourceManagement', Format(AuditCategory::ResourceManagement, 0, 1));
        Observer.Observe('number_PolicyManagement', Format(AuditCategory::PolicyManagement, 0, 1));
        Observer.Observe('number_DeviceManagement', Format(AuditCategory::DeviceManagement, 0, 1));
        Observer.Observe('number_EntitlementManagement', Format(AuditCategory::EntitlementManagement, 0, 1));
        Observer.Observe('number_PasswordManagement', Format(AuditCategory::PasswordManagement, 0, 1));
        Observer.Observe('number_IdentityProtection', Format(AuditCategory::IdentityProtection, 0, 1));
        Observer.Observe('number_ObjectManagement', Format(AuditCategory::ObjectManagement, 0, 1));
        Observer.Observe('number_ProvisioningManagement', Format(AuditCategory::ProvisioningManagement, 0, 1));
        Observer.Observe('number_CustomerFacing', Format(AuditCategory::CustomerFacing, 0, 1));
        Observer.Observe('number_Euii', Format(AuditCategory::Euii, 0, 1));
        Observer.Finish();
    end;

    [Test]
    procedure AC_AuditCategory_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := AuditCategory::Euii;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = AuditCategory::Euii));
        Observer.Observe('eq_first', Format(V = AuditCategory::Other));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure AC_AuditCategory_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        V := AuditCategory::Other;
        Observer.Observe('case_Other', CaseName(V));
        V := AuditCategory::UserManagement;
        Observer.Observe('case_UserManagement', CaseName(V));
        V := AuditCategory::GroupManagement;
        Observer.Observe('case_GroupManagement', CaseName(V));
        V := AuditCategory::Authentication;
        Observer.Observe('case_Authentication', CaseName(V));
        V := AuditCategory::Authorization;
        Observer.Observe('case_Authorization', CaseName(V));
        V := AuditCategory::RoleManagement;
        Observer.Observe('case_RoleManagement', CaseName(V));
        V := AuditCategory::ApplicationManagement;
        Observer.Observe('case_ApplicationManagement', CaseName(V));
        V := AuditCategory::KeyManagement;
        Observer.Observe('case_KeyManagement', CaseName(V));
        V := AuditCategory::DirectoryManagement;
        Observer.Observe('case_DirectoryManagement', CaseName(V));
        V := AuditCategory::ResourceManagement;
        Observer.Observe('case_ResourceManagement', CaseName(V));
        V := AuditCategory::PolicyManagement;
        Observer.Observe('case_PolicyManagement', CaseName(V));
        V := AuditCategory::DeviceManagement;
        Observer.Observe('case_DeviceManagement', CaseName(V));
        V := AuditCategory::EntitlementManagement;
        Observer.Observe('case_EntitlementManagement', CaseName(V));
        V := AuditCategory::PasswordManagement;
        Observer.Observe('case_PasswordManagement', CaseName(V));
        V := AuditCategory::IdentityProtection;
        Observer.Observe('case_IdentityProtection', CaseName(V));
        V := AuditCategory::ObjectManagement;
        Observer.Observe('case_ObjectManagement', CaseName(V));
        V := AuditCategory::ProvisioningManagement;
        Observer.Observe('case_ProvisioningManagement', CaseName(V));
        V := AuditCategory::CustomerFacing;
        Observer.Observe('case_CustomerFacing', CaseName(V));
        V := AuditCategory::Euii;
        Observer.Observe('case_Euii', CaseName(V));
        Observer.Finish();
    end;

    local procedure CaseName(V: AuditCategory): Text
    begin
        case V of
            AuditCategory::Other:
                exit('is_Other');
            AuditCategory::UserManagement:
                exit('is_UserManagement');
            AuditCategory::GroupManagement:
                exit('is_GroupManagement');
            AuditCategory::Authentication:
                exit('is_Authentication');
            AuditCategory::Authorization:
                exit('is_Authorization');
            AuditCategory::RoleManagement:
                exit('is_RoleManagement');
            AuditCategory::ApplicationManagement:
                exit('is_ApplicationManagement');
            AuditCategory::KeyManagement:
                exit('is_KeyManagement');
            AuditCategory::DirectoryManagement:
                exit('is_DirectoryManagement');
            AuditCategory::ResourceManagement:
                exit('is_ResourceManagement');
            AuditCategory::PolicyManagement:
                exit('is_PolicyManagement');
            AuditCategory::DeviceManagement:
                exit('is_DeviceManagement');
            AuditCategory::EntitlementManagement:
                exit('is_EntitlementManagement');
            AuditCategory::PasswordManagement:
                exit('is_PasswordManagement');
            AuditCategory::IdentityProtection:
                exit('is_IdentityProtection');
            AuditCategory::ObjectManagement:
                exit('is_ObjectManagement');
            AuditCategory::ProvisioningManagement:
                exit('is_ProvisioningManagement');
            AuditCategory::CustomerFacing:
                exit('is_CustomerFacing');
            AuditCategory::Euii:
                exit('is_Euii');
            else
                exit('other');
        end;
    end;
}

codeunit 77513 "LT AC Audit Category Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_AuditCategory_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := Evaluate(V, 'Other');
        Observer.Observe('name_Other', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'UserManagement');
        Observer.Observe('name_UserManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'GroupManagement');
        Observer.Observe('name_GroupManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Authentication');
        Observer.Observe('name_Authentication', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Authorization');
        Observer.Observe('name_Authorization', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'RoleManagement');
        Observer.Observe('name_RoleManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ApplicationManagement');
        Observer.Observe('name_ApplicationManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'KeyManagement');
        Observer.Observe('name_KeyManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'DirectoryManagement');
        Observer.Observe('name_DirectoryManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ResourceManagement');
        Observer.Observe('name_ResourceManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'PolicyManagement');
        Observer.Observe('name_PolicyManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'DeviceManagement');
        Observer.Observe('name_DeviceManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'EntitlementManagement');
        Observer.Observe('name_EntitlementManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'PasswordManagement');
        Observer.Observe('name_PasswordManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'IdentityProtection');
        Observer.Observe('name_IdentityProtection', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ObjectManagement');
        Observer.Observe('name_ObjectManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ProvisioningManagement');
        Observer.Observe('name_ProvisioningManagement', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'CustomerFacing');
        Observer.Observe('name_CustomerFacing', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Euii');
        Observer.Observe('name_Euii', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'usermanagement');
        Observer.Observe('name_lowercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'USERMANAGEMENT');
        Observer.Observe('name_uppercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '0');
        Observer.Observe('number_0', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '1');
        Observer.Observe('number_1', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '2');
        Observer.Observe('number_2', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '3');
        Observer.Observe('number_3', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '4');
        Observer.Observe('number_4', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '5');
        Observer.Observe('number_5', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '6');
        Observer.Observe('number_6', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '7');
        Observer.Observe('number_7', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '8');
        Observer.Observe('number_8', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '9');
        Observer.Observe('number_9', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '10');
        Observer.Observe('number_10', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '11');
        Observer.Observe('number_11', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '12');
        Observer.Observe('number_12', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '13');
        Observer.Observe('number_13', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '14');
        Observer.Observe('number_14', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '15');
        Observer.Observe('number_15', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '16');
        Observer.Observe('number_16', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '17');
        Observer.Observe('number_17', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '18');
        Observer.Observe('number_18', Format(Ok) + '/' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure AC_AuditCategory_EvaluateInvalid()
    var
        Observer: Codeunit "Probe Observer";
        V: AuditCategory;
    begin
        Clear(V);
        if Evaluate(V, 'Bogus') then
            Observer.Observe('bogus_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('bogus');
        Clear(V);
        if Evaluate(V, '') then
            Observer.Observe('empty_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('empty');
        Clear(V);
        if Evaluate(V, '19') then
            Observer.Observe('past_end_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('past_end');
        Clear(V);
        if Evaluate(V, '99') then
            Observer.Observe('large_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('large');
        Clear(V);
        if Evaluate(V, '-1') then
            Observer.Observe('negative_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('negative');
        Clear(V);
        if Evaluate(V, ' UserManagement') then
            Observer.Observe('space_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('space');
        Clear(V);
        if Evaluate(V, '1.5') then
            Observer.Observe('decimal_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('decimal');
        Observer.Finish();
    end;
}

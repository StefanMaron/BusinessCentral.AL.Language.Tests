// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects of UObsoleteObjects.al
// Probe (issue 602): Pending objects and controls still compile and run. The warning a Pending object gives is not visible to AL code or to the must-not-compile harness (it records errors only). Object id 69799.

codeunit 69799 "LT U Obsolete Pending Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Pending_CodeunitInterfaceEnum_StillRun()
    var
        Observer: Codeunit "Probe Observer";
        Obsolete: Codeunit "LT U Obsolete CU";
        Intf: Interface "LT U Obsolete Interface";
        ScopeIntf: Interface "LT U Scope Interface";
        Value: Enum "LT U Obsolete Enum";
        Ordinals: List of [Integer];
        Index: Integer;
        Names: Text;
    begin
        Observer.Observe('codeunit_answer', Format(Obsolete.Answer()));
        Intf := Obsolete;
        Observer.Observe('interface_answer', Format(Intf.Answer()));
        ScopeIntf := Obsolete;
        Observer.Observe('scope_cloud_interface_ping', Format(ScopeIntf.Ping()));
        Value := Value::Old;
        Observer.Observe('enum_value_old', Format(Value));
        Observer.Observe('enum_value_old_ordinal', Format(Value.AsInteger()));
        Value := Value::ExtOld;
        Observer.Observe('enum_ext_value_old', Format(Value));
        Observer.Observe('enum_ext_value_old_ordinal', Format(Value.AsInteger()));
        Ordinals := Value.Ordinals();
        foreach Index in Ordinals do
            Names += Value.Names().Get(Ordinals.IndexOf(Index)) + ',';
        Observer.Observe('enum_names', Names);
        Observer.Finish();
    end;

    [Test]
    procedure Pending_PageAndControls_StillOpen()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT U Page Src";
        Card: TestPage "LT U Obsolete Page";
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'one';
        Src.Insert();
        Card.OpenView();
        asserterror begin Observer.Observe('group_field', Card.InObsGroup.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('group_field|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('group_field_visible', Format(Card.InObsGroup.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('group_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('cue_field', Card.InObsCue.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('cue_field|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('label_visible', Format(Card.ObsLabel.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('label_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('action_enabled', Format(Card.ObsAction.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('action_enabled|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_field_visible', Format(Card.ObsExtField.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_group_field', Card.InObsExtGroup.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_group_field|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_action_enabled', Format(Card.ObsExtAction.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_action_enabled|failed')
        else
            ClearLastError();
        asserterror begin Card.ObsAction.Invoke(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('Card_ObsAction_Invoke_|failed')
        else
            ClearLastError();
        asserterror begin Card.ObsExtAction.Invoke(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('Card_ObsExtAction_Invoke_|failed')
        else
            ClearLastError();
        asserterror begin Card.Close(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('close|failed')
        else
            ClearLastError();
        Observer.Finish();
    end;

    [Test]
    procedure Pending_QueryReportXmlPort_StillRun()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Src: Record "LT U Page Src";
        Qry: Query "LT U Obsolete Query";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 7;
        Src.Insert();
        Observer.Observe('query_open', Format(Qry.Open()));
        Observer.Observe('query_read', Format(Qry.Read()));
        Observer.Observe('query_id', Format(Qry.Id));
        Qry.Close();
        Report.Run(Report::"LT U Obsolete Report", false, false);
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT U Obsolete XmlPort", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '\n';
        end;
        Observer.Observe('xmlport_export', Xml);
        Observer.Finish();
    end;
}

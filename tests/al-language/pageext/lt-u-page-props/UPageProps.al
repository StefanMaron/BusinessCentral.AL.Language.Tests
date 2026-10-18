// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in UPageObjects.al
// Probe (issue 600): states a TestPage reports for controls that a page extension adds or modifies (field, group, part, action, label),
// DecimalPlaces and AutoFormat output, DrillDown and Lookup on or off, part UpdatePropagation, an API page with a part and read only intent,
// and the Enabled property of a profile extension. Object id 69592.

codeunit 69592 "LT U Page Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LookupOpened: Integer;

    local procedure Seed()
    var
        Src: Record "LT U Page Src";
    begin
        Src.DeleteAll();
        Src.Init();
        Src.Id := 1;
        Src.Txt := 'first';
        Src.Dec := 1234.5;
        Src.Note := 'note';
        Src.Rel := 1;
        Src.AutoPlain := 1234.5;
        Src.AutoCustom := 1234.5;
        Src.AutoCurrency := 1234.5;
        Src.Insert();
    end;

    [Test]
    procedure PageExt_FieldAndGroupStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Observer.Observe('base_group_visible_field_visible', Format(Card.InVisibleGroup.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_group_visible_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_group_editable_field_editable', Format(Card.InEditableGroup.Editable())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_group_editable_field_editable|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_group_editable_field_visible', Format(Card.InEditableGroup.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_group_editable_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_group_hidden_field_visible', Format(Card.ExtInHidden.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_group_hidden_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_group_readonly_field_editable', Format(Card.ExtInReadOnly.Editable())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_group_readonly_field_editable|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_group_readonly_field_visible', Format(Card.ExtInReadOnly.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_group_readonly_field_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('modify_field_enabled_off', Format(Card.EnabledField.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('modify_field_enabled_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('modify_field_enabled_off_editable', Format(Card.EnabledField.Editable())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('modify_field_enabled_off_editable|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_field_enabled_off', Format(Card.ExtEnabledOff.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_field_enabled_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_field_enabled_off_editable', Format(Card.ExtEnabledOff.Editable())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_field_enabled_off_editable|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_field_default_enabled', Format(Card.ExtDec.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_field_default_enabled|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('label_enabled_after_modify', Format(Card.Lbl.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('label_enabled_after_modify|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('label_visible', Format(Card.Lbl.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('label_visible|failed')
        else
            ClearLastError();
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageExt_DecimalPlacesAndAutoFormat()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('base_decimal_places_2', Card.DecField.Value);
        Observer.Observe('ext_decimal_places_3', Card.ExtDec.Value);
        Observer.Observe('table_ext_auto_plain', Card.AutoPlainField.Value);
        Observer.Observe('table_ext_auto_custom', Card.AutoCustomField.Value);
        Observer.Observe('table_ext_auto_currency', Card.AutoCurrencyField.Value);
        Observer.Observe('table_ext_auto_custom_on_ext_control', Card.ExtAutoCustom.Value);
        Observer.Observe('page_auto_on_base_control', Card.AutoOnPage.Value);
        Observer.Observe('page_auto_on_ext_control', Card.ExtAutoPage.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageExt_DrillDownOnAndOff()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Card.DrillOn.Drilldown(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('base_on|no_error', 'true');
        end else
            Observer.ObserveError('base_on');
        asserterror begin Card.DrillOff.Drilldown(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('base_off|no_error', 'true');
        end else
            Observer.ObserveError('base_off');
        asserterror begin Card.ExtDrillOn.Drilldown(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('ext_on|no_error', 'true');
        end else
            Observer.ObserveError('ext_on');
        asserterror begin Card.ExtDrillOff.Drilldown(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('ext_off|no_error', 'true');
        end else
            Observer.ObserveError('ext_off');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure PageExt_LookupOnAndOff()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        LookupOpened := 0;
        asserterror begin Card.LookupField.Lookup(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('Card_LookupField_Lookup_|failed')
        else
            ClearLastError();
        Observer.Observe('base_lookup_pages_opened', Format(LookupOpened));
        LookupOpened := 0;
        asserterror begin Card.ExtLookupOn.Lookup(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('Card_ExtLookupOn_Lookup_|failed')
        else
            ClearLastError();
        Observer.Observe('ext_on_pages_opened', Format(LookupOpened));
        LookupOpened := 0;
        asserterror Card.ExtLookupOff.Lookup();
        Observer.Observe('ext_off_pages_opened', Format(LookupOpened));
        Observer.ObserveError('ext_off');
        Card.Close();
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LookupHandler(var LookupList: TestPage "LT U Lookup List")
    begin
        LookupOpened += 1;
        LookupList.Cancel().Invoke();
    end;

    [Test]
    procedure PageExt_ActionStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror begin Observer.Observe('base_enabled_modified_off', Format(Card.ActEnabled.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_enabled_modified_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_enabled_modified_off_visible', Format(Card.ActEnabled.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_enabled_modified_off_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_visible_modified_off', Format(Card.ActVisible.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_visible_modified_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_visible_modified_off_enabled', Format(Card.ActVisible.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_visible_modified_off_enabled|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_scope_page', Format(Card.ActScope.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_scope_page|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('base_footer_false', Format(Card.ActFooter.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('base_footer_false|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('actionref_hidden_modified_visible', Format(Card.ActRefTarget.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('actionref_hidden_modified_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_enabled_off', Format(Card.ExtActEnabledOff.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_enabled_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_enabled_off_visible', Format(Card.ExtActEnabledOff.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_enabled_off_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_visible_off', Format(Card.ExtActVisibleOff.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_visible_off|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_visible_off_enabled', Format(Card.ExtActVisibleOff.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_visible_off_enabled|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_scope_repeater_visible', Format(Card.ExtActScope.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_scope_repeater_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('ext_scope_repeater_enabled', Format(Card.ExtActScope.Enabled())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('ext_scope_repeater_enabled|failed')
        else
            ClearLastError();
        asserterror begin Card.ExtActScope.Invoke(); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('Card_ExtActScope_Invoke_|failed')
        else
            ClearLastError();
        Observer.Observe('ext_scope_repeater_invoked', 'ok');
        asserterror begin Card.ExtActEnabledOff.Invoke(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('ext_enabled_off_invoke|no_error', 'true');
        end else
            Observer.ObserveError('ext_enabled_off_invoke');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageExt_PartStates()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('part_host_visible', Format(Card.PartHost.Visible()));
        Observer.Observe('part_host_editable', Format(Card.PartHost.Editable()));
        Observer.Observe('part_sub_visible', Format(Card.PartSub.Visible()));
        Observer.Observe('part_sub_editable', Format(Card.PartSub.Editable()));
        Observer.Observe('ext_part_visible', Format(Card.ExtPart.Visible()));
        Observer.Observe('ext_part_editable', Format(Card.ExtPart.Editable()));
        Observer.Observe('ext_part_row_id', Card.ExtPart.Id.Value);
        Observer.Observe('ext_part_row_txt', Card.ExtPart.Txt.Value);
        Observer.Observe('ext_part_row_id_editable', Format(Card.ExtPart.Id.Editable()));
        Observer.Observe('ext_part_row_txt_editable', Format(Card.ExtPart.Txt.Editable()));
        Card.ExtPart.Filter.SetFilter(Txt, 'zzz');
        Observer.Observe('ext_part_filtered_first', Format(Card.ExtPart.First()));
        Observer.Observe('ext_part_filtered_first_txt', Card.ExtPart.Txt.Value);
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Part_UpdatePropagation_BothAndSubPart()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT U Base Card";
        Src: Record "LT U Page Src";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('host_before', Card.DrillOn.Value);
        Card.PartHost.Txt.SetValue('from both');
        Observer.Observe('host_after_part_both_edit', Card.DrillOn.Value);
        Observer.Observe('sibling_sub_part_after_both_edit', Card.PartSub.Txt.Value);
        Card.PartSub.Txt.SetValue('from subpart');
        Observer.Observe('host_after_part_subpart_edit', Card.DrillOn.Value);
        Observer.Observe('sibling_both_part_after_subpart_edit', Card.PartHost.Txt.Value);
        Card.Close();
        Src.Get(1);
        Observer.Observe('record_after_close', Src.Txt);
        Observer.Finish();
    end;

    [Test]
    procedure PageExt_PageLevel_Editable_And_DataCaptionExpression()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT U Lookup List";
        Card: TestPage "LT U Base Card";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('list_caption', List.Caption());
        Observer.Observe('list_txt_editable', Format(List.Txt.Editable()));
        Observer.Observe('list_id_editable', Format(List.Id.Editable()));
        List.Close();
        Card.OpenView();
        Observer.Observe('card_caption', Card.Caption());
        Observer.Observe('card_txt_editable_in_view', Format(Card.DrillOn.Editable()));
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ApiPage_PartAndReadOnlyIntent()
    var
        Observer: Codeunit "Probe Observer";
        Api: TestPage "LT U Api Page";
    begin
        Seed();
        Api.OpenView();
        asserterror begin Observer.Observe('first', Format(Api.First())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('first|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('txt', Api.txt.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('txt|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('txt_editable', Format(Api.txt.Editable())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('txt_editable|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('lines_visible', Format(Api.lines.Visible())); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('lines_visible|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('lines_row_txt', Api.lines.Txt.Value); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('lines_row_txt|failed')
        else
            ClearLastError();
        asserterror begin Observer.Observe('page_caption', Api.Caption()); Error('NOERROR'); end;
        if GetLastErrorText() <> 'NOERROR' then
            Observer.ObserveError('page_caption|failed')
        else
            ClearLastError();
        asserterror begin Api.txt.SetValue('changed'); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('set_on_read_only|no_error', 'true');
        end else
            Observer.ObserveError('set_on_read_only');
        Api.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageIntent_ApiPageOpenEditKeepsReadOnly()
    var
        Observer: Codeunit "Probe Observer";
        Api: TestPage "LT U Api Page";
    begin
        Seed();
        asserterror begin Api.OpenEdit(); Error('NOERROR'); end;
        if GetLastErrorText() = 'NOERROR' then begin
            ClearLastError();
            Observer.Observe('open_edit|no_error', 'true');
        end else
            Observer.ObserveError('open_edit');
        Observer.Finish();
    end;

    [Test]
    procedure ProfileExtension_EnabledFalse_ProfileLookup()
    var
        Observer: Codeunit "Probe Observer";
        Profile: Record "All Profile";
    begin
        Profile.SetRange("Profile ID", 'LT U PROFILE');
        Observer.Observe('count_by_id', Format(Profile.Count()));
        if Profile.FindFirst() then begin
            Observer.Observe('enabled', Format(Profile.Enabled));
            Observer.Observe('role_center_id', Format(Profile."Role Center ID"));
            Observer.Observe('caption', Profile.Description);
        end;
        Profile.Reset();
        Profile.SetRange("Role Center ID", 69590);
        Observer.Observe('count_by_role_center', Format(Profile.Count()));
        Profile.SetRange(Enabled, true);
        Observer.Observe('count_by_role_center_enabled', Format(Profile.Count()));
        Observer.Finish();
    end;
}

// @expect AL0324 | The language ENU must only be specified one time.
report 50817 "MNC Y Search Dup"
{
    ProcessingOnly = true;
    AdditionalSearchTermsML = ENU = 'a', ENU = 'b';
}

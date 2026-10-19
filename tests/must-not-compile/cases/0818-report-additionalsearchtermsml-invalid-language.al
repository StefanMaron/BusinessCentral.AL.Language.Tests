// @expect AL0160 | 'XXX' is not a valid language identifier
report 50818 "MNC Y Search Lang"
{
    ProcessingOnly = true;
    AdditionalSearchTermsML = XXX = 'a';
}

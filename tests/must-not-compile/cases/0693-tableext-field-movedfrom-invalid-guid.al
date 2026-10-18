// @expect AL0734 | The value 'Base Application' of the property 'MovedFrom' is not a valid GUID.
// MovedFrom takes the id of an app, a GUID.
tableextension 59693 "MNC U Ext 693" extends Customer
{
    fields { field(59693; MncMoved; Text[20]) { MovedFrom = 'Base Application'; } }
}

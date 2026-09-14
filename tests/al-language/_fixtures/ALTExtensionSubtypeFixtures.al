// Fixtures for the two *extension object kinds AllObjWithCaption's "Object Subtype" column
// (field 30) had no corpus coverage for: reportextension and permissionsetextension.
//
// AL Runner issue StefanMaron/BusinessCentral.AL.Runner#3566. Corpus PR #291 pinned the
// column for tableextension, pageextension and enumextension; these two were left resting on
// a decompiled switch arm in which all five kinds share one `case` body. That is a reading of
// the source, not a service-tier measurement, and this repository's evidence ordering puts a
// green corpus test above it.
//
// TWO OF EACH KIND, EXTENDING DIFFERENT TARGETS. A single fixture per kind cannot
// discriminate: an implementation answering one constant -- including the empty string every
// kind would otherwise take, or the extension's own id -- passes a one-fixture test. The
// pairs below target objects with ids far apart, which additionally rules out "the id minus a
// fixed offset". That is the shape #291's three kinds use, copied deliberately.

reportextension 60011 "ALT Simple Report Ext" extends "ALT Simple Report"
{
    // Extends report 60018. Adds nothing: the subject is the AllObjWithCaption row this
    // declaration produces, not any rendering behaviour.
}

reportextension 60012 "ALT Tx None Rep Ext" extends "ALT Run Tx None Rep Inserter"
{
    // Extends report 60412 -- a different target, read the same way. 60412 and 60018 are
    // 394 apart, and neither is near either extension's own id.
}

permissionsetextension 60019 "ALT NonAssignable Ext" extends "ALT NonAssignable"
{
    // Extends permissionset 60023.
    Permissions = tabledata "ALT Universal" = R;
}

permissionsetextension 60021 "ALT Agg Perm Set Ext" extends "ALT Agg Perm Set"
{
    // Extends permissionset 60930 -- a different target, 907 away from the first.
    Permissions = tabledata "ALT Universal" = R;
}

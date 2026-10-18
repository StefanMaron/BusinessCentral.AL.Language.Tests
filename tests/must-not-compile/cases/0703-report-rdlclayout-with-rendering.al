// @expect AL0706 | The property 'WordLayout' cannot be used while also specifying the rendering section
// @expect AL0706 | The property 'RDLCLayout' cannot be used while also specifying the rendering section
// RDLCLayout and WordLayout cannot be used while the report has a rendering section.
table 59703 "MNC U 703" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
report 59703 "MNC U Rep 703"
{
    DefaultRenderingLayout = L1;
    RDLCLayout = './Mnc703.rdlc';
    WordLayout = './Mnc703.docx';
    dataset { dataitem(Row; "MNC U 703") { column(Id; Id) { } } }
    rendering { layout(L1) { Type = RDLC; LayoutFile = './Mnc703.rdlc'; } }
}

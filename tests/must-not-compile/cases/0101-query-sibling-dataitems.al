// @expect AL0342 | You cannot combine two DataItems at the same level because unions are not supported.
// @expect AL0342 | You cannot combine two DataItems at the same level because unions are not supported.
// A query with two dataitems nested under the same parent dataitem (siblings).
table 50101 "MNC Sibling Parent"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 50102 "MNC Sibling Child"
{
    fields { field(1; Id; Integer) { } field(2; ParentId; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50103 "MNC Sibling Query"
{
    elements
    {
        dataitem(Parent; "MNC Sibling Parent")
        {
            column(Id; Id) { }
            dataitem(ChildA; "MNC Sibling Child")
            {
                DataItemLink = ParentId = Parent.Id;
                column(ChildAId; Id) { }
            }
            dataitem(ChildB; "MNC Sibling Child")
            {
                DataItemLink = ParentId = Parent.Id;
                column(ChildBId; Id) { }
            }
        }
    }
}

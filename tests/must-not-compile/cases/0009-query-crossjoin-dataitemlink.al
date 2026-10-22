// @expect AL0365 | The property 'DataItemLink' cannot be set if the property 'SqlJoinType' is set to 'CrossJoin'
// A nested query data item with SqlJoinType = CrossJoin states a DataItemLink.
table 50000 "MNC Parent"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 50001 "MNC Child"
{
    fields { field(1; Id; Integer) { } field(2; ParentId; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50002 "MNC Cross Join Query"
{
    elements
    {
        dataitem(Parent; "MNC Parent")
        {
            column(Id; Id) { }

            dataitem(Child; "MNC Child")
            {
                SqlJoinType = CrossJoin;
                DataItemLink = ParentId = Parent.Id;

                column(ChildId; Id) { }
            }
        }
    }
}

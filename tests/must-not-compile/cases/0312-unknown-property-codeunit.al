// @expect AL0124 | The property 'NoSuchProperty' cannot be used in this context. Verify the property is available for the current object type.
// A property that does not exist on a codeunit.
codeunit 50128 "MNC C312"
{
    NoSuchProperty = true;
}

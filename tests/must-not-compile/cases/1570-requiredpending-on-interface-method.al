// @expect AL0187 | Attribute 'RequiredPending' is valid only for normal methods.
// @from 29
// Corpus #664 item 19. [RequiredPending] on a method of an interface is refused with AL0187 at runtime 18.0 (BC 29). The attribute
// belongs on the implementing codeunit method (cases 0995 to 0997 and 0971 pin the runtime gate). For BC 27 and 28 see case 1571.
interface "MNC BM I1570"
{
    [RequiredPending('Use the new procedure', '29.0')]
    procedure Foo();
}

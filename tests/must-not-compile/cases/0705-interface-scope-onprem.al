// @expect AL0850 | This feature is under development and is exclusively accessible to Microsoft.
// @expect AL0296 | The application object or method 'MNC U Intf 705' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// Scope = OnPrem on an interface is refused for a Cloud app.
interface "MNC U Intf 705" { Scope = OnPrem; procedure P(); }

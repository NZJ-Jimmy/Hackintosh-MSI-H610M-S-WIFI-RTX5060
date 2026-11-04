// DSDT: \_SB.AWAC._STA uses STAS==0; LPCB.RTC._STA uses STAS==1.
// The original tables have no root \_INI; change the selector only for Darwin.
DefinitionBlock ("", "SSDT", 2, "LOCAL", "AwacRtc", 1)
{
    External (STAS, FieldUnitObj)
    Scope (\)
    {
        Method (_INI, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { STAS = One }
        }
    }
}

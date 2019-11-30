#DEFINE VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
#DEFINE VFP_OPTIONS_KEY2	"\Options"
#DEFINE HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1

local cEditorVariableColor, cForeColor, cBackColor, cRegKey, cVFPOptPath
local oRegApi

cVFPOptPath = VFP_OPTIONS_KEY1 + _vfp.version + VFP_OPTIONS_KEY2

oRegApi = newobject("Registry", home() + "FFC\Registry.VCX")

oRegApi.getregkey("EditorVariableColor", @cEditorVariableColor, cVFPOptPath, HKEY_CURRENT_USER)

cForeColor = substr(cEditorVariableColor, 5, at(",", cEditorVariableColor, 3) - 5)
cBackColor = substr(cEditorVariableColor, at(",", cEditorVariableColor, 3) + 1, at(")", cEditorVariableColor, 1) - at(",", cEditorVariableColor, 3) - 1)

_screen.forecolor = rgb(&cForeColor)
_screen.backcolor = rgb(&cBackColor)
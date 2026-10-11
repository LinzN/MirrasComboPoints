-- Mirra's Combo Points: settings

local ADDON, ns = ...

local PANEL_NAME = "Mirra's Combo Points"
local PREFIX = "|cffffcc00MCP|r: "

local L = {
    SUBTITLE        = "Combo points on your target's nameplate.",
    PREVIEW         = "Preview",
    PREVIEW_DESC    = "(dummy nameplate – updates live with your settings)",
    DUMMY_NAME      = "Training Dummy",
    APPEARANCE      = "Appearance",
    POSITION        = "Position",
    COLORS          = "Style & colors",
    BEHAVIOR        = "Behavior",
    SHAPE           = "Shape",
    STYLE           = "Style",
    SIZE            = "Pip size",
    SPACING         = "Spacing",
    OPACITY         = "Opacity",
    ANCHOR          = "Anchor",
    ABOVE           = "Above health bar",
    BELOW           = "Below health bar",
    OFFSET_X        = "Horizontal offset",
    OFFSET_Y        = "Vertical offset",
    COLOR_MODE      = "Color mode",
    GRADIENT        = "Gradient",
    SINGLE          = "Single color",
    COLOR_START     = "Color / gradient start",
    COLOR_END       = "Gradient end",
    FULL            = "Custom color when full",
    FULL_DESC       = "Separate color when all combo points are up.",
    COLOR_FULL      = "Full points color",
    COLOR_EMPTY     = "Empty slot color",
    SHOW_EMPTY      = "Show empty slots",
    SHOW_EMPTY_DESC = "Dark slots for missing combo points.",
    HIDE_ZERO       = "Hide at 0 combo points",
    HIDE_ZERO_DESC  = "Hides everything while the target has no combo points.",
    RESET           = "Restore defaults",
    RESET_DONE      = "Settings restored to defaults.",
    HINT            = "Note: Only tested with the default Blizzard nameplates. Enemy nameplates must be enabled (V).\nQuick access: /mcp",
}

local panel, category
local controls = {}

local function Apply()
    if ns.Update then ns.Update() end
end

local function Register(w)
    controls[#controls + 1] = w
    return w
end

local function SectionHeader(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 0.25)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetWidth(270 - fs:GetStringWidth() - 8)
    return fs
end

local function Checkbox(parent, key, label, desc, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", x - 4, y)

    local text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    text:SetText(label)

    if desc then
        local sub = cb:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        sub:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
        sub:SetWidth(240)
        sub:SetJustifyH("LEFT")
        sub:SetText(desc)
    end

    cb:SetScript("OnClick", function(self)
        ns.db[key] = self:GetChecked() and true or false
        if PlaySound and SOUNDKIT then
            PlaySound(ns.db[key] and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        end
        Apply()
    end)
    cb.Refresh = function() cb:SetChecked(ns.db[key]) end
    return Register(cb)
end

local function Cycle(parent, key, label, options, x, y)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y - 5)
    text:SetText(label)

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(140, 22)
    btn:SetPoint("TOPLEFT", x + 130, y)

    local function textFor(v)
        for _, o in ipairs(options) do
            if o[1] == v then return o[2] end
        end
        return tostring(v)
    end
    btn:SetScript("OnClick", function()
        local idx = 1
        for i, o in ipairs(options) do
            if o[1] == ns.db[key] then idx = i end
        end
        ns.db[key] = options[idx % #options + 1][1]
        btn:SetText(textFor(ns.db[key]))
        Apply()
    end)
    btn.Refresh = function() btn:SetText(textFor(ns.db[key])) end
    return Register(btn)
end

-- Row of clickable shape icons; the selected one is highlighted in gold.
local function ShapePicker(parent, label, x, y)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(270, 24)
    holder:SetPoint("TOPLEFT", x, y)

    local text = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", 0, 0)
    text:SetText(label)

    local buttons = {}
    for i, shape in ipairs(ns.SHAPES) do
        local b = CreateFrame("Button", nil, holder)
        b:SetSize(22, 22)
        b:SetPoint("LEFT", 62 + (i - 1) * 23, 0)

        local sel = b:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints()
        sel:SetColorTexture(1, 0.82, 0, 0.22)

        -- The texture has a glow margin around the shape, so draw it larger.
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", -3, 3)
        icon:SetPoint("BOTTOMRIGHT", 3, -3)
        icon:SetTexture(ns.MEDIA .. shape.key .. "_mask")

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.12)

        b:SetScript("OnClick", function()
            ns.db.shape = shape.key
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            holder.Refresh()
            Apply()
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(shape.name)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)

        b.key, b.sel, b.icon = shape.key, sel, icon
        buttons[i] = b
    end

    holder.Refresh = function()
        for _, b in ipairs(buttons) do
            local on = ns.db.shape == b.key
            b.sel:SetShown(on)
            if on then
                b.icon:SetVertexColor(1, 0.82, 0.1)
            else
                b.icon:SetVertexColor(0.65, 0.65, 0.65)
            end
        end
    end
    return Register(holder)
end

local function RoundTo(v, step)
    return math.floor(v / step + 0.5) * step
end

local function FallbackSlider(holder, key, minV, maxV, step, fmt)
    local s = CreateFrame("Slider", nil, holder)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(200, 16)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0.15, 0.15, 0.15, 1)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT")
    track:SetHeight(6)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1, 0.75, 0.1, 1)
    thumb:SetSize(10, 16)
    s:SetThumbTexture(thumb)
    local value = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    value:SetPoint("LEFT", s, "RIGHT", 8, 0)
    s:SetScript("OnValueChanged", function(self, v)
        v = RoundTo(v, step)
        value:SetText(fmt(v))
        if self.updating then return end
        ns.db[key] = v
        Apply()
    end)
    s.Refresh = function()
        s.updating = true
        s:SetValue(ns.db[key])
        value:SetText(fmt(ns.db[key]))
        s.updating = false
    end
    return s
end

local function Slider(parent, key, label, minV, maxV, step, fmt, x, y)
    fmt = fmt or function(v) return tostring(math.floor(v + 0.5)) end
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(270, 44)
    holder:SetPoint("TOPLEFT", x, y)

    local text = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetText(label)

    local ok, s = pcall(CreateFrame, "Frame", nil, holder, "MinimalSliderWithSteppersTemplate")
    if ok and s and s.Init and MinimalSliderWithSteppersMixin then
        s:SetSize(230, 20)
        s:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -2, -4)
        local formatters
        if CreateMinimalSliderFormatter and MinimalSliderWithSteppersMixin.Label then
            formatters = {
                [MinimalSliderWithSteppersMixin.Label.Right] =
                    CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt),
            }
        end
        s:Init(ns.db[key], minV, maxV, math.floor((maxV - minV) / step + 0.5), formatters)
        s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v)
            ns.db[key] = RoundTo(v, step)
            Apply()
        end, holder)
        holder.Refresh = function() s:SetValue(ns.db[key]) end
    else
        local fs = FallbackSlider(holder, key, minV, maxV, step, fmt)
        fs:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -8)
        holder.Refresh = fs.Refresh
    end
    return Register(holder)
end

local function OpenColorPicker(c, hasAlpha, onChange)
    local prev = { r = c.r, g = c.g, b = c.b, a = c.a }
    local function read()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        c.r, c.g, c.b = r, g, b
        if hasAlpha then
            local a
            if ColorPickerFrame.GetColorAlpha then
                a = ColorPickerFrame:GetColorAlpha()
            elseif OpacitySliderFrame then
                a = 1 - OpacitySliderFrame:GetValue()
            end
            c.a = a or c.a
        end
        onChange()
    end
    local function cancel()
        c.r, c.g, c.b, c.a = prev.r, prev.g, prev.b, prev.a
        onChange()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c.r, g = c.g, b = c.b,
            opacity = c.a or 1,
            hasOpacity = hasAlpha,
            swatchFunc = read,
            opacityFunc = read,
            cancelFunc = cancel,
        })
    else
        ColorPickerFrame.hasOpacity = hasAlpha
        ColorPickerFrame.opacity = 1 - (c.a or 1)
        ColorPickerFrame.func = read
        ColorPickerFrame.opacityFunc = read
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

local function Swatch(parent, key, label, hasAlpha, x, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(270, 22)
    btn:SetPoint("TOPLEFT", x, y)

    local text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", 0, 0)
    text:SetText(label)

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetSize(34, 18)
    border:SetPoint("LEFT", 170, 0)
    border:SetColorTexture(0.8, 0.8, 0.8, 1)
    local checker = btn:CreateTexture(nil, "BORDER")
    checker:SetPoint("TOPLEFT", border, 1, -1)
    checker:SetPoint("BOTTOMRIGHT", border, -1, 1)
    checker:SetColorTexture(0.25, 0.25, 0.25, 1)
    local col = btn:CreateTexture(nil, "ARTWORK")
    col:SetAllPoints(checker)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(border)
    hl:SetColorTexture(1, 1, 1, 0.25)

    btn.Refresh = function()
        local c = ns.db[key]
        col:SetColorTexture(c.r, c.g, c.b, hasAlpha and (c.a or 1) or 1)
    end
    btn:SetScript("OnClick", function()
        OpenColorPicker(ns.db[key], hasAlpha, function()
            btn.Refresh()
            Apply()
        end)
    end)
    return Register(btn)
end

local function BuildPanel()
    panel = CreateFrame("Frame")
    panel:Hide()
    panel.name = PANEL_NAME

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(PANEL_NAME)

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L.SUBTITLE)

    local pTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pTitle:SetPoint("TOPLEFT", 16, -64)
    pTitle:SetText(L.PREVIEW)
    local pSub = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    pSub:SetPoint("LEFT", pTitle, "RIGHT", 8, 0)
    pSub:SetText(L.PREVIEW_DESC)

    local box = CreateFrame("Frame", nil, panel)
    box:SetPoint("TOPLEFT", 16, -84)
    box:SetSize(584, 96)
    local boxBg = box:CreateTexture(nil, "BACKGROUND")
    boxBg:SetAllPoints()
    boxBg:SetColorTexture(0, 0, 0, 0.35)
    if box.SetClipsChildren then box:SetClipsChildren(true) end

    local function Border(f, inset)
        local edge = f:CreateTexture(nil, "BACKGROUND", nil, -8)
        edge:SetPoint("TOPLEFT", -inset - 2, inset + 2)
        edge:SetPoint("BOTTOMRIGHT", inset + 2, -inset - 2)
        edge:SetColorTexture(0, 0, 0, 1)
        local gold = f:CreateTexture(nil, "BACKGROUND", nil, -7)
        gold:SetPoint("TOPLEFT", -inset - 1, inset + 1)
        gold:SetPoint("BOTTOMRIGHT", inset + 1, -inset - 1)
        gold:SetColorTexture(0.86, 0.78, 0.6, 1)
        local inner = f:CreateTexture(nil, "BACKGROUND", nil, -6)
        inner:SetPoint("TOPLEFT", -inset, inset)
        inner:SetPoint("BOTTOMRIGHT", inset, -inset)
        inner:SetColorTexture(0, 0, 0, 1)
    end

    local plate = CreateFrame("StatusBar", nil, box)
    plate:SetSize(146, 20)
    plate:SetPoint("CENTER", -14, -10)
    plate:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    plate:SetStatusBarColor(0.9, 0.02, 0.02)
    plate:SetMinMaxValues(0, 1)
    plate:SetValue(1)
    Border(plate, 1)

    local plateName = plate:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    plateName:SetPoint("LEFT", 6, 0)
    plateName:SetText(L.DUMMY_NAME)
    local plateHP = plate:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    plateHP:SetPoint("RIGHT", -6, 0)
    plateHP:SetText("164")

    local level = CreateFrame("Frame", nil, box)
    level:SetSize(18, 18)
    level:SetPoint("LEFT", plate, "RIGHT", 6, 0)
    Border(level, 1)
    local levelText = level:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("CENTER", 0, 0)
    levelText:SetTextColor(0.1, 1, 0.1)
    levelText:SetText("8")

    local preview = ns.CreatePreview(box, plate)
    preview:SetFrameLevel(plate:GetFrameLevel() + 5)

    local LX, RX = 16, 330
    local y = -196
    SectionHeader(panel, L.APPEARANCE, LX, y)
    ShapePicker(panel, L.SHAPE, LX, y - 22)
    Slider(panel, "size", L.SIZE, 4, 40, 1, nil, LX, y - 52)
    Slider(panel, "spacing", L.SPACING, 0, 20, 1, nil, LX, y - 98)
    Slider(panel, "alpha", L.OPACITY, 0.1, 1, 0.05,
        function(v) return string.format("%d%%", v * 100 + 0.5) end, LX, y - 144)

    SectionHeader(panel, L.POSITION, LX, y - 198)
    Cycle(panel, "anchor", L.ANCHOR, { { "TOP", L.ABOVE }, { "BOTTOM", L.BELOW } }, LX, y - 220)
    Slider(panel, "offsetX", L.OFFSET_X, -100, 100, 1, nil, LX, y - 250)
    Slider(panel, "offsetY", L.OFFSET_Y, -50, 50, 1, nil, LX, y - 296)

    SectionHeader(panel, L.COLORS, RX, y)
    local styles = {}
    for _, st in ipairs(ns.STYLES) do styles[#styles + 1] = { st.key, st.name } end
    Cycle(panel, "style", L.STYLE, styles, RX, y - 22)
    Cycle(panel, "colorMode", L.COLOR_MODE, { { "gradient", L.GRADIENT }, { "single", L.SINGLE } }, RX, y - 52)
    Swatch(panel, "colorStart", L.COLOR_START, false, RX, y - 82)
    Swatch(panel, "colorEnd", L.COLOR_END, false, RX, y - 108)
    Checkbox(panel, "useFullColor", L.FULL, L.FULL_DESC, RX, y - 134)
    Swatch(panel, "colorFull", L.COLOR_FULL, false, RX, y - 174)
    Swatch(panel, "colorEmpty", L.COLOR_EMPTY, true, RX, y - 200)

    SectionHeader(panel, L.BEHAVIOR, RX, y - 228)
    Checkbox(panel, "showEmpty", L.SHOW_EMPTY, L.SHOW_EMPTY_DESC, RX, y - 248)
    Checkbox(panel, "hideEmpty", L.HIDE_ZERO, L.HIDE_ZERO_DESC, RX, y - 288)

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(180, 24)
    resetBtn:SetPoint("TOPLEFT", LX, y - 350)
    resetBtn:SetText(L.RESET)
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(ns.defaults) do ns.db[k] = ns.Copy(v) end
        panel:Refresh()
        Apply()
        print(PREFIX .. L.RESET_DONE)
    end)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 2, -10)
    hint:SetWidth(560)
    hint:SetJustifyH("LEFT")
    hint:SetText(L.HINT)

    function panel:Refresh()
        for _, c in ipairs(controls) do c.Refresh() end
    end
    panel:SetScript("OnShow", function(self)
        self:Refresh()
        preview:Show()
    end)
    panel:SetScript("OnHide", function() preview:Hide() end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, PANEL_NAME)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function ns.BuildOptions()
    BuildPanel()
end

function ns.RefreshOptions()
    if panel and panel:IsShown() then panel:Refresh() end
end

function ns.OpenOptions()
    if Settings and Settings.OpenToCategory and category then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and panel then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

function MirrasComboPoints_OnCompartmentClick()
    ns.OpenOptions()
end

-- Mirra's Combo Points
-- Shows your combo points on your target's nameplate (WoW: Forever).

local ADDON, ns = ...
local POWER_COMBO = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
local MAX_PIPS = 10
local FLAT = "Interface\\Buttons\\WHITE8X8"

local defaults = {
    size      = 18,
    spacing   = 3,
    offsetX   = 0,
    offsetY   = 8,
    anchor    = "TOP",
    hideEmpty = true,
    showEmpty = true,
    alpha     = 1,
    shape     = "hexagon",
    style     = "gold",
    colorMode = "gradient",
    colorStart = { r = 1,   g = 0.9,  b = 0.1 },
    colorEnd   = { r = 1,   g = 0.15, b = 0.1 },
    useFullColor = true,
    colorFull  = { r = 1,   g = 0.1,  b = 0.1 },
    colorEmpty = { r = 0,   g = 0,    b = 0, a = 0.85 },
}
ns.defaults = defaults

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = x end
    return t
end
ns.Copy = Copy

local db
local container
local lastReason = "no update yet"

local function Print(msg)
    print("|cffffcc00Mirra's Combo Points:|r " .. tostring(msg))
end

local function IsSecret(v)
    if issecretvalue then
        local ok, res = pcall(issecretvalue, v)
        return ok and res or false
    end
    return false
end

local function PipColor(i, max)
    local a, b = db.colorStart, db.colorEnd
    if db.colorMode == "single" then return a.r, a.g, a.b end
    local t = (max > 1) and (i - 1) / (max - 1) or 1
    return a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t
end

-- Pip textures live in Media/. Each texture is 64x64 with the shape in the
-- central 44x44; the margin leaves room for the glow. Every layer of a pip
-- uses the same frame, so the layers line up without per-layer insets.
local MEDIA = "Interface\\AddOns\\MirrasComboPoints\\Media\\"
local MARGIN = 10 / 44
ns.MEDIA = MEDIA

ns.SHAPES = {
    { key = "round",   name = "Round" },
    { key = "square",  name = "Square" },
    { key = "diamond", name = "Diamond" },
    { key = "hexagon", name = "Hexagon" },
    { key = "star",    name = "Star" },
    { key = "sparkle", name = "Sparkle" },
    { key = "heart",   name = "Heart" },
    { key = "shield",  name = "Shield" },
    { key = "drop",    name = "Drop" },
}

-- bg/fill name the texture variant; rim, edge, glow and shine are optional layers.
local STYLES = {
    gold   = { bg = "inner", fill = "geminner", rim = { 1, 0.82, 0.42 }, shine = true },
    silver = { bg = "inner", fill = "geminner", rim = { 0.85, 0.89, 0.96 }, shine = true },
    glow   = { bg = "mask",  fill = "gem", edge = true, glow = true, shine = true },
    flat   = { bg = "mask",  fill = "thin" },
}
ns.STYLES = {
    { key = "gold",   name = "Gold" },
    { key = "silver", name = "Silver" },
    { key = "glow",   name = "Glow" },
    { key = "flat",   name = "Flat" },
}

local function IsKnown(list, key)
    for _, e in ipairs(list) do
        if e.key == key then return true end
    end
    return false
end

local function CurrentStyle()
    local shape = IsKnown(ns.SHAPES, db.shape) and db.shape or defaults.shape
    local style = STYLES[db.style] and db.style or defaults.style
    return shape, style, STYLES[style]
end

-- Draw order, bottom to top. "gated" layers are only visible for pips that
-- are filled; the rest belong to the empty slot.
local LAYERS = {
    { key = "glow" },
    { key = "fullGlow" },
    { key = "bg" },
    { key = "edge" },
    { key = "rim" },
    { key = "fill" },
    { key = "full" },
    { key = "shine",    add = true },
}

local function NewBar(parent, level)
    local b = CreateFrame("StatusBar", nil, parent)
    b:SetStatusBarTexture(FLAT)
    b:SetMinMaxValues(0, 1)
    b:SetValue(0)
    b:SetFrameLevel(parent:GetFrameLevel() + level)
    return b
end

local function CreatePip(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.layers = {}
    for i, l in ipairs(LAYERS) do
        f.layers[l.key] = NewBar(f, i)
    end
    return f
end

local function CreateGroup(parent, name)
    local g = CreateFrame("Frame", name, parent)
    g:SetSize(1, 1)
    g.pips = {}
    for i = 1, MAX_PIPS do
        g.pips[i] = CreatePip(g)
    end
    return g
end

local function SetLayer(bar, texture, add)
    bar:SetStatusBarTexture(texture)
    local t = bar:GetStatusBarTexture()
    if t and t.SetBlendMode then t:SetBlendMode(add and "ADD" or "BLEND") end
end

-- Textures and positions only change with the settings, not with the
-- combo points, so they are applied only when this key changes.
local function LayoutKey(max)
    return table.concat({ db.shape or "", db.style or "", db.size, db.spacing, max }, ":")
end

local function LayoutPips(g, max)
    local key = LayoutKey(max)
    if g.layoutKey == key then return end
    g.layoutKey = key

    local shape, _, st = CurrentStyle()
    local size, gap = db.size, db.spacing
    local m = size * MARGIN
    g:SetSize(max * size + (max - 1) * gap, size)

    local textures = {
        glow = st.glow and "glow", fullGlow = st.glow and "glow",
        bg = st.bg, edge = st.edge and "edge", rim = st.rim and "rim",
        fill = st.fill, full = st.fill, shine = st.shine and "shine",
    }
    for i = 1, MAX_PIPS do
        local p = g.pips[i]
        p:ClearAllPoints()
        if i <= max then
            p:SetSize(size, size)
            p:SetPoint("LEFT", g, "LEFT", (i - 1) * (size + gap), 0)
            for _, l in ipairs(LAYERS) do
                local bar, variant = p.layers[l.key], textures[l.key]
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", p, "TOPLEFT", -m, m)
                bar:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", m, -m)
                if variant then
                    SetLayer(bar, MEDIA .. shape .. "_" .. variant, l.add)
                end
                bar.used = variant and true or false
            end
            p:Show()
        else
            p:Hide()
        end
    end
end

-- A filled layer shows for pip i once cur >= i. Using the StatusBar's own
-- min/max keeps this working when cur is a protected (secret) value.
local function Gate(bar, i, cur)
    bar:SetMinMaxValues(i - 1, i)
    bar:SetValue(cur)
end

-- Empty-slot layers: always visible (or tied to the first point when
-- hiding at 0), or only under filled pips when empty slots are off.
local function Slot(bar, i, cur)
    if db.showEmpty then
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(db.hideEmpty and cur or 1)
    else
        Gate(bar, i, cur)
    end
end

local function PaintGroup(g, cur, max)
    LayoutPips(g, max)
    local _, _, st = CurrentStyle()
    local fc, e = db.colorFull, db.colorEmpty
    local full = db.useFullColor
    for i = 1, max do
        local L = g.pips[i].layers
        local r, gr, b = PipColor(i, max)

        Slot(L.bg, i, cur)
        L.bg:SetStatusBarColor(e.r, e.g, e.b, e.a or 0.85)
        L.bg:SetShown(L.bg.used and db.showEmpty)

        Slot(L.edge, i, cur)
        L.edge:SetStatusBarColor(r * 0.8, gr * 0.8, b * 0.8, 0.9)
        L.edge:SetShown(L.edge.used and db.showEmpty)

        Slot(L.rim, i, cur)
        if st.rim then L.rim:SetStatusBarColor(st.rim[1], st.rim[2], st.rim[3], 1) end
        L.rim:SetShown(L.rim.used)

        Gate(L.glow, i, cur)
        L.glow:SetStatusBarColor(r, gr, b, 0.75)
        L.glow:SetShown(L.glow.used)

        Gate(L.fill, i, cur)
        L.fill:SetStatusBarColor(r, gr, b, 1)
        L.fill:SetShown(L.fill.used)

        -- The "full" layers only light up when the last pip is filled.
        L.full:SetMinMaxValues(max - 1, max)
        L.full:SetValue(cur)
        L.full:SetStatusBarColor(fc.r, fc.g, fc.b, 1)
        L.full:SetShown(L.full.used and full)

        L.fullGlow:SetMinMaxValues(max - 1, max)
        L.fullGlow:SetValue(cur)
        L.fullGlow:SetStatusBarColor(fc.r, fc.g, fc.b, 0.75)
        L.fullGlow:SetShown(L.fullGlow.used and full)

        Gate(L.shine, i, cur)
        L.shine:SetStatusBarColor(1, 1, 1, 1)
        L.shine:SetShown(L.shine.used)
    end
    g:SetAlpha(db.alpha or 1)
end

local function BuildFrames()
    container = CreateGroup(UIParent, "MirrasComboPointsFrame")
    container:SetFrameStrata("HIGH")
    container:Hide()
end

local function GetCombo()
    local cur
    if GetComboPoints then
        local ok, c = pcall(GetComboPoints, "player", "target")
        if ok then cur = c end
    end
    local max = UnitPowerMax and UnitPowerMax("player", POWER_COMBO)
    if max == nil or IsSecret(max) or max <= 0 then max = MAX_COMBO_POINTS or 5 end
    max = math.min(max, MAX_PIPS)
    return cur or 0, max, "GetComboPoints"
end

local function GetAnchorFrame(plate)
    local uf = plate.UnitFrame
    if uf then
        local hb = uf.healthBar or uf.HealthBar
            or (uf.HealthBarsContainer and (uf.HealthBarsContainer.healthBar or uf.HealthBarsContainer))
        if hb then return hb, "healthBar" end
        return uf, "UnitFrame"
    end
    return plate, "plate"
end

local function Hide(reason)
    lastReason = reason
    container:Hide()
end

local function Render(anchor, plate, cur, max)
    container:ClearAllPoints()
    local ok = pcall(function()
        if db.anchor == "BOTTOM" then
            container:SetPoint("TOP", anchor, "BOTTOM", db.offsetX, -db.offsetY)
        else
            container:SetPoint("BOTTOM", anchor, "TOP", db.offsetX, db.offsetY)
        end
    end)
    if not ok and plate then
        container:ClearAllPoints()
        container:SetPoint("BOTTOM", plate, "TOP", db.offsetX, db.offsetY)
    end
    PaintGroup(container, cur, max)
    container:Show()
end

local function Update()
    if not container then return end

    if not UnitExists("target") then return Hide("no target") end

    local canAttack = UnitCanAttack("player", "target")
    if not IsSecret(canAttack) and not canAttack then return Hide("target not attackable") end

    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return Hide("target has no visible nameplate (press V?)") end

    local cur, max, src = GetCombo()
    local secret = IsSecret(cur)

    if db.hideEmpty and not secret and cur == 0 then
        return Hide("0 combo points (" .. src .. ")")
    end

    Render(GetAnchorFrame(plate), plate, cur, max)
    lastReason = "shown (" .. src .. (secret and ", protected value" or ", " .. tostring(cur) .. "/" .. max) .. ")"
end

function ns.CreatePreview(parent, anchor)
    local g = CreateGroup(parent)
    g:Hide()
    local t = 1
    g:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if t < 0.1 or not db then return end
        t = 0
        local _, max = GetCombo()
        local n = math.floor(GetTime() / 0.8) % max + 1
        self:ClearAllPoints()
        if db.anchor == "BOTTOM" then
            self:SetPoint("TOP", anchor, "BOTTOM", db.offsetX, -db.offsetY)
        else
            self:SetPoint("BOTTOM", anchor, "TOP", db.offsetX, db.offsetY)
        end
        PaintGroup(self, n, max)
    end)
    return g
end

ns.Update = Update

local ev = CreateFrame("Frame")
local function Reg(e) pcall(ev.RegisterEvent, ev, e) end
Reg("ADDON_LOADED")
Reg("PLAYER_ENTERING_WORLD")
Reg("PLAYER_TARGET_CHANGED")
Reg("NAME_PLATE_UNIT_ADDED")
Reg("NAME_PLATE_UNIT_REMOVED")
Reg("UNIT_POWER_UPDATE")
Reg("UNIT_POWER_FREQUENT")
Reg("UNIT_MAXPOWER")
Reg("UNIT_FLAGS")
Reg("UPDATE_SHAPESHIFT_FORM")
Reg("PLAYER_COMBO_POINTS")
Reg("UNIT_COMBO_POINTS")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        MirrasComboPointsDB = MirrasComboPointsDB or {}
        db = MirrasComboPointsDB
        for k, v in pairs(defaults) do
            if db[k] == nil then db[k] = Copy(v) end
        end
        db.source = nil
        db.loginMessage = nil
        ns.db = db
        BuildFrames()
        if ns.BuildOptions then ns.BuildOptions() end
        return
    end
    if not db then return end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        C_Timer.After(0, Update)
        return
    end
    Update()
end)

local elapsed = 0
ev:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed >= 0.2 then
        elapsed = 0
        if db then Update() end
    end
end)

local function Debug()
    Print("--- Diagnostics ---")
    print("  Interface:", select(4, GetBuildInfo()), " Build:", (GetBuildInfo()))
    print("  Target exists:", UnitExists("target"), " attackable:", tostring(UnitCanAttack("player", "target")))
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit("target")
    print("  Nameplate:", plate and "yes" or "NO")
    if plate then
        local _, kind = GetAnchorFrame(plate)
        print("  Anchor:", kind)
    end
    if GetComboPoints then
        local ok, c = pcall(GetComboPoints, "player", "target")
        print("  GetComboPoints:", ok and (IsSecret(c) and "<protected>" or tostring(c)) or "error")
    else
        print("  GetComboPoints: not available")
    end

    print("  Status:", lastReason)
end

SLASH_MIRRASCOMBOPOINTS1 = "/mcp"
SLASH_MIRRASCOMBOPOINTS2 = "/mirrascombopoints"
SlashCmdList.MIRRASCOMBOPOINTS = function(input)
    local cmd, val = strsplit(" ", (input or ""):lower(), 2)
    local n = tonumber(val)
    if cmd == "" or cmd == "config" or cmd == "options" then
        if ns.OpenOptions then ns.OpenOptions() end
        return
    elseif cmd == "debug" then
        Debug()
        return
    elseif cmd == "size" and n then
        db.size = math.max(4, math.min(40, n))
    elseif cmd == "spacing" and n then
        db.spacing = math.max(0, math.min(20, n))
    elseif cmd == "x" and n then
        db.offsetX = n
    elseif cmd == "y" and n then
        db.offsetY = n
    elseif cmd == "shape" or cmd == "style" then
        local list = cmd == "shape" and ns.SHAPES or ns.STYLES
        local names = {}
        for _, e in ipairs(list) do names[#names + 1] = e.key end
        if not (val and IsKnown(list, val)) then
            Print("Available " .. cmd .. "s: " .. table.concat(names, ", "))
            return
        end
        db[cmd] = val
    elseif cmd == "top" or cmd == "bottom" then
        db.anchor = cmd:upper()
    elseif cmd == "empty" then
        db.hideEmpty = not db.hideEmpty
        Print("Hide at 0 points: " .. (db.hideEmpty and "on" or "off"))
    elseif cmd == "slots" then
        db.showEmpty = not db.showEmpty
        Print("Show empty slots: " .. (db.showEmpty and "on" or "off"))
    elseif cmd == "reset" then
        for k, v in pairs(defaults) do db[k] = Copy(v) end
        Print("Settings reset.")
    elseif cmd ~= "help" then
        Print("Unknown command – /mcp help")
        return
    else
        Print("Commands:")
        print("  /mcp                  – open settings")
        print("  /mcp debug            – print diagnostics")
        print("  /mcp size <4-40>      – pip size (current " .. db.size .. ")")
        print("  /mcp spacing <0-20>   – spacing (current " .. db.spacing .. ")")
        print("  /mcp shape <name>     – pip shape (current " .. tostring(db.shape) .. ")")
        print("  /mcp style <name>     – pip style (current " .. tostring(db.style) .. ")")
        print("  /mcp x <n> | y <n>    – offset (current " .. db.offsetX .. " / " .. db.offsetY .. ")")
        print("  /mcp top | bottom     – above/below the health bar")
        print("  /mcp empty            – toggle hide at 0 points")
        print("  /mcp slots            – toggle empty slots")
        print("  /mcp reset            – restore defaults")
        return
    end
    Update()
    if ns.RefreshOptions then ns.RefreshOptions() end
end

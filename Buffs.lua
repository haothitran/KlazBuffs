local addon, ns = ...
local C = ns.C

--------------------------------------------------------------------------------
-- // BUFFS
--------------------------------------------------------------------------------

local loader = CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent', function(self, addon)
  if addon ~= KlazBuffs then
    local function initDB(db, defaults)
      if type(db) ~= 'table' then db = {} end
      if type(defaults) ~= 'table' then return db end
      for k, v in pairs(defaults) do
        if type(v) == 'table' then
          db[k] = initDB(db[k], v)
        elseif type(v) ~= type(db[k]) then
          db[k] = v
        end
      end
    return db
  end

  KlazBuffsDB = initDB(KlazBuffsDB, C.Position)
    C.UserPlaced = KlazBuffsDB
    self:UnregisterEvent('ADDON_LOADED')
  end
end)

--------------------------------------------------------------------------------
-- // ANCHOR FRAME
--------------------------------------------------------------------------------

local anchor = CreateFrame('Frame', 'KlazBuffsAnchor', UIParent)
anchor:SetSize(C.Size.Width, C.Size.Height)
if not anchor.SetBackdrop then Mixin(anchor, BackdropTemplateMixin) end
anchor:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background"})
anchor:SetFrameStrata('HIGH')
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:EnableMouse(true)
anchor:SetUserPlaced(true)
anchor:RegisterForDrag('LeftButton')
anchor:RegisterEvent('PLAYER_LOGIN')
anchor:Hide()

anchor.text = anchor:CreateFontString(nil, 'OVERLAY')
anchor.text:SetAllPoints(anchor)
anchor.text:SetFont(C.Font.Family, C.Font.Size, C.Font.Style)
anchor.text:SetShadowOffset(0, 0)
anchor.text:SetText('KlazBuffsAnchor')

anchor:SetScript('OnEvent', function(self, event, arg1)
  if event == 'PLAYER_LOGIN' then
    self:ClearAllPoints()
    self:SetPoint(
    C.UserPlaced.Point,
    C.UserPlaced.RelativeTo,
    C.UserPlaced.RelativePoint,
    C.UserPlaced.XOffset,
    C.UserPlaced.YOffset)
  end
end)

anchor:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)

anchor:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)

  point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1)
    if relativeTo then
      relativeTo = relativeTo:GetName();
    else
      relativeTo = self:GetParent():GetName();
    end

  C.UserPlaced.Point = point
  C.UserPlaced.RelativeTo = relativeTo
  C.UserPlaced.RelativePoint = relativePoint
  C.UserPlaced.XOffset = xOffset
  C.UserPlaced.YOffset = yOffset
end)

local SetPoint = anchor.SetPoint
local ClearAllPoints = anchor.ClearAllPoints
ClearAllPoints(BuffFrame)
SetPoint(BuffFrame, "TOPRIGHT", anchor, "TOPRIGHT")
hooksecurefunc(BuffFrame, "SetPoint", function(frame)
	ClearAllPoints(frame)
	SetPoint(frame, "TOPRIGHT", anchor, "TOPRIGHT")
end)

--------------------------------------------------------------------------------
-- // MASQUE SUPPORT
--------------------------------------------------------------------------------

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
if not LMB then return end

local f = CreateFrame("Frame")

local Buffs = LMB:Group("KlazBuffs", "Buffs")
local Debuffs = LMB:Group("KlazBuffs", "Debuffs")
local TempEnchant = LMB:Group("KlazBuffs", "TempEnchant")

local function OnEvent(self, event, addon)
	for i=1, BUFF_MAX_DISPLAY do
		local buff = _G["BuffButton"..i]
		if buff then
			Buffs:AddButton(buff)
		end
		if not buff then break end
	end

	for i=1, BUFF_MAX_DISPLAY do
		local debuff = _G["DebuffButton"..i]
		if debuff then
			Debuffs:AddButton(debuff)
		end
		if not debuff then break end
	end

	for i=1, NUM_TEMP_ENCHANT_FRAMES do
		local f = _G["TempEnchant"..i]
		if TempEnchant then
			TempEnchant:AddButton(f)
		end
		_G["TempEnchant"..i.."Border"]:SetVertexColor(.75, 0, 1)
	end

	f:SetScript("OnEvent", nil)
end

-- do not need this for TempEnchant frames
-- because they are hard created in XML
hooksecurefunc("CreateFrame", function (_, name, parent)
  if parent ~= BuffFrame or type(name) ~= "string" then return end
  -- prevent issues with stack text appearing under frame
	if strfind(name, "^DebuffButton%d+$") then
		Debuffs:AddButton(_G[name])
		Debuffs:ReSkin()
	elseif strfind(name, "^BuffButton%d+$") then
		Buffs:AddButton(_G[name])
		Buffs:ReSkin()
	end
end
)

f:SetScript("OnEvent", OnEvent)
f:RegisterEvent("PLAYER_ENTERING_WORLD")

--------------------------------------------------------------------------------
-- // SLASH COMMAND
--------------------------------------------------------------------------------

SlashCmdList.KLAZBUFFS = function (msg, editbox)
  if string.lower(msg) == 'reset' then
    KlazBuffsDB = C.Position
    ReloadUI()
  elseif string.lower(msg) == 'unlock' then
    if not anchor:IsShown() then
      anchor:Show()
      print('|cff1994ffKlazBuffs|r |cff00ff00Unlocked.|r')
    end
  elseif string.lower(msg) == 'lock' then
    anchor:Hide()
    print('|cff1994ffKlazBuffs|r |cffff0000Locked.|r')
  else
    print('------------------------------------------')
    print('|cff1994ffKlazBuffs commands:|r')
    print('------------------------------------------')
    print('|cff1994ff/klazbuffs unlock|r Unlocks frame to be moved.')
    print('|cff1994ff/klazbuffs lock|r Locks frame in position.')
    print('|cff1994ff/klazbuffs reset|r Resets frame to default position.')
  end
end
SLASH_KLAZBUFFS1 = '/klazbuffs'
SLASH_KLAZBUFFS2 = '/kbuffs'

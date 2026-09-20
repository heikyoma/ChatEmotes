ChatEmotes = ChatEmotes or {}

local ADDON_NAME = "ChatEmotes"
local PREFIX = "|cB66CFF[ChatEmotes]|r "

ChatEmotes.defaultSize = 32
ChatEmotes._ourFormatters = ChatEmotes._ourFormatters or {}

local function EscapeLuaPattern(text)
    return (text:gsub("(%W)", "%%%1"))
end

local function MakeTextureTag(data)
    if type(data) == "string" then
        return string.format(
            "|t%d:%d:%s|t",
            ChatEmotes.defaultSize,
            ChatEmotes.defaultSize,
            data
        )
    end

    if type(data) ~= "table" or not data.texture then
        return nil
    end

    local width = tonumber(data.width) or ChatEmotes.defaultSize
    local height = tonumber(data.height) or ChatEmotes.defaultSize

    return string.format("|t%d:%d:%s|t", width, height, data.texture)
end

function ChatEmotes.Replace(text)
    if type(text) ~= "string" or text == "" then
        return text
    end

    if type(ChatEmotes_Emotes) ~= "table" then
        return text
    end

    local result = text

    for code, data in pairs(ChatEmotes_Emotes) do
        if type(code) == "string" and code ~= "" then
            local textureTag = MakeTextureTag(data)

            if textureTag then
                result = result:gsub(EscapeLuaPattern(code), textureTag)
            end
        end
    end

    return result
end

function ChatEmotes.HookChatFormatter()
    if not CHAT_ROUTER or not CHAT_ROUTER.GetRegisteredMessageFormatters then
        return
    end

    local formatters = CHAT_ROUTER:GetRegisteredMessageFormatters()
    if not formatters then
        return
    end

    local previousFormatter = formatters[EVENT_CHAT_MESSAGE_CHANNEL]
    if type(previousFormatter) ~= "function" then
        return
    end

    -- Уже стоит наша последняя обёртка.
    if ChatEmotes._ourFormatters[previousFormatter] then
        return
    end

    -- ВАЖНО:
    -- previousFormatter захватывается именно как local для этой конкретной
    -- обёртки. Поэтому повторный hook после /reloadui или смены зоны не
    -- создаёт рекурсию.
    local wrapper

    wrapper = function(channelType, fromName, text, isCustomerService, fromDisplayName, ...)
        -- ВАЖНО:
        -- Подменяем :код: на DDS ДО вызова pChat/vanilla formatter.
        -- pChat умеет отдельно распознавать |t...|t и не заворачивает DDS
        -- внутрь своих |H...|h ссылок для копирования.
        local displayText = ChatEmotes.Replace(text)

        local formattedText,
              saveTarget,
              returnedDisplayName,
              originalText,
              formattedNarrationText =
            previousFormatter(
                channelType,
                fromName,
                displayText,
                isCustomerService,
                fromDisplayName,
                ...
            )

        -- Наружу возвращаем исходный текст сообщения как originalText,
        -- чтобы сам сетевой текст по-прежнему оставался :код:.
        return formattedText,
               saveTarget,
               returnedDisplayName,
               text,
               formattedNarrationText
    end

    ChatEmotes._ourFormatters[wrapper] = true
    CHAT_ROUTER:RegisterMessageFormatter(EVENT_CHAT_MESSAGE_CHANNEL, wrapper)
end

local function CountEmotes()
    local count = 0

    if type(ChatEmotes_Emotes) == "table" then
        for _ in pairs(ChatEmotes_Emotes) do
            count = count + 1
        end
    end

    return count
end

local function OnPlayerActivated()
    -- pChat тоже регистрирует formatter на EVENT_PLAYER_ACTIVATED.
    -- Небольшая задержка позволяет нам обернуть уже установленный formatter,
    -- а не перетереть его.
    zo_callLater(function()
        ChatEmotes.HookChatFormatter()
    end, 250)
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    SLASH_COMMANDS["/chatemotes"] = function(args)
        local command = zo_strlower((args or ""):match("^%s*(.-)%s*$"))

        if command == "rehook" then
            ChatEmotes.HookChatFormatter()
            d(PREFIX .. "formatter подключён заново.")
            return
        end

        d(PREFIX .. string.format(
            "загружено смайликов: %d. Команда: /chatemotes rehook",
            CountEmotes()
        ))
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

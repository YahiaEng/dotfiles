-- Vampire Survivors maps a held left button and pointer motion to movement.
-- Forward a click on release so menus still work without steering on drags.
local leftButton = "mouse:272"
local clickRadius = 8
local pendingClick

local function focusedGameAtPointer()
    local window = hl.get_active_window()
    if not window or window.class ~= "VampireSurvivors.exe" then
        return
    end

    local pointer = hl.get_cursor_pos()
    local pos, size = window.at, window.size
    if pointer and pointer.x >= pos.x and pointer.x < pos.x + size.x
        and pointer.y >= pos.y and pointer.y < pos.y + size.y then
        return window, pointer
    end
end

hl.bind(leftButton, function()
    local window, pointer = focusedGameAtPointer()
    if pendingClick then
        local press = pendingClick
        pendingClick = nil
        if window and window.address == press.window then
            local dx, dy = pointer.x - press.x, pointer.y - press.y
            if dx * dx + dy * dy <= clickRadius * clickRadius then
                hl.dispatch(hl.dsp.send_key_state({ mods = "", key = leftButton, state = "down" }))
                hl.dispatch(hl.dsp.send_key_state({ mods = "", key = leftButton, state = "up" }))
            end
        end
        return
    end

    if not window then
        return { pass_event = true }
    end
    pendingClick = { window = window.address, x = pointer.x, y = pointer.y }
    return { request_release = true }
end)

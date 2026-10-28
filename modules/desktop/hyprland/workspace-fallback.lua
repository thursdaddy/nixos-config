local reconciling = false

local function resolve_target_monitor(home_monitor)
  if hl.get_monitor(home_monitor) ~= nil then
    return home_monitor
  end
  for _, candidate in ipairs(monitor_fallbacks[home_monitor] or {}) do
    if hl.get_monitor(candidate) ~= nil then
      return candidate
    end
  end
  return home_monitor
end

local function apply_rules_and_collect_moves()
  local target_by_ws_id = {}
  local pending_moves = {}

  for _, base_rule in ipairs(base_workspace_rules) do
    local target = resolve_target_monitor(base_rule.monitor)
    local updated_rule = {}
    for k, v in pairs(base_rule) do
      updated_rule[k] = v
    end
    updated_rule.monitor = target
    hl.workspace_rule(updated_rule)

    local ws_id = tonumber(base_rule.workspace)
    if ws_id ~= nil then
      target_by_ws_id[ws_id] = target
      if hl.get_monitor(target) ~= nil then
        local ws = hl.get_workspace(ws_id)
        if ws ~= nil and (ws.monitor == nil or ws.monitor.name ~= target) then
          table.insert(pending_moves, { ws_id = ws_id, target = target })
        end
      end
    end
  end

  return target_by_ws_id, pending_moves
end

local function relocate_silently(target_by_ws_id, pending_moves)
  -- Moving a workspace that was active on a disconnected output can displace the
  -- destination monitor's visible workspace or steal focus from fullscreen apps.
  local active_mon = hl.get_active_monitor()
  local active_mon_name = active_mon and active_mon.name or nil
  local active_win = hl.get_active_window()
  local active_win_addr = active_win and active_win.address or nil

  local saved_visible_ws = {}
  for _, mon in ipairs(hl.get_monitors()) do
    local active_ws = mon.active_workspace
    if active_ws ~= nil and target_by_ws_id[active_ws.id] == mon.name then
      saved_visible_ws[mon.name] = active_ws.id
    end
  end

  for _, move in ipairs(pending_moves) do
    hl.dispatch(hl.dsp.workspace.move({
      workspace = move.ws_id,
      monitor = move.target,
    }))
  end

  for mon_name, expected_ws_id in pairs(saved_visible_ws) do
    local mon = hl.get_monitor(mon_name)
    if mon ~= nil and (mon.active_workspace == nil or mon.active_workspace.id ~= expected_ws_id) then
      local expected_ws = hl.get_workspace(expected_ws_id)
      if expected_ws ~= nil and expected_ws.monitor ~= nil and expected_ws.monitor.name == mon_name then
        hl.dispatch(hl.dsp.focus({ workspace = expected_ws_id }))
      end
    end
  end

  if active_mon_name ~= nil and hl.get_monitor(active_mon_name) ~= nil then
    local cur_mon = hl.get_active_monitor()
    if cur_mon == nil or cur_mon.name ~= active_mon_name then
      hl.dispatch(hl.dsp.focus({ monitor = active_mon_name }))
    end
  end

  if active_win_addr ~= nil then
    for _, win in ipairs(hl.get_windows()) do
      if win.address == active_win_addr and win.workspace ~= nil and win.workspace.visible then
        local cur_win = hl.get_active_window()
        if cur_win == nil or cur_win.address ~= active_win_addr then
          hl.dispatch(hl.dsp.focus({ window = win }))
        end
        break
      end
    end
  end
end

local function reconcile_workspaces()
  if reconciling then
    return
  end
  reconciling = true
  local ok, err = pcall(function()
    local target_by_ws_id, pending_moves = apply_rules_and_collect_moves()
    if #pending_moves > 0 then
      relocate_silently(target_by_ws_id, pending_moves)
    end
  end)
  reconciling = false
  if not ok then
    error(err)
  end
end

reconcile_workspaces()

hl.on("hyprland.start", reconcile_workspaces)
hl.on("config.reloaded", reconcile_workspaces)
hl.on("monitor.added", reconcile_workspaces)
hl.on("monitor.layout_changed", reconcile_workspaces)
-- CMonitor::onDisconnect emits monitor.removed before scheduleRecheck() runs on the next tick.
hl.on("monitor.removed", function()
  hl.timer(reconcile_workspaces, { timeout = 50, type = "oneshot" })
end)

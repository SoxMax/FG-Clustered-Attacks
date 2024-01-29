local notifyApplyDamage
local applyModifierKeysToModRoll

local function isClusteredDamage(sDesc)
    return sDesc:find("[CLUSTERED]", 1, true)
end

local clusteredDamage = {}

function notifyApplyDamageIntercept(rSource, rTarget, bSecret, sRollType, sDesc, nTotal, ...)
    if isClusteredDamage(sDesc) and sRollType == "damage" then
        target = ""
        if rTarget then
            target = rTarget.sCreatureNode
        end
        local sourceTargets = clusteredDamage[rSource.sCreatureNode] or {}
        local targetDamage = sourceTargets[target] or {}
        table.insert(targetDamage,
            {
                rSource = rSource,
                rTarget = rTarget,
                bSecret = bSecret,
                sRollType = sRollType,
                sDesc = sDesc:gsub(" %[CLUSTERED%]", ""),
                nTotal = nTotal,
                extraArgs = { ... }
            }
        )
        sourceTargets[target] = targetDamage
        clusteredDamage[rSource.sCreatureNode] = sourceTargets
    else
        notifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal, ...)
    end
end

function notifyApplyClusteredDamage()
    for _, targetDamages in pairs(clusteredDamage) do
        for _, damageInstances in pairs(targetDamages) do
            local rSource = nil
            local rTarget = nil
            local bSecret = nil
            local sRollType = "damage"
            local sDesc = ""
            local nTotal = 0
            local extraArgs = {}
            for _, damageInstance in ipairs(damageInstances) do
                rSource = damageInstance.rSource
                rTarget = damageInstance.rTarget
                bSecret = damageInstance.bSecret
                sDesc = sDesc .. " " .. damageInstance.sDesc
                nTotal = nTotal + damageInstance.nTotal
                extraArgs = damageInstance.extraArgs
            end
            notifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal, unpack(extraArgs))
        end
    end
    clusteredDamage = {}
end

function applyModifierKeysToModRollIntercept(rRoll, rSource, rTarget)
    applyModifierKeysToModRoll(rRoll, rSource, rTarget)
    if ModifierManager.getKey("DMG_CLUSTERED") then
		table.insert(rRoll.tNotifications, "[CLUSTERED]");
	end
end

function onDamageClusteredModifier(key)
    if ModifierManager.getRawKey(key) then
        ModifierManager.lock()
    else
        ModifierManager.unlock()
        notifyApplyClusteredDamage()
    end
end

function clusterDamage(sCommand, sParams)
    Interface.openWindow("cluster_attacks", "")
end

function onInit()
    notifyApplyDamage = ActionDamage.notifyApplyDamage
    ActionDamage.notifyApplyDamage = notifyApplyDamageIntercept

    applyModifierKeysToModRoll = ActionDamage.applyModifierKeysToModRoll
    ActionDamage.applyModifierKeysToModRoll = applyModifierKeysToModRollIntercept

    ModifierManager.addModWindowPresetButton("damage", "DMG_CLUSTERED")
    ModifierManager.registerKeyCallback("DMG_CLUSTERED", onDamageClusteredModifier)

    -- Comm.registerSlashHandler("clusterdamage", clusterDamage)
    -- Comm.registerSlashHandler("clusterattacks", clusterDamage)
end

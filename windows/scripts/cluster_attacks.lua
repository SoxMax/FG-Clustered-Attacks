local damageTarget

function addDamageInstance(draginfo)
    Debug.chat(draginfo)
    CombatDropManager.handleAnyDrop(draginfo, damageTarget.getPath())
end

function onDrop(x, y, dragdata)
    if dragdata.getType() == "damage" then
        addDamageInstance(dragdata)
        return true
    end
end

function onFirstLayout()
    for _,nodeCT in pairs(CombatManager.getAllCombatantNodes()) do
        damageTarget = nodeCT
    end
    target.setValue(damageTarget.getPath())
end

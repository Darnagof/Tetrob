function Local.Init(pos, color)
    Object.pos = pos
    color = color or obe.Color(255, 255, 255)
    This:LevelSprite():setPosition(obe.UnitVector(pos.x, pos.y, obe.Units.ScenePixels))
    This:LevelSprite():setColor(color)
end

-- function Local.Init(pos, color)
--  ...

function Object:getPosition()
    return This:LevelSprite():getPosition()
end

function Object:setPosition(pos)
    This:LevelSprite():setPosition(pos)
end

function Object:isVisible()
    return This:LevelSprite():isVisible()
end

function Object:show(visible)
    This:LevelSprite():setVisible(visible)
end

function Object:deleteObject()
    This:delete()
end
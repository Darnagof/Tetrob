function Local.Init()
    Scene:loadFromFile("Tetrob.map.vili", function()
        Scene:getGameObject("board"):setState("falling_state")
        --Scene:getGameObject("board"):setState("stop")
    end)

    score = 0;
    canvas = obe.Canvas.Canvas(obe.Screen.Width, obe.Screen.Height);
    canvas:setTarget(This:LevelSprite());
    cvScore = canvas:Text("score")({
        x = obe.Screen.Width / 10, y = 0,
        text = "0", size = 72,
        font = "Data/Fonts/arial.ttf",
        layer = 0
    });

    canvas:render();
end

function Global.Game.Render()
    canvas:render();
end

-- Update player score, depending of number of completed lines
-- 1 line: +50, 2: +200, 3: +450, 4: +800
-- n lines = +50*nbLines²
function Object.Scored(self, nbLines)
    score = score + 50*(nbLines^2)
    cvScore.text = score;
    canvas:render();
end
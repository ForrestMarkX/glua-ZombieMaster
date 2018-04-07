local mapTrapSettings = {}
local slots = {}
local traps = {    {1237, 1246, 1320, 1338, 1354, 1370, 1388, 1436}, 
                {1238, 1247, 1321, 1339, 1355, 1371, 1389, 1437},
                {1239, 1248, 1322, 1340, 1356, 1372, 1390, 1438},
                {1240, 1249, 1323, 1341, 1357, 1373, 1391, 1439},
                {1241, 1250, 1324, 1342, 1358, 1374, 1392, 1440, 1404, 1456, 1881},
                {1242, 1251, 1325, 1343, 1359, 1375, 1393, 1441},
                {1243, 1252, 1326, 1344, 1358, 1376, 1394, 1442},
                {1244, 1253, 1327, 1345, 1359, 1377, 1395, 1443},
                {1245, 1254, 1328, 1345, 1360, 1378, 1395, 1444}
            }
local firstCal, secondCal = -1024, -557
-- Create triggers
for i=1, #traps do -- Each slot
    slots[i] = {Vector(836, firstCal, -3300), Vector(1066, secondCal, 3013)} -- Box
    firstCal = firstCal + 200 -- Size of trigger
    secondCal = secondCal + 250 -- Size of trigger
end
-- Put which trap belongs on what trigger
for i=1, #slots do -- Each slot
    for o=1, #traps[i] do -- Each trap in the slot
        table.insert( mapTrapSettings, { -- Add it again
                trapName = "Trap Trigger",
                creationID = traps[i][o],
                usageChance = nil,
                usageRadius = nil,
                positions = slots[i],
                lineOfSight = true
            })
    end 
end

return nil, mapTrapSettings, nil
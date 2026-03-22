scriptName = (Config and Config.ScriptName and Config.ScriptName ~= '' and Config.ScriptName) or GetCurrentResourceName()
Config = {
    ["Router"] = "esx:getSharedObject",
    ["Font"] = "font4thai",
    ["ScriptName"] = scriptName,
    ["ExportResources"] = Config.ExportResources or {},
    ["Items"] = {
        enabled = true,
        surgery = {
            name = "surgery_ticket",
            menu = "SURGERY",
            consume = false,
        }
    },

    ["Notify"] = function (text,type)
        local notifyResource = Config.ExportResources and Config.ExportResources.notify
        if notifyResource and notifyResource ~= '' and GetResourceState(notifyResource) == 'started' then
            exports[notifyResource]:AddNotify({
                type = type,
                text = text,
            })
        end
    end,

    ["Admin"] = {
        ["steam:11000015702cfcc"] = true,
    },

    ["CameraPos"] = {
        ["default"] = {
            x = 0.0,
            y = 6.0,
            z = 0.0,
            height = -0.1,
            fov = 20.0,
        },
        ["head"] = {
            x = 0.0,
            y = 2.0,
            z = 0.65,
            height = 0.65,
            fov = 15.0,
        },
        ["body"] = {
            x = 0.0,
            y = 5.0,
            z = 0.3,
            height = 0.3,
            fov = 10.0,
        },
        ["lowbody"] = {
            x = 0.0,
            y = 5.0,
            z = 0.0,
            height = 0.0,
            fov = 12.0,
        },
        ["legs"] = {
            x = 0.0,
            y = 5.0,
            z = -0.7,
            height = -0.6,
            fov = 13.0,
        },
    },

    ["SkinPosition"] = {
        ["default"] = {
            Header = {
                Main = "SKIN MENU",
                Control = "SKIN MENU PANEL",
            },
            Position = {

            },
            CustumeType = "SURGERY",
            Price = {
                AddFavorite = false,
                BuyPrice = 0,
            },
        },
        ["Clothes"] = {
            Header = {
                Main = "CLOTHES SHOP",
                Control = "CLOTHES PANEL",
            },
            Position = {
                {coords = vector3(71.286262512207, -1399.1505126953, 29.376111984253), size = 4, heading = 268.78, blip = true},
                {coords = vector3(-708.48754882812, -160.65924072266, 37.415145874023), size = 4, heading = 23.64, blip = true},
                {coords = vector3(-158.58013916016, -297.23098754883, 39.733341217041), size = 4, heading = 152.02, blip = true},
                {coords = vector3(430.06640625, -800.08081054688, 29.491117477417), size = 4, heading = 89.63, blip = true},
                {coords = vector3(-829.71264648438, -1072.9431152344, 11.328103065491), size = 4, heading = 206.68, blip = true},
                {coords = vector3(-1457.3850097656, -241.29544067383, 49.805347442627), size = 4, heading = 314.59, blip = true},
                {coords = vector3(11.720878601074, 6514.0454101562, 31.877836227417), size = 4, heading = 41.13, blip = true},
                {coords = vector3(123.74843597412, -219.61694335938, 54.557815551758), size = 4, heading = 330.87, blip = true},
                {coords = vector3(1697.5361328125, 4829.5234375, 42.063083648682), size = 4, heading = 94.6, blip = true},
                {coords = vector3(617.8330078125, 2759.5085449219, 42.088062286377), size = 4, heading = 177.59, blip = true},
                {coords = vector3(1190.3264160156, 2714.9504394531, 38.222606658936), size = 4, heading = 178.32, blip = true},
                {coords = vector3(-1193.2591552734, -772.12017822266, 17.32442855835), size = 4, heading = 120.7, blip = true},
                {coords = vector3(-3172.5234375, 1048.0648193359, 20.863204956055), size = 4, heading = 328.68, blip = true},
                {coords = vector3(-1109.0693359375, 2709.8752441406, 19.107852935791), size = 4, heading = 218.2, blip = true},
            },
            Key = "E",
            Text = "ร้านเสื้อผ้า",
            Blip = {
                enabled = true,
                sprite = 73,
                color = 0,
                scale = 0.8,
                text = '<font face="font4thai">[ ร้าน ] เสื้อผ้า</font>'
            },
            Marker = {
                show = 20.0,
                type = 23,
                size = {x = 5.0, y = 5.0, z = 5.0},
                colors = {r = 0, g = 178, b = 255, a = 100}, --  color = { r = 0, g = 178, b = 255 },
                hight = -0.95,
            },
            CustumeType = "ClothShop",
            Price = {
                AddFavorite = 3000, -- เซฟชุด 3000
                BuyPrice = 1000, -- ซื้อชุด 1000
            },
        },
        ["Barber"] = {
            Header = {
                Main = "BARBER SHOP",
                Control = "BARBER PANEL",
            },
            Position = {
                {coords = vector3(-813.66650390625, -183.64619445801, 37.568885803223), size = 1.0, heading = 120.71, blip = true},
                {coords = vector3(137.7103729248, -1707.0092773438, 29.291603088379), size = 1.0, heading = 139.26, blip = true},
                {coords = vector3(-1281.2967529297, -1117.0653076172, 6.9901103973389), size = 1.0, heading = 86.26, blip = true},
                {coords = vector3(1930.9429931641, 3732.0727539062, 32.844417572021), size = 1.0, heading = 205.86, blip = true},
                {coords = vector3(1214.6204833984, -473.55163574219, 66.207977294922), size = 1.0, heading = 71.9, blip = true},
                {coords = vector3(-33.563232421875, -154.58755493164, 57.076469421387), size = 1.0, heading = 341.31, blip = true},
                {coords = vector3(-276.37316894531, 6226.607421875, 31.695514678955), size = 1.0, heading = 49.89, blip = true},

                -- {coords = vector3(326.0998, -601.3358, 43.3368), size = 1.0, heading = 256.2957, blip = true}, -- หมอ โรงพยาบาลทางออกนอกเมือง
                {coords = vector3(1125.4856, -1574.4976, 35.3792), size = 1.0, heading = 270.0841, blip = false}, -- หมอ โรงพยาบาลในเมือง
                {coords = vector3(424.1852, -975.9402, 32.1480), size = 1.0, heading = 271.8633, blip = false}, -- ตำรวจ 451.8878, -991.9243, 30.6896, 354.5542
                {coords = vector3(-426.0433, 1081.5277, 334.2428), size = 1.0, heading = 351.3931, blip = false}, -- สภา -423.0725, 1043.0106, 329.3558, 73.2842
            },
            Key = "E",
            Text = "ร้านตัดผม",
            Blip = {
                enabled = true,
                sprite = 71,
                color = 0,
                scale = 0.8,
                text = '<font face="font4thai">[ ร้าน ] ตัดผม</font>'
            },
            Marker = {
                show = 20.0,
                type = 23,
                size = {x = 2.0, y = 2.0, z = 2.0},
                colors = {r = 0, g = 178, b = 255, a = 100},
                hight = -0.95,
            },
            CustumeType = "Barber",
            Price = {
                AddFavorite = false,
                BuyPrice = 1000, -- 1000
            },
        },
        ["SURGERY"] = {
            Header = {
                Main = "SURGERY SHOP",
                Control = "SURGERY PANEL",
            },
            Position = {
                -- {coords = vector3(4379.3257, 1803.1855, 575.9810), size = 400.0, heading = 178.0},
                -- {coords = vector3(-3173.4448242188, -3310.142578125, 630.87091064453), size = 5.0, heading = 269.0},
                -- {coords = vector3(-3153.822265625, -3328.501953125, 630.87017822266), size = 5.0, heading = 0.0},
                -- {coords = vector3(-3132.8464355469, -3309.8449707031, 630.87005615234), size = 5.0, heading = 90.0},
            },
            Key = "E",
            Text = "ศัลยกรรม",
            Blip = {
                enabled = true,
                sprite = 304,
                color = 0,
                scale = 0.8,
                text = '<font face="ThaiFont">SURGERY</font>'
            },
            Marker = {
                show = 20.0,
                type = 23,
                size = {x = 2.0, y = 2.0, z = 2.0},
                colors = {r = 0, g = 178, b = 255, a = 100},
                hight = -0.95,
            },
            CustumeType = "default",
            Price = {
                AddFavorite = false,
                BuyPrice = 0,
            },
        },
        ["Mask"] = {
            Header = {
                Main = "MASK SHOP",
                Control = "MASK PANEL",
            },
            Position = {
                {coords = vector3(-1338.1101074219, -1277.3967285156, 4.8831286430359), size = 1.0, heading = 66.61, blip = true},
            },
            Key = "E",
            Text = "ร้านหน้ากาก",
            Blip = {
                enabled = true,
                sprite = 362,
                color = 0,
                scale = 0.8,
                text = '<font face="font4thai">[ ร้าน ] หน้ากาก</font>'
            },
            Marker = {
                show = 20.0,
                type = 23,
                size = {x = 2.0, y = 2.0, z = 2.0},
                colors = {r = 0, g = 178, b = 255, a = 100},
                hight = -0.95,
            },
            CustumeType = "Mask",
            Price = {
                AddFavorite = false,
                BuyPrice = 3000, -- 3000
            },
            Accessories = {
                label = "mask_1",
                skin = {
                    ["mask_1"] = true,
                    ["mask_2"] = true,
                },
                anime = {
                    dict = "veh@bicycle@roadfront@base",
                    anime = "put_on_helmet",
                },
                default = {
                    ["mask_1"] = 0,
                },
            },
        },
    },

    ["FavoritePosition"] = {
        Position = {
            -- {coords = vector3(332.3942, -576.3573, 48.2708), size = 1.0, heading = 69.8506},
            -- {coords = vector3(453.2049, -996.4148, 31.7140), size = 1.0, heading = 265.6199},
            -- {coords = vector3(-404.7271, 1029.8615, 336.5996), size = 1.0, heading = 74.5242},
        },
        Header = "MY FAVORITE",
        Key = "E",
        Text = "ตู้เก็บเสื้อผ้า",
        Blip = {
            enabled = false,
            sprite = 362,
            color = 0,
            scale = 0.8,
            text = '<font face="ThaiFont">ตู้เก็บเสื้อผ้า</font>'
        },
        Marker = {
            show = 20.0,
            type = 23,
            size = {x = 2.0, y = 2.0, z = 2.0},
            colors = {r = 0, g = 178, b = 255, a = 100},
            hight = -0.95,
        },
        Price = {
            AddFavorite = 1,
            BuyPrice = 0,
        },
    },
}

$(function () {

    let isLeftMouseDragging = false
    let isRightMouseDragging = false
    let lastMouseX = 0
    let rotationValue = 0
    const sliderPreviewDelayMs = 60
    const pendingSkinPreviewUpdates = {}

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    var sound1 = new Audio('sound/sound1.mp3');
    sound1.volume = 0.1;

    var sound2 = new Audio('sound/sound2.mp3');
    sound2.volume = 0.1;

    var sound3 = new Audio('sound/sound3.mp3');
    sound3.volume = 0.1;

    var sound4 = new Audio('sound/sound4.mp3');
    sound4.volume = 0.1;

    var soundloading = new Audio('sound/loading.mp3');
    soundloading.volume = 0.5;

    function restartSound(audio) {
        audio.currentTime = 0;
        const playPromise = audio.play();

        if (playPromise && typeof playPromise.catch === 'function') {
            playPromise.catch(() => {});
        }
    }

    function PlaySound(sound) {
        if (sound == 1) {
            restartSound(sound1);
        }
        if (sound == 2) {
            restartSound(sound2);
        }
        if (sound == 3) {
            restartSound(sound3);
        }
        if (sound == 4) {
            restartSound(sound4);
        }
    }

    let select_skin = null
    let activeCategory = 'all'

    function getAvailableCategories() {
        const categories = []
        const seen = new Set()

        for (const key in skinlist) {
            const entry = skinlist[key]
            if (!entry || !entry.category || seen.has(entry.category)) {
                continue
            }

            seen.add(entry.category)
            categories.push({
                id: entry.category,
                label: entry.categoryLabel || entry.category
            })
        }

        return categories
    }

    function getVisibleSkinEntries() {
        const entries = []

        for (const key in skinlist) {
            const entry = skinlist[key]
            if (!entry) {
                continue
            }

            if (activeCategory !== 'all' && entry.category && entry.category !== activeCategory) {
                continue
            }

            entries.push([key, entry])
        }

        return entries
    }

    function renderCategoryTabs() {
        const categories = getAvailableCategories()
        const hasActiveCategory = activeCategory === 'all' || categories.some((category) => category.id === activeCategory)

        if (!hasActiveCategory) {
            activeCategory = 'all'
        }

        $(".category_tabs").empty()

        if (categories.length <= 1) {
            return
        }

        $(".category_tabs").append(`
            <div class="category_tab ${activeCategory === 'all' ? 'active' : ''}" data-category="all">ทั้งหมด</div>
        `)

        categories.forEach((category) => {
            $(".category_tabs").append(`
                <div class="category_tab ${activeCategory === category.id ? 'active' : ''}" data-category="${category.id}">${category.label}</div>
            `)
        })

        $(".category_tab").off("click").on("click", function () {
            const nextCategory = $(this).data("category")
            if (!nextCategory || nextCategory === activeCategory) {
                return
            }

            activeCategory = nextCategory
            select_skin = null
            PlaySound(2)
            RefreshSkinMenu()
        })
    }

     /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    window.addEventListener('message', function(event) {
        var item = event.data;
        if (item.action == "ToggleSkinMenu") {
            if (item.data.status) {
                skinlist = item.data.skin_list
                cfg = item.data.CFG
                activeCategory = 'all'
                SetDefaultMenu()
                RefreshSkinMenu()
            }
            ToggleMenu(item.data.status)
        }
        if (item.action == "update_skinlist") {
            skinlist = item.skin_list
            RefreshSkinMenu()
        }
        if (item.action == "UpdateMaxValue") {
            skinlist[item.data.index] = item.data.data
            // RefreshSkinMenu()
            if(item.data.data.item1 != null && item.data.data.item1.value != null){
                $(".inputskin_"+item.data.index+"").val(item.data.data.item1.value);
                $(".rangeskin_"+item.data.index+"").val(item.data.data.item1.value);
                $(".inputskin_"+item.data.index+"").attr('min', item.data.data.item1.minvalue);
                $(".inputskin_"+item.data.index+"").attr('max', item.data.data.item1.maxvalue);
            }
            if(item.data.data.item2 != null && item.data.data.item2.value != null){
                $(".inputpattern_"+item.data.index+"").val(item.data.data.item2.value);
                $(".rangepattern_"+item.data.index+"").val(item.data.data.item2.value);
                $(".inputpattern_"+item.data.index+"").attr('min', item.data.data.item2.minvalue);
                $(".inputpattern_"+item.data.index+"").attr('max', item.data.data.item2.maxvalue);
            }
            
            PlaySound(4)
        }
        if (item.action == "savefavoritelist") {
            if (item.data) {
                let savefavorite = JSON.stringify(item.data)
                localStorage.setItem("savefavoritelist", savefavorite)
                RefreshFavoriteList(item.data)
            }
        }
        if (item.action == 'refreshfavorite') {
            RefreshFavoriteList(item.data)
        }
        if (item.action == 'ToggleFavorite') {
            $("#panelname").html(item.CFG.Header)
            ToggleFavorite(item.status)
        }
    })

    function RefreshFavoriteList(data) {
        $(".favoritelist").empty()
        for (key in data) {
            $(".favoritelist").append(`
                <div class="fav_value" id="${key}">
                    <img src="img/fav.png" style="width: 15px; height: 15px;" id="${key}">
                    ${key}
                    <div class="de_fav" id="${key}"> <img src="img/del_fav.png" id="${key}"> </div>
                </div>    
            `);
            // $(".favoritelist").append(`<div class="value-favorite" id="${key}"><img src="img/favorite.png" class="favoriteicon" id="${key}">${key} <img src="img/recycle-bin.png" class="deletefavorite" id="${key}"></div>`);
        }
        $(".de_fav").click(function (event) {
            let deleteid = event.target.id
            if (deleteid) {
                PlaySound(3)
                $.post('http://' + GetParentResourceName() + '/daletefavorite', JSON.stringify({name:deleteid}));
            }
        })
        $(".fav_value").click(function (event) {
            let favoriteid = event.target.id
            if (favoriteid) {
                PlaySound(4)
                $.post('http://' + GetParentResourceName() + '/loadskinfavorite', JSON.stringify({name:favoriteid}));
            }
        })
    }

    function LoadFavoriteList() {
        let Data = localStorage.getItem("savefavoritelist")
        myfavoritelist = JSON.parse(Data)
        if (myfavoritelist == null) { myfavoritelist = {} }
        $.post('http://' + GetParentResourceName() + '/loadfavorite', JSON.stringify({data:myfavoritelist}));
    }

    function queueSkinPreviewUpdate(key, payload) {
        if (pendingSkinPreviewUpdates[key]) {
            clearTimeout(pendingSkinPreviewUpdates[key])
        }

        pendingSkinPreviewUpdates[key] = setTimeout(function() {
            $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify(payload))
            pendingSkinPreviewUpdates[key] = null
        }, sliderPreviewDelayMs)
    }

    function ShouldShowFavoriteBox() {
        if (!cfg) {
            return false
        }

        if (cfg.CustumeType === "SURGERY") {
            return false
        }

        return !!(cfg.Price && cfg.Price.AddFavorite)
    }

function ToggleMenu(status) {
    if (status) {
        PlaySound(2)
        $(".skinmenu").css({"transition": "0ms","transform":"translate(150%,-50%)","opacity": "0%"})
        $(".controlui").css({"transition": "0ms","right":"calc(2% + 344px + 12px)","transform":"translate(150%,-50%)","opacity": "0%"})
        $(".fav_box").css({"transition": "0ms","left":"2%","transform":"translate(0%,-50%)"})
        setTimeout(function() {
            $(".skinmenu").css({"transition": "500ms"})
            $(".controlui").css({"transition": "500ms"})
            setTimeout(function() {
                $(".skinmenu").show()
                $(".controlui").show()
                if (ShouldShowFavoriteBox()) {
                    $(".fav_box").show()
                } else {
                    $(".fav_box").hide()
                }
                $(".rotation").show()
                $(".skinmenu").css({"transform": "translate(0%,-50%)", "opacity": "100%"})
                $(".controlui").css({"transform": "translate(0%,-50%)", "opacity": "100%"})
                if (ShouldShowFavoriteBox()) {
                    $(".fav_box").css({"transform": "translate(0%,-50%)", "opacity": "100%"})
                }
                $(".rotation").css({"transform": "translate(-50%, 0%)", "opacity": "100%"})
            }, 5);
        }, 5);
    } else {
        PlaySound(1)
        $(".skinmenu").css({"transform": "translate(150%,-50%)", "opacity": "0%"})
        $(".controlui").css({"transform": "translate(150%,-50%)", "opacity": "0%"}) // แก้ตรงนี้
        $(".fav_box").css({"transform": "translate(0%,-50%)", "opacity": "0%"})
        $(".rotation").css({"transform": "translate(-50%, 250%)", "opacity": "0%"})
    }
}

    function ToggleFavorite(status) {
        if (status) {
            PlaySound(2)
            ToggleSelectSex(false)
            SetDefaultMenu()
            $(".controlui").css({"transition": "0ms","top":"55%","left":"73%","transform":"translate(150%,-50%)"})
            $(".fav_box").css({"transition": "0ms","top":"55%","left":"73%","transform":"translate(150%,-50%)"})
            setTimeout(function() {
                $(".controlui").css({"transition": "500ms"})
                setTimeout(function() {
                    $(".controlui").show()
                    $(".fav_box").show()
                    $(".controlui").css({"transform": "translate(0%,-50%)", "opacity": "100%"})
                    $(".fav_box").css({"transform": "translate(0%,-50%)", "opacity": "100%"})
                }, 5);
            }, 5);
        } else {
            PlaySound(1)
            $(".controlui").css({"transform": "translate(150%,-50%)", "opacity": "0%"})
            $(".fav_box").css({"transform": "translate(150%,-50%)", "opacity": "0%"})
        }
    }

    function RefreshSkinMenu() {
        let canselectsex = false
        allskincount = 0
        const visibleEntries = getVisibleSkinEntries()

        for (key in skinlist) {
            allskincount = allskincount + 1
            if (skinlist[key].item1.name == "sex") { canselectsex = true }
        }


        $(".pagebtn").css({"background-color": "rgb(255, 255, 255, 0.1)","box-shadow": "0px 0px 0px rgb(255, 255, 255)"})
        $(".page"+MenuPage+"").css({"background-color": "rgb(120, 171, 190)","box-shadow": "0px 0px 0px rgb(120, 171, 190)"})
        $(".menu_main").empty()
        renderCategoryTabs()
        // console.log("select_skin : "+select_skin+"")
        let currentCategory = null
        for (const [key, v] of visibleEntries) {
            let skintype = ``
            let pattern = ``
            let value = ``
            let setrange1 = ``
            let setrange2 = ``
            let select = ``

            if (v.category && v.category !== currentCategory) {
                currentCategory = v.category
                $(".menu_main").append(`
                    <div class="category_header">${v.categoryLabel || v.category}</div>
                `)
            }

            if (select_skin != null && key == select_skin && v.item1.value != null) {
                select = `selctskin`
                setrange1 = `<div class="set_range"> <input type="range" class="skinrange rangeskin_${key}" value="${v.item1.value}" min="${v.item1.minvalue}" max="${v.item1.maxvalue}" id="${key}"> </div>`
            }
            if (select_skin != null && key == select_skin && v.item2 != null && v.item2.value != null) {
                select = `selctskin`
                setrange2 = `<div class="set_range"> <input type="range" class="patternrange rangepattern_${key}" value="${v.item2.value}" min="${v.item2.minvalue}" max="${v.item2.maxvalue}" id="${key}"> </div>`
            }
            if (v.item1) {
                skintype = `
                    <div class="skinitem">
                        <div class="name">
                            ลำดับ
                            <div class="skinlabel"><span>►</span> ${v.item1.label}</div>
                        </div>
                        <div class="inputnumber">
                            <div class="back backskin" id="${key}">-</div>
                            <div class="input"><input type="number" class="skinvalue inputskin_${key}" id="${key}" name="skinvalue" value="${v.item1.value}"></div>
                            <div class="next nextskin" id="${key}">+</div>
                            <div class="arrowdown" id="${key}">▼</div>
                        </div>
                        ${setrange1}
                    </div>
                `
            }
            if (v.item2) {
                pattern = `
                    <div class="pattern">
                        <div class="name">ลำดับ</div>
                        <div class="inputnumber">
                            <div class="back backpattern" id="${key}">-</div>
                            <div class="input"><input type="number" class="patternvalue inputpattern_${key}" id="${key}" name="patternvalue" value="${v.item2.value}"></div>
                            <div class="next nextpattern" id="${key}">+</div>
                            <div class="arrowdown" id="${key}">▼</div>
                        </div>
                        ${setrange2}
                    </div>
                `
            } else {
                pattern = `
                    <div class="patterndisable">Pattern Disable</div>
                `
            }
            value = `<div class="valueskin ${select}">${skintype}${pattern}</div>`
            $(".menu_main").append(value);
        }

        $(".arrowdown").click(function (event) {
            let skinid = parseInt(event.target.id)
            if (skinid != null) {
                if (skinid != select_skin) {
                    select_skin = skinid
                } else {
                    select_skin = null
                }
                RefreshSkinMenu()
            }
        })

        $(".backskin").click(function (event) {
            let skinid = parseInt(event.target.id)
            if (skinid != null) {
                if (skinlist[skinid]) {
                    if (skinlist[skinid].item1.value > skinlist[skinid].item1.minvalue) {
                        skinlist[skinid].item1.value = skinlist[skinid].item1.value - 1
                        $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                            data:skinlist[skinid],
                            index:skinid
                        }));
                    }
                }
            }
        })

        $(".nextskin").click(function (event) {
            let skinid = parseInt(event.target.id)
            if (skinid != null) {
                if (skinlist[skinid]) {
                    if (skinlist[skinid].item1.value < skinlist[skinid].item1.maxvalue) {
                        skinlist[skinid].item1.value = skinlist[skinid].item1.value + 1
                        $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                            data:skinlist[skinid],
                            index:skinid
                        }));
                    }
                }
            }
        })

        $(".backpattern").click(function (event) {
            let skinid = parseInt(event.target.id)
            if (skinid != null) {
                if (skinlist[skinid]) {
                    if (skinlist[skinid].item2.value > skinlist[skinid].item2.minvalue) {
                        skinlist[skinid].item2.value = skinlist[skinid].item2.value - 1
                        $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                            data:skinlist[skinid],
                            index:skinid
                        }));
                    }
                }
            }
        })

        $(".nextpattern").click(function (event) {
            let skinid = parseInt(event.target.id)
            if (skinid != null) {
                if (skinlist[skinid]) {
                    if (skinlist[skinid].item2.value < skinlist[skinid].item2.maxvalue) {
                        skinlist[skinid].item2.value = skinlist[skinid].item2.value + 1
                        $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                            data:skinlist[skinid],
                            index:skinid
                        }));
                    }
                }
            }
        })

        if (cfg.Price.AddFavorite) {
            $(".addprice").html(""+cfg.Price.AddFavorite+"$")
            $(".controlui").show();
        } else {
            $(".addprice").html("ไม่อนุญาต")
            // $(".controlui").hide();
        }
        if (cfg.Price.BuyPrice) {
            $(".buyprice").html(""+cfg.Price.BuyPrice+"<img src='img/dollar-symbol.png'>")
        } else {
            $(".buyprice").html("FREE")
        }

        $("#headername").html(cfg.Header.Main)
        $("#panelname").html(cfg.Header.Control)

        ToggleSelectSex(canselectsex)

    }

    function ToggleSelectSex(status) {
        if (status) {
            $(".gendertext").show()
            $(".genderselect").show()
        } else {
            $(".gendertext").hide()
            $(".genderselect").hide()
        }
    }

    $(".buybtn").click(function (event) {
        $.post('http://' + GetParentResourceName() + '/buy', JSON.stringify({}));
    })

    $(".addfavoritebtn").click(function (event) {
        PlaySound(4)
        let name = $("#favorite").val();
        $.post('http://' + GetParentResourceName() + '/addfavorite', JSON.stringify({name:name}));
        $("#favorite").val("");
    })

    function SetDefaultMenu() {
        MenuPage = 1
        select_skin = null
        LoadFavoriteList()
        SetCamera()
    }


    function NormalizeRotationValue(value) {
        if (value > 180) {
            return value - 360
        }

        if (value < -180) {
            return value + 360
        }

        return value
    }

    function UpdateRotationText(value) {
        rotationValue = NormalizeRotationValue(value)
        const degree = Math.round(180 + rotationValue)
        $('#rangetext').html(degree)
    }

    function SetCamera(pos) {
        let campos = "default"
        if (pos) {campos = pos}
        $.post('http://' + GetParentResourceName() + '/setcamera', JSON.stringify({pos:campos}));
        UpdateRotationText(0)
        $('.ctbtn').css({"background": "rgba(0, 0, 0, 0)"});
        $('#'+campos+'').css({"background": "rgba(0, 0, 0, 0)"});
    }
 
    document.onkeyup = function (data) {
        if (data.which == 27) {
            $.post('http://' + GetParentResourceName() + '/exit', JSON.stringify({}));
        }
        if (data.which == 13) {
            for (let i = 0; i <= allskincount; i++) {
                if ($(".inputskin_"+i+"").is(":focus")) {
                    let number = parseInt($(".inputskin_"+i+"").val())
                    if (number != null) {
                        if (number > skinlist[i].item1.maxvalue) { number = skinlist[i].item1.maxvalue }
                        PlaySound(4)
                        skinlist[i].item1.value = number
                        $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                            data:skinlist[i],
                            index:i
                        }));
                    }
                }
                if ($(".inputpattern_"+i+"").is(":focus")) {
                    let number = parseInt($(".inputpattern_"+i+"").val())
                    if (number != null) {
                        if (number <= skinlist[i].item2.maxvalue) {
                            PlaySound(4)
                            skinlist[i].item2.value = number
                            $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                                data:skinlist[i],
                                index:i
                            }));
                        } else {
                            $(".inputpattern_"+i+"").val(skinlist[i].item2.value)
                        }
                    }
                }
            }
        }
    };

    document.onkeydown = function (data) {
        if (data.which == 69) {
            $.post('http://' + GetParentResourceName() + '/zoom', JSON.stringify({value:"in"}));
        }
        if (data.which == 81) {
            $.post('http://' + GetParentResourceName() + '/zoom', JSON.stringify({value:"out"}));
        }
    };

    function print(text) {
        $.post('http://' + GetParentResourceName() + '/print', JSON.stringify({text:text}));
    }

    $(".camerposition").click(function (event) {
        let camname = event.target.id
        if (camname) {
            PlaySound(1)
            SetCamera(camname)
        }
    })

    $(".sexselect").click(function (event) {
        let sexnumber = parseInt(event.target.id)
        if (sexnumber != null) {
            PlaySound(1)
            skinlist[0].item1.value = sexnumber
            $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                data:skinlist[0],
                index:0
            }));
        }
    })

    $(".confirmbtn").click(function (event) {
        $.post('http://' + GetParentResourceName() + '/buy', JSON.stringify({}));
    })

    $(".cancelbtn").click(function (event) {
        $.post('http://' + GetParentResourceName() + '/exit', JSON.stringify({}));
    })

    $(document).on('contextmenu', function (event) {
        event.preventDefault()
    })

    $(document).on('mousedown', function (event) {
        const clickedOnUiElement = $(event.target).closest('.skinmenu, .controlui, .fav_box, .rotation, input, button, select, textarea').length > 0
        if (clickedOnUiElement) {
            isLeftMouseDragging = false
            isRightMouseDragging = false
            return
        }

        if (event.which === 1 || event.which === 3) {
            lastMouseX = event.clientX
        }

        if (event.which === 1) {
            isLeftMouseDragging = true
        }

        if (event.which === 3) {
            isRightMouseDragging = true
        }
    })

    $(document).on('mousemove', function (event) {
        if (!isLeftMouseDragging && !isRightMouseDragging) {
            return
        }

        const deltaX = event.clientX - lastMouseX
        if (deltaX === 0) {
            return
        }

        lastMouseX = event.clientX

        if (isLeftMouseDragging) {
            $.post('http://' + GetParentResourceName() + '/characterrotation', JSON.stringify({delta: deltaX}))
            UpdateRotationText(rotationValue + (deltaX * 0.35))
        }

        if (isRightMouseDragging) {
            $.post('http://' + GetParentResourceName() + '/camerarotation', JSON.stringify({delta: deltaX}))
        }
    })

    $(document).on('mouseup', function (event) {
        if (event.which === 1) {
            isLeftMouseDragging = false
        }

        if (event.which === 3) {
            isRightMouseDragging = false
        }
    })

    $(document).on('input', '.skinrange', function(event) {
        let value = $(this).val()
        let skinid = event.target.id

        if (skinlist[skinid]) {
            skinlist[skinid].item1.value = parseInt(value)
            if (skinlist[skinid].item2) {
                skinlist[skinid].item2.value = 0
            }
            $(".inputskin_"+skinid+"").val(skinlist[skinid].item1.value);
            queueSkinPreviewUpdate(`skin_${skinid}`, {
                data:skinlist[skinid],
                index:skinid,
                update: false
            });
        }

    });

    $(document).on('change', '.skinrange', function(event) {
        let value = $(this).val();
        let skinid = event.target.id;

        if (skinlist[skinid]) {
            skinlist[skinid].item1.value = parseInt(value);
            if (skinlist[skinid].item2) {
                skinlist[skinid].item2.value = 0
            }
            $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                data: skinlist[skinid],
                index: skinid,
                update: true
            }));
        }
    });

    $(document).on('input', '.patternrange', function(event) {
        let value = $(this).val()
        let skinid = event.target.id

        if (skinlist[skinid] && skinlist[skinid].item2) {
            skinlist[skinid].item2.value = parseInt(value)
            $(".rangepattern_"+skinid+"").val(skinlist[skinid].item2.value);
            queueSkinPreviewUpdate(`pattern_${skinid}`, {
                data:skinlist[skinid],
                index:skinid,
                update: false,
            });
        }

    });

    $(document).on('change', '.patternrange', function(event) {
        let value = $(this).val();
        let skinid = event.target.id;

        if (skinlist[skinid] && skinlist[skinid].item2) {
            skinlist[skinid].item2.value = parseInt(value);
            $.post('http://' + GetParentResourceName() + '/valuechangeskin', JSON.stringify({
                data: skinlist[skinid],
                index: skinid,
                update: true
            }));
        }
    });

    $(document).on('input', '#flashlight_level', function(event) {
        let number = $(this).val()
        if (number != null) {
            $(".text_flashlight").html(""+number+".00");
            $.post('http://' + GetParentResourceName() + '/brightness', JSON.stringify({
                value:number
            }));
        }

    });

})

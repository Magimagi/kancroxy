proxy = require('./config').config.proxy

$ = global.$
$$ = global.$$

materialsName = ['', '油', '弹', '钢', '铝', '高速建造', '高速修复', '开发资材', '改修资材']

state = false

ships = []
stypes = []
mapareas = []
maps = []
missions = []
slotitems = []
ownShips = []
ownSlotitems = []
materials = []
decks = []

exports.initConfig = ->
  # Update tab state
  if proxy.useShadowsocks
    $('#current-proxy').text 'shadowsocks'
    $('#shadowsocks-tab-li').addClass 'am-active'
    $('#shadowsocks-tab').addClass 'am-in am-active'
  else if proxy.useHttpProxy
    $('#current-proxy').text 'http'
    $('#http-tab-li').addClass 'am-active'
    $('#http-tab').addClass 'am-in am-active'
  else if proxy.useSocksProxy
    $('#current-proxy').text 'socks'
    $('#socks-tab-li').addClass 'am-active'
    $('#socks-tab').addClass 'am-in am-active'
  # Shadowsocks
  $('#shadowsocks-server-ip')[0].value = proxy.shadowsocks.serverIp
  $('#shadowsocks-server-port')[0].value = proxy.shadowsocks.serverPort
  $('#shadowsocks-password')[0].value = proxy.shadowsocks.password
  $('#shadowsocks-method')[0].value = proxy.shadowsocks.method
  # HTTP Proxy
  $('#httpproxy-ip')[0].value = proxy.httpProxy.httpProxyIp
  $('#httpproxy-port')[0].value = proxy.httpProxy.httpProxyPort
  # Socks Proxy
  $('#socksproxy-ip')[0].value = proxy.socksProxy.socksProxyIp
  $('#socksproxy-port')[0].value = proxy.socksProxy.socksProxyPort

exports.saveConfig = ->
  conf = require('./config').config
  # Shadowsocks
  conf.proxy.useShadowsocks = $('#current-proxy').text() == 'shadowsocks'
  conf.proxy.shadowsocks.serverIp = $('#shadowsocks-server-ip')[0].value
  conf.proxy.shadowsocks.serverPort = $('#shadowsocks-server-port')[0].value
  conf.proxy.shadowsocks.password = $('#shadowsocks-password')[0].value
  conf.proxy.shadowsocks.method = $('#shadowsocks-method')[0].value
  # HTTP
  conf.proxy.useHttpProxy = $('#current-proxy').text() == 'http'
  conf.proxy.httpProxy.httpProxyIp = $('#httpproxy-ip')[0].value
  conf.proxy.httpProxy.httpProxyPort = $('#httpproxy-port')[0].value
  # Socks
  conf.proxy.useSocksProxy = $('#current-proxy').text() == 'socks'
  conf.proxy.socksProxy.socksProxyIp = $('#socksproxy-ip')[0].value
  conf.proxy.socksProxy.socksProxyPort = $('#socksproxy-port')[0].value
  if require('./config').updateConfig conf
    $$('#save-ok-modal').modal()
  else
    $$('#save-error-modal').modal()

exports.turnOn = ->
  if !state
    state = true
    $("#state-panel-content").text "正常运行中"
    $("#state-panel").hide()
    $("#user-panel").fadeIn()
    $("#resource-panel").fadeIn()

exports.turnOff = ->
  if state
    state = false
    $("#state-panel-content").text "没有检测到流量"
    $("#user-panel").hide()
    $("#resource-panel").hide()
    $("#state-panel").fadeIn()

exports.updateUserinfo = (api_data) ->
  html = ''
  html += "<li>Lv. #{api_data.api_level} #{api_data.api_nickname}</li>"
  $("#user-panel-content").html html

exports.updateShips = (api_mst_ship) ->
  ships = []
  ships[ship.api_id] = ship for ship in api_mst_ship

exports.updateShiptypes = (api_mst_stype) ->
  stypes = []
  stypes[stype.api_id] = stype for stype in api_mst_stype

exports.updateSlotitems = (api_mst_slotitem) ->
  slotitems = []
  slotitems[slotitem.api_id] = slotitem for slotitem in api_mst_slotitem

exports.updateMapareas = (api_mst_maparea) ->
  mapareas = []
  mapareas[maparea.api_id] = maparea for maparea in api_mst_maparea

exports.updateMaps = (api_mst_mapinfo) ->
  maps = []
  maps[map.api_id] = map for map in api_mst_mapinfo

exports.updateMissions = (api_mst_mission) ->
  missions = []
  missions[mission.api_id] = mission for mission in api_mst_mission

exports.updateOwnSlotitems = (api_slotitem) ->
  ownSlotitems = []
  ownSlotitems[slotitem.api_id] = slotitem for slotitem in api_slotitem

exports.updateOwnShips = (api_ship) ->
  ownShips = []
  ownShips[ship.api_id] = ship for ship in api_ship

exports.updateMaterials = (api_material) ->
  material = []
  materials[material.api_id] = material for material in api_material
  html = ""
  for i in [1, 2, 3, 4, 5, 6, 7, 8]
    html += "<li>#{materialsName[i]}: #{materials[i].api_value}</li>"
  $("#resource-panel-content").html html

exports.updateDecks = (api_deck_port) ->
  decks = []
  decks[deck.api_id] = deck for deck in api_deck_port
  for deck in api_deck_port
    decks[deck.api_id] = deck
    # Deckname
    $("#deckname-#{deck.api_id}").text deck.api_name
    # Mission
    for shipId, i in deck.api_ship
      if shipId != -1
        ship = ownShips[shipId]
        $("#ship-#{deck.api_id}#{i + 1}-type").text stypes[ships[ship.api_ship_id].api_stype].api_name
        $("#ship-#{deck.api_id}#{i + 1}-exp").text "Next: #{ship.api_exp[1]}"
        $("#ship-#{deck.api_id}#{i + 1}-hp").text "HP: #{ship.api_nowhp} / #{ship.api_maxhp}"
        $("#ship-#{deck.api_id}#{i + 1}-cond").text "Cond. #{ship.api_cond}"

        $("#ship-#{deck.api_id}#{i + 1}-name").text ships[ship.api_ship_id].api_name
        $("#ship-#{deck.api_id}#{i + 1}-lv").text "Lv. #{ship.api_lv}"

        # HP Line
        hpPercent = ship.api_nowhp * 100 / ship.api_maxhp
        currentState = "am-progress-bar-success"
        currentState = "am-progress-bar-secondary" if hpPercent < 75
        currentState = "am-progress-bar-warning" if hpPercent < 50
        currentState = "am-progress-bar-danger" if hpPercent < 25
        $("#ship-#{deck.api_id}#{i + 1}-hpline").html "<div class=\"am-progress am-progress-striped\"><div class=\"am-progress-bar #{currentState}\" style=\"width: #{hpPercent}%\"></div></div>"

        # Equipment
        # $("#ship-#{deck.api_id}#{i + 1}-equip")

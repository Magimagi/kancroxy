http = require('http')
socks = require('socksv5')
fs = require('fs')
url = require('url')
local = require('shadowsocks')
config = require('./config').config
Buffer = require('buffer').Buffer
processor = require('./processor')
ui = require('./ui')
util = require('./util')
cache = require('./cache')

exports.createShadowsocksServer = ->
  return unless config.proxy.useShadowsocks
  local.createServer config.proxy.shadowsocks.serverIp, config.proxy.shadowsocks.serverPort, config.proxy.shadowsocks.localPort, config.proxy.shadowsocks.password, config.proxy.shadowsocks.method, config.proxy.shadowsocks.timeout, '127.0.0.1'
  if config.proxy.shadowsocks.serverIp == '106.186.30.188'
    ui.showModal '注意', '默认的代理设置仅供测试和日常使用，不保证链接稳定性和长期可用性，请尽量使用其他专业VPN！'
  console.log "Shadowsocks listening at 127.0.0.1:#{config.proxy.shadowsocks.localPort}"

exports.createServer = ->
  server = http.createServer (req, res) ->
    parsed = url.parse req.url
    options = getOptions req, parsed
    # Load File From Cache
    cache.loadCacheFile req, res, (err) ->
      if err
        # Post Data
        postData = ''
        req.setEncoding 'utf8'
        req.addListener 'data', (chunk) ->
          postData += chunk
        req.addListener 'end', ->
          options.postData = req.postData = postData
          sendHttpRequest options, 0, (result) ->
            if result.err
              res.writeHead 500, {'Content-Type': 'text/html'}
              res.write '<!DOCTYPE html><html><body><h1>Network Error</h1></body></html>'
              res.end()
            else
              buffers = []
              result.on 'data', (chunk) ->
                buffers.push chunk
              result.on 'end', ->
                data = Buffer.concat buffers
                result.removeAllListeners 'data'
                result.removeAllListeners 'end'
                res.writeHead result.statusCode, result.headers
                res.write data
                res.end()
                processor.processData req, data if req.url.indexOf('/kcsapi') != -1
                cache.saveCacheFile req, data if req.url.indexOf('/kcs/') != -1
  server.listen config.poi.listenPort
  console.log "Proxy listening at 127.0.0.1:#{config.poi.listenPort}"

getOptions = (req, parsed) ->
  options = null
  if config.proxy.useShadowsocks
    console.log "Get Request #{req.url} using Shadowsocks"
    socksConfig =
      proxyHost:  '127.0.0.1'
      proxyPort:  config.proxy.shadowsocks.localPort
      auths:      [ socks.auth.None() ]
    options =
      host:       parsed.host || '127.0.0.1'
      hostname:   parsed.hostname || '127.0.0.1'
      port:       parsed.port || 80
      method:     req.method
      path:       parsed.path || '/'
      headers:    req.headers
      agent:      new socks.HttpAgent(socksConfig)
  else if config.proxy.useSocksProxy
    console.log "Get Request #{req.url} using Socks Proxy"
    socksConfig =
      proxyHost:  config.proxy.socksProxy.socksProxyIp
      proxyPort:  config.proxy.socksProxy.socksProxyPort
      auths:      [ socks.auth.None() ]
    options =
      host:       parsed.host || '127.0.0.1'
      hostname:   parsed.hostname || '127.0.0.1'
      port:       parsed.port || 80
      method:     req.method
      path:       parsed.path || '/'
      headers:    req.headers
      agent:      new socks.HttpAgent(socksConfig)
  else if config.proxy.useHttpProxy
    console.log "Get Request #{req.url} using HTTP Proxy"
    options =
      host:     config.proxy.httpProxy.httpProxyIP
      port:     config.proxy.httpProxy.httpProxyPort
      method:   req.method
      path:     req.url
      headers:  req.headers
  else
    console.log "Get Request #{req.url}"
    options =
      host: parsed.host || '127.0.0.1'
      hostname: parsed.hostname || '127.0.0.1'
      port: parsed.port || 80
      method: req.method || 'GET'
      path: parsed.path || '/'
      headers: req.headers
  return options

sendHttpRequest = (options, counter, callback) ->
  request = http.request options, (result) ->
    if (options.path.indexOf('/kcsapi/') != -1 || options.path.indexOf('/kcs/') != -1) && (result.statusCode == 500 || result.statusCode == 502 || result.statusCode == 503)
      console.log "Code #{result.statusCode}, retried for the #{counter} time."
      if counter != config.antiCat.retryTime
        ui.addAntiCatCounter()
        setTimeout ->
          sendHttpRequest(options, counter + 1, callback)
        , config.antiCat.retryDelay
      else
        callback {err: true}
    else
      callback result
  if options.method == "POST" && options.postData
    request.write options.postData
  request.on 'error', (e) ->
    return unless options.path.indexOf('/kcsapi/') != -1 || options.path.indexOf('/kcs/') != -1
    console.log "#{e}, retried for the #{counter} time."
    if counter != config.antiCat.retryTime
      ui.addAntiCatCounter()
      setTimeout ->
        sendHttpRequest(options, counter + 1, callback)
      , config.antiCat.retryDelay
    else
      callback {err: true}
  request.end()


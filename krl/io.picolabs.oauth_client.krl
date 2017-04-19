ruleset io.picolabs.oauth_client {
  meta {
    use module io.picolabs.pico alias wrangler
    shares __testing, status, getResource
  }
  global {
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "status" },
                               { "name": "getResource" } ],
                  "events": [ { "domain": "oauth", "type": "access_token_expired" } ]
                }
    authorizationEndpoint = "http://localhost:9001/authorize"
    tokenEndpoint = "http://localhost:9001/token"
    client_id = "oauth-client-1"
    client_secret = "oauth-client-secret-1"
    encodeClientCredentials = function(username,password) {
      // Base64(client_id + ":" + client_secret)
      "b2F1dGgtY2xpZW50LTE6b2F1dGgtY2xpZW50LXNlY3JldC0x"
    }
    redirect_uris = ["http://localhost:9000/callback"]
    application_home = "client.html#/index"
    protectedResource = "http://localhost:9002/resource"
    refreshToken = function() {
      ent:refresh_token || "j2r3oj32r23rmasd98uhjrk2o3i"
    }
    status = function() {
      result = { "access_token": ent:access_token,
                 "scope": ent:scope,
                 "refresh_token": refreshToken() }
    }
    getResource = function() {
      resource = http:post(protectedResource) with
        headers = { "Authorization": "Bearer " + ent:access_token };
      resource.klog("resource")
    }
  }

  rule oauth_authorize {
    select when oauth authorize
    pre {
      state = engine:newChannel(
        { "name": "oauth", "type": "nonce", "pico_id": wrangler:myself().id })
      authorizeUrl = <<#{authorizationEndpoint}?response_type=code&client_id=#{client_id}&state=#{state.id}&redirect_uri=#{redirect_uris[0]}>>
    }
    send_directive("redirect") with url = authorizeUrl.klog("authorizeUrl")
    fired {
      ent:access_token := null;
      ent:state := state
    }
  }

  rule oauth_callback {
    select when oauth callback code re#(.*)# setting(code)
    pre {
      not_used = code.klog("code")
      state = event:attr("state").klog("state")
      stateMatches = ent:state{"id"} == state
    }
    if stateMatches.klog("stateMatches") then 
      http:post(tokenEndpoint) setting(tokRes) with
        headers = {
          "Authorization": "Basic " + encodeClientCredentials(client_id,client_secret) }
        form = {
          "grant_type": "authorization_code",
          "code": code,
          "redirect_uri": redirect_uris[0] }
    fired {
      raise oauth event "access_token" attributes tokRes.klog("tokRes")
    } else {
      log error "State DOES NOT MATCH: expected "+ent:state{"id"}+" got "+state
    } finally {
      engine:removeChannel({
        "pico_id": wrangler:myself().id,
        "eci": state.klog("eci to be removed")
      });
      ent:state := null
    }
  }

  rule oauth_access_token {
    select when oauth access_token status_code re#200#
    pre {
      //status_code = event:attr("status_code").as("String").klog("status_code")
      content = event:attr("content").klog("content").decode()
      access_token = content{"access_token"}.klog("access_token")
      token_type = content{"token_type"}.klog("token_type")
      scope = content{"scope"}.klog("scope")
      refresh_token = content{"refresh_token"}.klog("refresh_token").defaultsTo(refreshToken())
    }
    send_directive("redirect") with url = application_home
    fired {
      ent:access_token := access_token;
      ent:token_type := token_type;
      ent:scope := scope;
      ent:refresh_token := refresh_token
    }
  }

  rule oauth_access_token_expired {
    select when oauth access_token_expired
    pre {
      refresh_token = refreshToken()
    }
    if refresh_token then
      http:post(tokenEndpoint) setting(tokRes) with
        headers = {
          "Authorization": "Basic " + encodeClientCredentials(client_id,client_secret) }
        form = {
          "grant_type": "refresh_token",
          "refresh_token": refresh_token }
      send_directive("refresh_response") with response = tokRes
    fired {
      raise oauth event "access_token" attributes tokRes.klog("tokRes")
    }
  }
}

ruleset app_registration_owner {
  meta {
    use module io.picolabs.pico alias wrangler
    shares __testing
  }
  global {
    __testing =
      { "queries": [ { "name": "__testing" } ],
        "events": [ { "domain": "registration", "type": "channel_needed",
                      "attrs": [ "student_id" ] } ] }
    validRegPico = function(regPico){
      wrangler:children()
        .filter(function(pico){
                  pico.id == regPico.id
                })
        .length()
    }
  }

  rule registration_channel_needed {
    select when registration channel_needed
    pre {
      student_id = event:attr("student_id")
    }
    if ent:reg_pico then every {
      engine:newChannel(ent:reg_pico.id,student_id,"anon")
        setting(anon_channel)
      send_directive("registration",{
        "eci": anon_channel.id.klog("anon eci issued:")})
    }
  }

  rule initialization {
    select when pico ruleset_added where rid == meta:rid
    pre {
      regPico = ent:reg_pico
      regBase = meta:rulesetURI
      regURL = "app_registration.krl"
      needRegPico = not regPico || not validRegPico(regPico)
    }
    if needRegPico then
      engine:registerRuleset(regURL,regBase)
    fired {
      raise pico event "new_child_request"
        attributes { "dname": "Registration Pico",
                     "color": "#7FFFD4" }
    }
  }

  rule new_registration_pico {
    select when pico child_initialized
    pre {
      regPico = event:attr("new_child")
      regRID = "app_registration"
    }
    event:send(
      { "eci": regPico.eci, "eid": "ruleset-install",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "rid": regRID } } )
    fired {
      ent:reg_pico := regPico
    }
  }
}

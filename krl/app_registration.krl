ruleset app_registration {
  meta {
    shares __testing
    use module io.picolabs.pico alias wrangler
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "section", "type": "needed",
                                "attrs": [ "student_id", "section_id" ] } ] }
    validScoPico = function(scoPico){
      wrangler:children()
        .filter(function(pico){
                  pico.id == scoPico.id
                })
        .length()
    }
  }

  rule section_needed {
    select when section needed
    pre {
      student_id = event:attr("student_id")
      section_id = event:attr("section_id")
      section_name = student_id + "/" + section_id
    }
    if ent:sco_pico then every {
      engine:newChannel(ent:sco_pico.id,section_name,"anon")
        setting(anon_channel)
      send_directive("section_collection",{
        "eci": anon_channel{"id"}.klog("anon eci issued:"),
        "section_id": section_id})
      event:send(
        { "eci": anon_channel{"id"}, "eid": "section-needed",
          "domain": "section", "type": "needed",
          "attrs": event:attrs() } )
    }
  }

  rule initialization {
    select when pico ruleset_added where rid == meta:rid
    pre {
      scoPico = ent:sco_pico
      scoBase = meta:rulesetURI
      scoURL = "app_section_collection.krl"
      needScoPico = not scoPico || not validScoPico(scoPico)
    }
    if needScoPico then
      engine:registerRuleset(scoURL,scoBase)
    fired {
      raise pico event "new_child_request"
        attributes { "dname": "Section Collection Pico",
                     "color": "#7FFFD4" }
    }
  }

  rule new_section_collection_pico {
    select when pico child_initialized
    pre {
      scoPico = event:attr("new_child")
      scoRID = "app_section_collection"
    }
    event:send(
      { "eci": scoPico.eci, "eid": "ruleset-install",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "rid": scoRID } } )
    fired {
      ent:sco_pico := scoPico
    }
  }
}

ruleset app_registration {
  meta {
    shares __testing
    use module io.picolabs.pico alias wrangler
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "section", "type": "needed",
                                "attrs": [ "student_id", "section_id" ] } ] }
    newSectionCollectionChannel = function(student_id,section_id){
      ent:sco_pico => engine:newChannel(
                        { "name": student_id + "/" + section_id,
                          "type": "anon",
                          "pico_id": ent:sco_pico.id } )
                    | null
    }
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
      anon_channel = newSectionCollectionChannel(student_id,section_id)
      anon_eci = anon_channel.id
                             .klog("anon_eci issued:")
    }
    if anon_channel then
      send_directive("section_collection")
        with eci = anon_eci
             section_id = section_id
      event:send(
        { "eci": anon_eci, "eid": "section-needed",
          "domain": "section", "type": "needed",
          "attrs": event:attrs() } )
  }

  rule initialization {
    select when pico ruleset_added
    pre {
      scoPico = ent:sco_pico.klog("scoPico")
      scoBase = meta:rulesetURI.klog("scoBase")
      scoURL = "app_section_collection.krl".klog("scoURL")
      needScoPico = not scoPico || not validScoPico(scoPico)
    }
    if needScoPico.klog("needScoPico") then noop()
    fired {
      engine:registerRuleset( { "base": scoBase, "url": scoURL } );
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

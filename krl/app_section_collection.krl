ruleset app_section_collection {
  meta {
    use module io.picolabs.pico alias wrangler
    shares sections, showChildren, __testing
  }
  global {
    sections = function() {
      ent:sections.defaultsTo({})
    }
 
    __testing = { "queries": [ { "name": "sections" },
                               { "name": "showChildren" } ],
                  "events":  [ { "domain": "collection", "type": "empty" },
                               { "domain": "section", "type": "needed",
                                 "attrs": [ "section_id" ] },
                               { "domain": "section", "type": "offline",
                                 "attrs": [ "section_id" ] }
                             ]
                }
 
    showChildren = function() {
      wrangler:children()
    }
 
    childFromID = function(section_id) {
      ent:sections{section_id}
    }
 
    nameFromID = function(section_id) {
      "Section " + section_id + " Pico"
    }
  }
 
  rule collection_empty {
    select when collection empty
    always {
      ent:sections := {}
    }
  }
 
  rule section_may_need_creation {
    select when section may_need_creation
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if not exists
    then noop()
    fired {
      ent:sections{[section_id,"state"]} := "creating";
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id),
                     "color": "#FF69B4",
                     "section_id": section_id }
    }
  }
 
  rule section_already_exists {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      student_id = event:attr("student_id")
      section_name = student_id + "/" + section_id
      the_section = exists => ent:sections{[section_id]}
                            | null
    }
    if exists && ent:sections{[section_id,"state"]} == "ready"
    then every {
      engine:newChannel(the_section{"id"},section_name,"anon")
        setting(anon_channel)
      send_directive("section_ready",{
        "section_id": section_id,
        "section_state": the_section{["state"]},
        "eci": anon_channel{"id"}.klog("anon eci issued:")})
    }
  }
 
  rule section_needed {
    select when section needed
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
    }
    if not exists
    then
      send_directive("section_ready",{
        "section_id": section_id,
        "section_state": "creating"})
    fired {
      ent:sections{[section_id,"state"]} := "creating";
      raise pico event "new_child_request"
        attributes { "dname": nameFromID(section_id),
                     "color": "#FF69B4",
                     "section_id": section_id }
    }
  }
 
  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      the_section = event:attr("new_child")
      section_id = event:attr("rs_attrs"){"section_id"}
    }
    if section_id
    then
      event:send(
        { "eci": the_section.eci, "eid": 255,
          "domain": "pico", "type": "new_ruleset",
          "attrs": { "rid": "app_section", "section_id": section_id } } )
    fired {
      ent:sections := ent:sections.defaultsTo({});
      ent:sections{[section_id]} := the_section;
      ent:sections{[section_id,"state"]} := "initializing"
    }
  }

  rule section_ready {
    select when section ready
    pre {
      section_id = event:attr("section_id")
      exists = (ent:sections >< section_id)
    }
    if exists
    then
      noop()
    fired {
      ent:sections{[section_id,"state"]} := "ready"
    }
  }

  rule section_offline {
    select when section offline
    pre {
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      eci = meta:eci
      child_to_delete = childFromID(section_id)
    }
    if exists then
      send_directive("section_deleted",{
        "section_id": section_id})
    fired {
      raise pico event "delete_child_request"
        attributes child_to_delete;
      ent:sections{[section_id]} := null
    }
  }

  rule section_join {
    select when section add_request
    pre {
      student_id = event:attr("student_id")
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      the_section = exists => ent:sections{section_id} | null
    }
    if exists then
      event:send(
        { "eci": the_section.eci, "eid": "join request",
          "domain": "section", "type": "add_request",
          "attrs": { "student_id": student_id, "section_id": section_id } } )
    fired {
      student_id.klog("added");
      section_id.klog("to section")
    }
  }

  rule section_drop {
    select when section drop_request
    pre {
      student_id = event:attr("student_id")
      section_id = event:attr("section_id")
      exists = ent:sections >< section_id
      the_section = exists => ent:sections{section_id} | null
    }
    if exists then
      event:send(
        { "eci": the_section.eci, "eid": "drop request",
          "domain": "section", "type": "drop_request",
          "attrs": { "student_id": student_id, "section_id": section_id } } )
    fired {
      student_id.klog("dropped");
      section_id.klog("from section")
    }
  }

  rule initialization {
    select when pico ruleset_added where rid == meta:rid
    pre {
      secBase = meta:rulesetURI
      secURL = "app_section.krl"
    }
    engine:registerRuleset(secURL,secBase)
    always {
      ent:sections := {}
    }
  }
}

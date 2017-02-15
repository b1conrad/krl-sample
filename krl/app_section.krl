ruleset app_section {
  meta {
    name "Section"
    description <<
A test ruleset for Registration
>>
    author "Aaron Rasmussen, Bruce Conrad"
    logging on
    shares sectionInfo, inRoster, __testing
    use module io.picolabs.pico alias wrangler
  }
  global {

    sectionInfo = function() {
      info = {
        "section_id": ent:section_id,
        "capacity": ent:capacity,
        "taken": ent:taken,
        "remaining": ent:capacity - ent:taken,
        "roster": ent:roster
      };
      info.klog("Section Info: ")
    }

    inRoster = function(student_id) {
      student_id = student_id.defaultsTo("99-999-9999");
      ent:roster.has([student_id])
    }

    __testing =
      { "queries": [ { "name": "sectionInfo" },
                     { "name": "__testing" },
                     { "name": "inRoster", "args": [ "student_id"] } ],
        "events": [ { "domain": "section", "type": "config_empty",
                      "attrs": [ "capacity" ] },
                    { "domain": "section", "type": "add_request", 
                      "attrs": [ "student_id" ] },
                    { "domain": "section", "type": "drop_request",
                      "attrs": [ "student_id" ] } ]
      }
  }
  
  rule config is active {
    select when section config_empty
    pre {
      capacity = event:attr("capacity")
    }
    always {
      ent:capacity := capacity;
      ent:roster := [];
      ent:taken := 0
    }
  }

  rule join_section is active {
    select when section add_request
    pre {
      student_id = event:attr("student_id")
      new_roster = ent:roster.union( [ student_id ] )
    }
    if ent:taken < ent:capacity
    then
      send_directive("request_granted")
    fired {
      ent:roster := new_roster;
      ent:taken := ent:roster.length()
    }
  }

  rule drop_section is active {
    select when section drop_request
    pre {
      student_id = event:attr("student_id")
      new_roster = ent:roster.difference( [ student_id ] )
    }
    if new_roster.length() < ent:taken then noop()
    fired {
      ent:roster := new_roster;
      ent:taken := ent:roster.length()
    }
    
  }

  rule pico_ruleset_added {
    select when pico ruleset_added
    pre {
      section_id = event:attr("section_id")
      attrs = event:attrs().klog("attrs")
    }
    if section_id
      && not ent:section_id
    then noop()
    fired {
      raise section event "assigned_id"
        attributes event:attrs()
    }
  }

  rule section_assigned_id {
    select when section assigned_id
    pre {
      section_id = event:attr("section_id").klog("assigned id")
      response = http:get("http://www.sanbachs.net/byu/picolabs/cgi-bin/sec-cap.cgi",
                          { "sid": section_id } ).klog("response")
    }
    if response{"content"} then noop()
    fired {
      ent:section_id := section_id;
      ent:capacity := response{"content"}.extract(re#([0-9]*)#).head();
      ent:roster := [];
      ent:taken := 0;
      raise section event "ready"
    }
  }

  rule section_ready {
    select when section ready
    if ent:capacity
    then
      event:send( { "eci": wrangler:parent().eci, "eid": 163,
                    "domain": "section", "type": "ready",
                    "attrs": { "section_id": ent:section_id } } )
  }

  rule info_directive is active {
    select when section add_request  or 
        section drop_request or
        section config_empty
    send_directive("section") with
      section_info = sectionInfo()
  }
 
}

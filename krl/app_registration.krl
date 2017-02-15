ruleset app_registration {
  meta {
    shares sectionCollection, __testing
    use module io.picolabs.pico alias wrangler
  }
  global {
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "sectionCollection" } ],
                  "events": [ { "domain": "channel", "type": "needed",
                                "attrs": [ "student_id" ] },
                              { "domain": "section", "type": "needed",
                                "attrs": [ "student_id", "section_id" ] } ] }
    sectionCollection = function(section_id){
      wrangler:children()[0] // for now assume it is the first child
    }
    newSectionCollectionChannel = function(student_id,section_id){
      engine:newChannel(
        { "name": student_id + "/" + section_id,
          "type": "anon",
          "pico_id": sectionCollection(section_id).id } )
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
    send_directive("section_collection")
      with eci = anon_eci
           section_id = section_id
    event:send(
      { "eci": anon_eci, "eid": 117,
        "domain": "section", "type": "needed",
        "attrs": event:attrs() } )
  }
}
